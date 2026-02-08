///|
/// A chord with its time range within a measure
pub(all) struct ChordSegment {
  chord : @music.Chord
  start_beat : Double
  end_beat : Double
} derive(Eq, Show)

///|
/// Phrase state for phrase-based note generation
priv enum PhraseState {
  Playing(Int) // remaining notes in phrase (including current)
  Resting // must insert rest, then start new phrase
}

///|
/// Context passed to MeasureGenerator
pub struct MeasureContext {
  chords : Array[ChordSegment] // Chord segments within this measure
  incoming_tie : TieContext? // Tie from previous measure
  key : @music.KeySignature
  time_signature : @music.TimeSignature
  beats_per_measure : Double
  incoming_stamina : Int // Stamina from previous measure
  incoming_last_midi : @music.MidiNumber? // Last note from previous measure
  incoming_phrase : Int? // Phrase state from previous measure (Some(n) = playing, None = resting)
}

///|
/// Get the chord at a specific beat position within the measure
pub fn MeasureContext::chord_at(
  self : MeasureContext,
  beat : Double,
) -> @music.Chord {
  // Find the chord segment that contains this beat
  for segment in self.chords {
    if beat >= segment.start_beat && beat < segment.end_beat {
      return segment.chord
    }
  }
  // If beat is at or beyond end, use the last chord
  self.chords[self.chords.length() - 1].chord
}

///|
/// Create chord segments from an array of chords, evenly distributed across the measure
pub fn create_chord_segments(
  chords : Array[@music.Chord],
  beats_per_measure : Double,
) -> Array[ChordSegment] {
  let num_chords = chords.length()
  guard num_chords > 0 else { return [] }
  let beats_per_chord = beats_per_measure / num_chords.to_double()
  chords
  .iter()
  .mapi(fn(i, chord) {
    ChordSegment::{
      chord,
      start_beat: i.to_double() * beats_per_chord,
      end_beat: (i + 1).to_double() * beats_per_chord,
    }
  })
  .collect()
}

///|
/// Tie information for cross-measure notes
pub struct TieContext {
  midi : @music.MidiNumber
  remaining_beats : Double
}

///|
/// Result from MeasureGenerator
pub struct MeasureResult {
  beats : Array[@music.Beat]
  outgoing_tie : TieContext? // Tie to next measure
  outgoing_stamina : Int // Stamina to pass to next measure
  outgoing_last_midi : @music.MidiNumber? // Last note to pass to next measure
  outgoing_phrase : Int? // Phrase state to pass to next measure (Some(n) = playing, None = resting)
}

///|
/// Generator function that produces notes for one measure
pub type MeasureGenerator = (MeasureContext) -> MeasureResult

///|
/// Settings for the measure generator
pub(all) struct Settings {
  seed : Int
  rest_probability : Int // 0-100
  note_duration_weights : DurationWeights
  rest_duration_weights : DurationWeights
  stamina_initial : Int // Initial stamina (e.g., 100)
  stamina_max : Int // Maximum stamina (e.g., 100)
  stamina_recovery_per_beat : Int // Recovery per beat of rest (e.g., 20)
  stamina_passive_recovery : Int // Passive recovery after playing note (e.g., 5)
  scale_tone_weight_ratio : Int // 0-100, scale tone weight as % of chord tone weight
  tension_weight_ratio : Int // 0-100, tension tone weight as % of chord tone weight
  approach_weight_ratio : Int // 0-100, approach tone weight as % of chord tone weight
  phrase_length_min : Int // Minimum notes in a phrase (default: 2)
  phrase_length_max : Int // Maximum notes in a phrase (default: 8)
  phrase_early_end_stamina : Int // Below this stamina, phrase may end early (default: 15)
  max_interval : Int // Maximum interval jump in semitones (default: 7 = perfect fifth)
  syncopation_probability : Int // 0-100, chance of forcing off-beat phrase start on downbeats (default: 40)
} derive(Eq, Show)

///|
/// Create default settings with given seed
pub fn Settings::default(seed : Int) -> Settings {
  Settings::{
    seed,
    rest_probability: 25,
    note_duration_weights: DurationWeights::note_default(),
    rest_duration_weights: DurationWeights::rest_default(),
    stamina_initial: 50,
    stamina_max: 50,
    stamina_recovery_per_beat: 20,
    stamina_passive_recovery: 5,
    scale_tone_weight_ratio: 30,
    tension_weight_ratio: 50,
    approach_weight_ratio: 20,
    phrase_length_min: 2,
    phrase_length_max: 8,
    phrase_early_end_stamina: 15,
    max_interval: 7,
    syncopation_probability: 40,
  }
}

