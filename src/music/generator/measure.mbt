///|
/// A chord with its time range within a measure
pub(all) struct ChordSegment {
  chord : @music.Chord
  start_beat : Double
  end_beat : Double
} derive(Eq, Show)

///|
/// Context passed to MeasureGenerator
pub struct MeasureContext {
  chords : Array[ChordSegment] // Chord segments within this measure
  incoming_tie : TieContext? // Tie from previous measure
  key : @music.KeySignature
  beats_per_measure : Double
  incoming_stamina : Int // Stamina from previous measure
  incoming_last_midi : @music.MidiNumber? // Last note from previous measure
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
}

///|
fn MeasureState::new(
  num_beats : Int,
  stamina : Int,
  last_midi : @music.MidiNumber?,
) -> MeasureState {
  MeasureState::{
    measure_pos: 0.0,
    beat_notes: Array::makei(num_beats, fn(_) { [] }),
    stamina,
    last_midi,
    last_was_rest: false,
  }
}

///|
fn MeasureState::add_note(
  self : MeasureState,
  note : @music.MeasureNote,
) -> MeasureState {
  let beat_index = self.measure_pos.to_int()
  self.beat_notes[beat_index].push(note)
  MeasureState::{
    measure_pos: self.measure_pos + note.duration.to_beats(),
    beat_notes: self.beat_notes,
    stamina: self.stamina,
    last_midi: self.last_midi,
    last_was_rest: note.midi is None, // rest if no MIDI
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
  let initial_state = MeasureState::new(
    ctx.beats_per_measure.to_int(),
    ctx.incoming_stamina,
    ctx.incoming_last_midi,
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
  MeasureResult::{
    beats: final_state.to_beats(),
    outgoing_tie,
    outgoing_stamina: final_state.stamina,
    outgoing_last_midi: final_state.last_midi,
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
    let new_state = state.add_note(@music.MeasureNote::{
      midi: Some(midi.value),
      duration: fitted,
      accidental: None,
      tie: Some(tie),
    })
    continue remaining - fitted.to_beats(), new_state
  }
}

///|
/// Fill remaining measure with new notes
fn fill_remaining_measure(
  state : MeasureState,
  ctx : MeasureContext,
  settings : Settings,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  random_int : (Int) -> Int,
) -> MeasureState {
  for state = state {
    guard state.measure_pos < ctx.beats_per_measure else { break state }
    let remaining = ctx.beats_per_measure - state.measure_pos
    // Get chord at current beat position
    let chord = ctx.chord_at(state.measure_pos)
    let (midi_opt, weights) = match
      decide_midi_number(
        chord,
        state.last_midi,
        state.stamina,
        settings.stamina_max,
        state.last_was_rest,
        settings.rest_probability,
        random_int,
      ) {
      Some(midi) => (Some(midi), settings.note_duration_weights)
      None => (None, settings.rest_duration_weights)
    }
    match random_duration_within(remaining, weights, random_int) {
      Some(duration) => {
        // Update stamina based on note or rest
        let (new_stamina, new_last_midi) = match midi_opt {
          Some(midi) => {
            // Playing a note: consume cost + passive recovery
            let cost = match state.last_midi {
              Some(prev) => interval_cost(prev, midi)
              None => 0 // First note has no cost
            }
            let stamina = @cmp.maximum(
              0,
              @cmp.minimum(
                state.stamina - cost + settings.stamina_passive_recovery,
                settings.stamina_max,
              ),
            )
            (stamina, Some(midi))
          }
          None => {
            // Rest: recover stamina based on duration
            let recovery = (duration.to_beats() *
            settings.stamina_recovery_per_beat.to_double()).to_int()
            let stamina = @cmp.minimum(
              state.stamina + recovery,
              settings.stamina_max,
            )
            (stamina, state.last_midi)
          }
        }
        let beat_index = state.measure_pos.to_int()
        let is_rest = midi_opt is None
        state.beat_notes[beat_index].push(@music.MeasureNote::{
          midi: midi_opt.map(fn(m) { m.value }),
          duration,
          accidental: midi_opt.bind(update_accidental),
          tie: None,
        })
        continue MeasureState::{
            measure_pos: state.measure_pos + duration.to_beats(),
            beat_notes: state.beat_notes,
            stamina: new_stamina,
            last_midi: new_last_midi,
            last_was_rest: is_rest,
          }
      }
      None => break state
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
/// Decide whether to generate a note or rest, and if note, which MIDI number
/// Uses stamina-based weighted selection for chord tones
fn decide_midi_number(
  chord : @music.Chord,
  last_midi : @music.MidiNumber?,
  stamina : Int,
  stamina_max : Int,
  last_was_rest : Bool,
  rest_probability : Int,
  random_int : (Int) -> Int,
) -> @music.MidiNumber? {
  let actual_rest_prob = effective_rest_probability(
    rest_probability, stamina, stamina_max, last_was_rest,
  )
  guard random_int(100) >= actual_rest_prob else { return None }
  let extended_tones = get_extended_tones(chord)
  match last_midi {
    Some(prev) => {
      // Calculate weights based on stamina and interval cost
      let weighted_tones : Array[(Int, @music.MidiNumber)] = extended_tones
        .iter()
        .map(fn(tone) {
          let cost = interval_cost(prev, tone)
          let weight = note_selection_weight(stamina, cost)
          (weight, tone)
        })
        .collect()
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
      // First note: uniform random selection
      let index = random_int(extended_tones.length())
      Some(extended_tones[index])
    }
  }
}