///|
/// Create a measure generator from settings
/// Returns a function that generates notes for one measure
pub fn create_measure_generator(settings : Settings) -> MeasureGenerator {
  let random_int = create_random_int(settings.seed)
  fn(ctx : MeasureContext) -> MeasureResult {
    generate_measure_notes(ctx, settings, random_int)
  }
}

///|
/// Internal state for measure generation
priv struct MeasureState {
  measure_pos : Double
  beat_notes : Array[Array[@music.MeasureNote]]
  stamina : Int
  last_midi : @music.MidiNumber?
  last_was_rest : Bool
  phrase : PhraseState
}

///|
fn MeasureState::new(
  num_beats : Int,
  stamina : Int,
  last_midi : @music.MidiNumber?,
  phrase : PhraseState,
) -> MeasureState {
  MeasureState::{
    measure_pos: 0.0,
    beat_notes: Array::makei(num_beats, fn(_) { [] }),
    stamina,
    last_midi,
    last_was_rest: false,
    phrase,
  }
}

///|
fn MeasureState::add_note(
  self : MeasureState,
  note : @music.MeasureNote,
  phrase : PhraseState,
) -> MeasureState {
  let beat_index = self.measure_pos.to_int()
  self.beat_notes[beat_index].push(note)
  MeasureState::{
    measure_pos: self.measure_pos + note.duration.to_beats(),
    beat_notes: self.beat_notes,
    stamina: self.stamina,
    last_midi: self.last_midi,
    last_was_rest: note.midi is None, // rest if no MIDI
    phrase,
  }
}

///|
fn MeasureState::to_beats(self : MeasureState) -> Array[@music.Beat] {
  self.beat_notes
  .iter()
  .mapi(fn(i, notes) { @music.Beat::{ count: i, notes } })
  .collect()
}

///|
/// Calculate the stamina cost for an interval jump
fn interval_cost(prev : @music.MidiNumber, next : @music.MidiNumber) -> Int {
  let distance = prev.distance(next)
  match distance {
    0..=2 => 0
    3..=4 => 10
    5..=7 => 30
    8..=12 => 80
    _ => 150 + (distance - 12) * 10
  }
}

///|
/// Calculate the weight for note selection based on stamina and cost
fn note_selection_weight(stamina : Int, cost : Int) -> Int {
  let base_weight = @cmp.maximum(1, 100 - cost)
  let stamina_factor = @cmp.maximum(10, stamina)
  base_weight * stamina_factor / 50
}

///|
/// Generate notes for one measure
fn generate_measure_notes(
  ctx : MeasureContext,
  settings : Settings,
  random_int : (Int) -> Int,
) -> MeasureResult {
  // Convert Int? to PhraseState
  let incoming_phrase = match ctx.incoming_phrase {
    Some(n) => Playing(n)
    None => Resting
  }
  let initial_state = MeasureState::new(
    ctx.beats_per_measure.to_int(),
    ctx.incoming_stamina,
    ctx.incoming_last_midi,
    incoming_phrase,
  )

  // Handle incoming tie first
  let (state_after_tie, outgoing_tie) = match ctx.incoming_tie {
    Some(tie_ctx) =>
      process_incoming_tie(initial_state, tie_ctx, ctx.beats_per_measure)
    None => (initial_state, None)
  }

  // Fill remaining measure with new notes
  let update_accidental = @music.create_accidental_calculator(ctx.key)
  let final_state = fill_remaining_measure(
    state_after_tie, ctx, settings, update_accidental, random_int,
  )
  // Convert PhraseState back to Int?
  let outgoing_phrase = match final_state.phrase {
    Playing(n) => Some(n)
    Resting => None
  }
  MeasureResult::{
    beats: final_state.to_beats(),
    outgoing_tie,
    outgoing_stamina: final_state.stamina,
    outgoing_last_midi: final_state.last_midi,
    outgoing_phrase,
  }
}

///|
/// Process incoming tie from previous measure
/// Returns updated state and optional outgoing tie
fn process_incoming_tie(
  state : MeasureState,
  tie_ctx : TieContext,
  beats_per_measure : Double,
) -> (MeasureState, TieContext?) {
  let midi = tie_ctx.midi
  for remaining = tie_ctx.remaining_beats, state = state {
    guard remaining > 0.0 && state.measure_pos < beats_per_measure else {
      let outgoing = if remaining > 0.0 {
        Some(TieContext::{ midi, remaining_beats: remaining })
      } else {
        None
      }
      break (state, outgoing)
    }
    let beat_index = state.measure_pos.to_int()
    let beat_capacity = (beat_index + 1).to_double() - state.measure_pos
    let remaining_in_measure = beats_per_measure - state.measure_pos
    let (tie, consume) = match
      (remaining > remaining_in_measure, remaining > beat_capacity) {
      (true, _) => (@music.TieBoth, beat_capacity) // Extends beyond measure
      (false, true) => (@music.TieBoth, beat_capacity) // Spans beyond beat
      (false, false) => (@music.TieEnd, remaining) // Ends in this beat
    }
    let fitted = @music.NoteDuration::fit(consume).unwrap_or(@music.Eighth)
    let new_state = state.add_note(
      @music.MeasureNote::{
        midi: Some(midi.value),
        duration: fitted,
        accidental: None,
        tie: Some(tie),
      },
      state.phrase,
    )
    continue remaining - fitted.to_beats(), new_state
  }
}

///|
/// Roll a new phrase length from settings
fn roll_phrase_length(settings : Settings, random_int : (Int) -> Int) -> Int {
  let range = settings.phrase_length_max - settings.phrase_length_min + 1
  settings.phrase_length_min + random_int(range)
}

///|
/// Fill remaining measure with new notes using phrase-based generation
fn fill_remaining_measure(
  state : MeasureState,
  ctx : MeasureContext,
  settings : Settings,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  random_int : (Int) -> Int,
) -> MeasureState {
  for state = state {
    guard state.measure_pos < ctx.beats_per_measure else { break state }
    let remaining_in_measure = ctx.beats_per_measure - state.measure_pos
    let remaining_in_group = ctx.time_signature.beat_group_remaining(
      state.measure_pos,
    )
    let remaining = if remaining_in_measure < remaining_in_group {
      remaining_in_measure
    } else {
      remaining_in_group
    }
    // Get chord at current beat position
    let chord = ctx.chord_at(state.measure_pos)
    match state.phrase {
      Resting => {
        // Syncopation: on downbeats, sometimes force eighth rest so phrase starts on upbeat
        let is_on_downbeat = (state.measure_pos -
          state.measure_pos.to_int().to_double()).abs() <
          0.01
        let use_syncopation = is_on_downbeat &&
          random_int(100) < settings.syncopation_probability
        let duration = if use_syncopation {
          if remaining >= @music.Eighth.to_beats() {
            Some(@music.Eighth)
          } else {
            None
          }
        } else {
          random_duration_within(
            remaining,
            settings.rest_duration_weights,
            random_int,
          )
        }
        // Emit a rest, then roll a new phrase
        match duration {
          Some(duration) => {
            let recovery = (duration.to_beats() *
            settings.stamina_recovery_per_beat.to_double()).to_int()
            let new_stamina = @cmp.minimum(
              state.stamina + recovery,
              settings.stamina_max,
            )
            let beat_index = state.measure_pos.to_int()
            state.beat_notes[beat_index].push(@music.MeasureNote::{
              midi: None,
              duration,
              accidental: None,
              tie: None,
            })
            let new_phrase_len = roll_phrase_length(settings, random_int)
            continue MeasureState::{
                measure_pos: state.measure_pos + duration.to_beats(),
                beat_notes: state.beat_notes,
                stamina: new_stamina,
                last_midi: state.last_midi,
                last_was_rest: true,
                phrase: Playing(new_phrase_len),
              }
          }
          None => break state
        }
      }
      Playing(notes_left) => {
        // Check for early phrase termination due to low stamina
        let should_end_early = notes_left > 1 &&
          state.stamina < settings.phrase_early_end_stamina &&
          {
            let prob = effective_rest_probability(
              settings.rest_probability,
              state.stamina,
              settings.stamina_max,
              state.last_was_rest,
            )
            random_int(100) < prob
          }
        guard not(should_end_early) else {
          // Transition to resting (will emit rest on next iteration)
          continue MeasureState::{ ..state, phrase: Resting }
        }
        // Force a note (no random rests within a phrase)
        let midi_opt = decide_midi_number(
          chord,
          ctx.key,
          state.last_midi,
          state.stamina,
          settings.stamina_max,
          state.last_was_rest,
          0, // rest_probability = 0 to force note
          settings.scale_tone_weight_ratio,
          settings.tension_weight_ratio,
          settings.approach_weight_ratio,
          settings.max_interval,
          random_int,
        )
        match midi_opt {
          Some(midi) =>
            match
              random_duration_within(
                remaining,
                settings.note_duration_weights,
                random_int,
              ) {
              Some(duration) => {
                let cost = match state.last_midi {
                  Some(prev) => interval_cost(prev, midi)
                  None => 0
                }
                let new_stamina = @cmp.maximum(
                  0,
                  @cmp.minimum(
                    state.stamina - cost + settings.stamina_passive_recovery,
                    settings.stamina_max,
                  ),
                )
                let beat_index = state.measure_pos.to_int()
                state.beat_notes[beat_index].push(@music.MeasureNote::{
                  midi: Some(midi.value),
                  duration,
                  accidental: update_accidental(midi),
                  tie: None,
                })
                let next_phrase = match notes_left {
                  1 => Resting
                  n => Playing(n - 1)
                }
                continue MeasureState::{
                    measure_pos: state.measure_pos + duration.to_beats(),
                    beat_notes: state.beat_notes,
                    stamina: new_stamina,
                    last_midi: Some(midi),
                    last_was_rest: false,
                    phrase: next_phrase,
                  }
              }
              None => break state
            }
          None =>
            // Shouldn't happen with rest_probability=0, but handle gracefully
            break state
        }
      }
    }
  }
}

///|
/// Get extended chord tones across multiple octaves
fn get_extended_tones(chord : @music.Chord) -> Array[@music.MidiNumber] {
  [-1, 0, 1]
  .iter()
  .flat_map(fn(octave_offset) {
    chord
    .tones()
    .iter()
    .filter_map(fn(tone) { tone.shift_octave(octave_offset) })
  })
  .collect()
}

///|
/// Get extended scale tones (non-chord diatonic tones) across multiple octaves
fn get_extended_scale_tones(
  chord : @music.Chord,
  key : @music.KeySignature,
) -> Array[@music.MidiNumber] {
  [-1, 0, 1]
  .iter()
  .flat_map(fn(octave_offset) {
    chord
    .scale_tones(key)
    .iter()
    .filter_map(fn(tone) { tone.shift_octave(octave_offset) })
  })
  .collect()
}

///|
/// Get extended tension tones across multiple octaves
fn get_extended_tension_tones(chord : @music.Chord) -> Array[@music.MidiNumber] {
  [-1, 0, 1]
  .iter()
  .flat_map(fn(octave_offset) {
    chord
    .tension_tones()
    .iter()
    .filter_map(fn(tone) { tone.shift_octave(octave_offset) })
  })
  .collect()
}

///|
/// Get extended approach tones (chromatic half-step above/below chord tones) across multiple octaves
fn get_extended_approach_tones(
  chord : @music.Chord,
) -> Array[@music.MidiNumber] {
  [-1, 0, 1]
  .iter()
  .flat_map(fn(octave_offset) {
    chord
    .approach_tones()
    .iter()
    .filter_map(fn(tone) { tone.shift_octave(octave_offset) })
  })
  .collect()
}

///|
/// Calculate effective rest probability based on stamina and previous note
/// High stamina → low rest probability (want to play)
/// Low stamina → high rest probability (need to rest)
/// After rest → lower rest probability (avoid consecutive rests)
fn effective_rest_probability(
  base_probability : Int,
  stamina : Int,
  stamina_max : Int,
  last_was_rest : Bool,
) -> Int {
  guard stamina_max > 0 else { return base_probability }
  // When stamina is max, rest probability drops to ~10% of base
  // When stamina is 0, rest probability is at base value
  let stamina_ratio = stamina.to_double() / stamina_max.to_double()
  let stamina_scale = 1.0 - stamina_ratio * 0.9 // 1.0 at stamina=0, 0.1 at stamina=max
  // After a rest, reduce probability by 70% to avoid consecutive rests
  let consecutive_scale = if last_was_rest { 0.3 } else { 1.0 }
  (base_probability.to_double() * stamina_scale * consecutive_scale).to_int()
}

///|
/// Filter tones to only those within max_interval semitones of prev.
/// If all are filtered out, returns the single closest tone as fallback.
fn filter_by_interval(
  tones : Array[@music.MidiNumber],
  prev : @music.MidiNumber,
  max_interval : Int,
) -> Array[@music.MidiNumber] {
  let filtered : Array[@music.MidiNumber] = tones
    .iter()
    .filter(fn(tone) { prev.distance(tone) <= max_interval })
    .collect()
  guard filtered.is_empty() else { return filtered }
  // Fallback: pick the single closest tone
  let mut closest = tones[0]
  let mut min_dist = prev.distance(closest)
  for tone in tones {
    let d = prev.distance(tone)
    if d < min_dist {
      closest = tone
      min_dist = d
    }
  }
  [closest]
}

///|
/// Decide whether to generate a note or rest, and if note, which MIDI number
/// Uses stamina-based weighted selection for chord tones
fn decide_midi_number(
  chord : @music.Chord,
  key : @music.KeySignature,
  last_midi : @music.MidiNumber?,
  stamina : Int,
  stamina_max : Int,
  last_was_rest : Bool,
  rest_probability : Int,
  scale_tone_weight_ratio : Int,
  tension_weight_ratio : Int,
  approach_weight_ratio : Int,
  max_interval : Int,
  random_int : (Int) -> Int,
) -> @music.MidiNumber? {
  let actual_rest_prob = effective_rest_probability(
    rest_probability, stamina, stamina_max, last_was_rest,
  )
  guard random_int(100) >= actual_rest_prob else { return None }
  let chord_tones = get_extended_tones(chord)
  let tension_tones = get_extended_tension_tones(chord)
  let scale_tones = get_extended_scale_tones(chord, key)
  let approach_tones = get_extended_approach_tones(chord)
  match last_midi {
    Some(prev) => {
      // Filter candidates by max interval
      let chord_tones = filter_by_interval(chord_tones, prev, max_interval)
      let tension_tones = filter_by_interval(tension_tones, prev, max_interval)
      let scale_tones = filter_by_interval(scale_tones, prev, max_interval)
      let approach_tones = filter_by_interval(
        approach_tones, prev, max_interval,
      )
      // Calculate weights for chord tones
      let weighted_chord : Array[(Int, @music.MidiNumber)] = chord_tones
        .iter()
        .map(fn(tone) {
          let cost = interval_cost(prev, tone)
          let weight = note_selection_weight(stamina, cost)
          (weight, tone)
        })
        .collect()
      // Calculate weights for tension tones (between chord and scale)
      let weighted_tension : Array[(Int, @music.MidiNumber)] = tension_tones
        .iter()
        .map(fn(tone) {
          let cost = interval_cost(prev, tone)
          let weight = note_selection_weight(stamina, cost) *
            tension_weight_ratio /
            100
          (@cmp.maximum(1, weight), tone)
        })
        .collect()
      // Calculate weights for scale tones (reduced by ratio)
      let weighted_scale : Array[(Int, @music.MidiNumber)] = scale_tones
        .iter()
        .map(fn(tone) {
          let cost = interval_cost(prev, tone)
          let weight = note_selection_weight(stamina, cost) *
            scale_tone_weight_ratio /
            100
          (@cmp.maximum(1, weight), tone)
        })
        .collect()
      // Calculate weights for approach tones (chromatic half-steps to chord tones)
      let weighted_approach : Array[(Int, @music.MidiNumber)] = approach_tones
        .iter()
        .map(fn(tone) {
          let cost = interval_cost(prev, tone)
          let weight = note_selection_weight(stamina, cost) *
            approach_weight_ratio /
            100
          (@cmp.maximum(1, weight), tone)
        })
        .collect()
      let weighted_tones = weighted_chord +
        weighted_tension +
        weighted_scale +
        weighted_approach
      let total = weighted_tones
        .iter()
        .fold(init=0, fn(acc, pair) { acc + pair.0 })
      let r = random_int(total)
      let mut cumulative = 0
      for pair in weighted_tones {
        cumulative = cumulative + pair.0
        if r < cumulative {
          return Some(pair.1)
        }
      }
      Some(weighted_tones[weighted_tones.length() - 1].1)
    }
    None => {
      // First note: uniform random from chord tones only
      let index = random_int(chord_tones.length())
      Some(chord_tones[index])
    }
  }
}
