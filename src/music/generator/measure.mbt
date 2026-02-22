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
  incoming_motif_memory : MotifMemory // Motif memory from previous measure
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
  outgoing_motif_memory : MotifMemory // Motif memory to pass to next measure
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
  enclosure_weight_ratio : Int // 0-100, enclosure tone weight as % of chord tone weight
  phrase_length_min : Int // Minimum notes in a phrase (default: 2)
  phrase_length_max : Int // Maximum notes in a phrase (default: 8)
  phrase_early_end_stamina : Int // Below this stamina, phrase may end early (default: 15)
  max_interval : Int // Maximum interval jump in semitones (default: 7 = perfect fifth)
  syncopation_probability : Int // 0-100, chance of forcing off-beat phrase start on downbeats (default: 40)
  motif_reuse_probability : Int // 0-100, chance of replaying a stored motif when starting a new phrase (default: 30)
  triplet_probability : Int // 0-100, chance of generating eighth-note triplet group when playing (default: 15)
  bebop_weight_ratio : Int // 0-100, bebop passing tone weight as % of chord tone weight (default: 0 = disabled)
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
    enclosure_weight_ratio: 15,
    phrase_length_min: 2,
    phrase_length_max: 8,
    phrase_early_end_stamina: 15,
    max_interval: 7,
    syncopation_probability: 40,
    motif_reuse_probability: 30,
    triplet_probability: 8,
    bebop_weight_ratio: 0,
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
  motif_memory : MotifMemory
  motif_first_note : Bool // true if next note is the first in the current phrase
}

///|
fn MeasureState::new(
  num_beats : Int,
  stamina : Int,
  last_midi : @music.MidiNumber?,
  phrase : PhraseState,
  motif_memory : MotifMemory,
) -> MeasureState {
  MeasureState::{
    measure_pos: 0.0,
    beat_notes: Array::makei(num_beats, fn(_) { [] }),
    stamina,
    last_midi,
    last_was_rest: false,
    phrase,
    motif_memory,
    motif_first_note: match phrase {
      Playing(_) => false // continuing phrase from previous measure
      Resting => true // will be set properly when entering Playing
    },
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
    motif_memory: self.motif_memory,
    motif_first_note: self.motif_first_note,
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
  // Transpose everything to key of C so the RNG sequence is key-independent.
  // Only pitch values change with key; rhythm/structure remain identical.
  let offset = ctx.key.root.midi() - 60 // semitones from C
  let neg_offset = -offset

  // Transpose input to C
  let c_chords = ctx.chords.map(fn(seg) {
    ChordSegment::{
      chord: seg.chord.transpose(neg_offset),
      start_beat: seg.start_beat,
      end_beat: seg.end_beat,
    }
  })
  let c_incoming_tie = ctx.incoming_tie.map(fn(tie) {
    TieContext::{
      midi: tie.midi.transpose(neg_offset),
      remaining_beats: tie.remaining_beats,
    }
  })
  let c_incoming_last_midi = ctx.incoming_last_midi.map(fn(m) {
    m.transpose(neg_offset)
  })
  let c_ctx = MeasureContext::{
    chords: c_chords,
    incoming_tie: c_incoming_tie,
    key: @music.KeySignature::c_major(),
    time_signature: ctx.time_signature,
    beats_per_measure: ctx.beats_per_measure,
    incoming_stamina: ctx.incoming_stamina,
    incoming_last_midi: c_incoming_last_midi,
    incoming_phrase: ctx.incoming_phrase,
    incoming_motif_memory: ctx.incoming_motif_memory,
  }

  // Convert Int? to PhraseState
  let incoming_phrase = match c_ctx.incoming_phrase {
    Some(n) => Playing(n)
    None => Resting
  }

  let initial_state = MeasureState::new(
    c_ctx.beats_per_measure.to_int(),
    c_ctx.incoming_stamina,
    c_ctx.incoming_last_midi,
    incoming_phrase,
    c_ctx.incoming_motif_memory,
  )

  // Handle incoming tie first
  let (state_after_tie, outgoing_tie) = match c_ctx.incoming_tie {
    Some(tie_ctx) =>
      process_incoming_tie(initial_state, tie_ctx, c_ctx.beats_per_measure)
    None => (initial_state, None)
  }

  // Fill remaining measure with new notes (all in key of C)
  // Use a temporary accidental calculator for C major during generation
  let c_update_accidental = @music.create_accidental_calculator(
    @music.KeySignature::c_major(),
  )
  let final_state = fill_remaining_measure(
    state_after_tie, c_ctx, settings, c_update_accidental, random_int,
  )

  // Transpose output back to the real key
  let real_update_accidental = @music.create_accidental_calculator(ctx.key)
  let beats = final_state
    .to_beats()
    .map(fn(beat) {
      @music.Beat::{
        count: beat.count,
        notes: beat.notes.map(fn(note) {
          match note.midi {
            Some(midi_val) => {
              let real_midi = @music.MidiNumber::new(midi_val)
                .unwrap()
                .transpose(offset)
              @music.MeasureNote::{
                midi: Some(real_midi.value),
                duration: note.duration,
                accidental: real_update_accidental(real_midi),
                tie: note.tie,
                tone_origin: note.tone_origin,
              }
            }
            None => note
          }
        }),
      }
    })

  // Convert PhraseState back to Int?
  let outgoing_phrase = match final_state.phrase {
    Playing(n) => Some(n)
    Resting => None
  }
  let real_outgoing_tie = outgoing_tie.map(fn(tie) {
    TieContext::{
      midi: tie.midi.transpose(offset),
      remaining_beats: tie.remaining_beats,
    }
  })
  let real_outgoing_last_midi = final_state.last_midi.map(fn(m) {
    m.transpose(offset)
  })
  MeasureResult::{
    beats,
    outgoing_tie: real_outgoing_tie,
    outgoing_stamina: final_state.stamina,
    outgoing_last_midi: real_outgoing_last_midi,
    outgoing_phrase,
    outgoing_motif_memory: final_state.motif_memory,
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
        tone_origin: None,
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
/// Find the closest available chord/scale tone to a target MIDI number.
/// Used for motif-guided note selection where the target comes from replaying
/// a stored interval pattern.
fn select_motif_guided_note(
  target_value : Int,
  chord : @music.Chord,
  last_midi : @music.MidiNumber,
  max_interval : Int,
) -> @music.MidiNumber? {
  let target = match @music.MidiNumber::new(target_value) {
    Some(t) => t
    None => return None // target out of valid MIDI range
  }

  let chord_tones = filter_by_interval(
    extend_across_octaves(chord.tones()),
    last_midi,
    max_interval,
  )
  let scale_tones = filter_by_interval(
    extend_across_octaves(chord.scale_tones()),
    last_midi,
    max_interval,
  )
  let all_tones = chord_tones + scale_tones
  guard not(all_tones.is_empty()) else { return None }

  let mut best = all_tones[0]
  let mut best_dist = target.distance(best)
  for tone in all_tones {
    let d = target.distance(tone)
    if d < best_dist {
      best = tone
      best_dist = d
    }
  }
  Some(best)
}

///|
/// Select a note, using motif-guided selection if replaying, otherwise normal selection.
/// Returns (midi_option, tone_origin_option, updated_motif_memory).
fn select_note_with_motif(
  state : MeasureState,
  chord : @music.Chord,
  settings : Settings,
  random_int : (Int) -> Int,
) -> (@music.MidiNumber?, @music.ToneOrigin?, MotifMemory) {
  // First note of phrase: always use normal selection
  guard not(state.motif_first_note) else {
    let (midi, origin) = decide_midi_number(
      chord,
      state.last_midi,
      state.stamina,
      settings.stamina_max,
      state.last_was_rest,
      0,
      settings.scale_tone_weight_ratio,
      settings.tension_weight_ratio,
      settings.approach_weight_ratio,
      settings.enclosure_weight_ratio,
      settings.bebop_weight_ratio,
      settings.max_interval,
      random_int,
    )
    return (midi, origin, state.motif_memory)
  }

  // Try motif-guided selection if replaying
  match state.motif_memory.next_replay_interval() {
    Some((interval, updated_memory)) =>
      match state.last_midi {
        Some(prev) => {
          let target = prev.value + interval
          match
            select_motif_guided_note(target, chord, prev, settings.max_interval) {
            Some(midi) => (Some(midi), Some(@music.MotifReplay), updated_memory)
            None => {
              // Motif interval didn't work, fall back to normal selection
              let (midi, origin) = decide_midi_number(
                chord,
                state.last_midi,
                state.stamina,
                settings.stamina_max,
                state.last_was_rest,
                0,
                settings.scale_tone_weight_ratio,
                settings.tension_weight_ratio,
                settings.approach_weight_ratio,
                settings.enclosure_weight_ratio,
                settings.bebop_weight_ratio,
                settings.max_interval,
                random_int,
              )
              (midi, origin, MotifMemory::{ ..updated_memory, replaying: None })
            }
          }
        }
        None => {
          let (midi, origin) = decide_midi_number(
            chord,
            state.last_midi,
            state.stamina,
            settings.stamina_max,
            state.last_was_rest,
            0,
            settings.scale_tone_weight_ratio,
            settings.tension_weight_ratio,
            settings.approach_weight_ratio,
            settings.enclosure_weight_ratio,
            settings.bebop_weight_ratio,
            settings.max_interval,
            random_int,
          )
          (midi, origin, state.motif_memory)
        }
      }
    None => {
      // Not replaying or replay finished, use normal selection
      let (midi, origin) = decide_midi_number(
        chord,
        state.last_midi,
        state.stamina,
        settings.stamina_max,
        state.last_was_rest,
        0,
        settings.scale_tone_weight_ratio,
        settings.tension_weight_ratio,
        settings.approach_weight_ratio,
        settings.enclosure_weight_ratio,
        settings.bebop_weight_ratio,
        settings.max_interval,
        random_int,
      )
      (midi, origin, state.motif_memory)
    }
  }
}

///|
/// Record the interval between the current note and previous note into motif memory,
/// but only when recording (not replaying) and not on the first note of a phrase.
fn record_motif_interval(
  motif_memory : MotifMemory,
  prev_midi : @music.MidiNumber?,
  current_midi : @music.MidiNumber,
  first_note : Bool,
) -> MotifMemory {
  guard not(first_note) && motif_memory.replaying is None else {
    return motif_memory
  }
  match prev_midi {
    Some(prev) => motif_memory.record_interval(current_midi.value - prev.value)
    None => motif_memory
  }
}

///|
/// Choose a motif to replay (with optional inversion) when starting a new phrase.
/// Returns updated motif memory with replay started, or unchanged if no replay.
fn maybe_start_motif_replay(
  motif_memory : MotifMemory,
  settings : Settings,
  random_int : (Int) -> Int,
) -> MotifMemory {
  guard not(motif_memory.stored.is_empty()) &&
    random_int(100) < settings.motif_reuse_probability else {
    return motif_memory
  }
  let index = random_int(motif_memory.stored.length())
  let motif = motif_memory.stored[index]
  // 40% chance to invert the motif for variation
  let motif = if random_int(100) < 40 { motif.invert() } else { motif }
  motif_memory.start_replay(motif)
}

///|
/// Result of a single step in fill_remaining_measure
priv enum StepResult {
  Continue(MeasureState)
  Break(MeasureState)
}

///|
/// Handle the Resting phase: emit a rest note and transition to a new Playing phrase
fn handle_resting(
  state : MeasureState,
  remaining : Double,
  settings : Settings,
  random_int : (Int) -> Int,
) -> StepResult {
  let motif_memory = state.motif_memory.finish_recording()
  let duration = match
    syncopation_rest(
      state.measure_pos,
      remaining,
      settings.syncopation_probability,
      random_int,
    ) {
    Some(d) => Some(d)
    None =>
      random_duration_within(
        remaining,
        settings.rest_duration_weights,
        random_int,
      )
  }
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
        tone_origin: None,
      })
      let new_phrase_len = roll_phrase_length(settings, random_int)
      let new_motif_memory = maybe_start_motif_replay(
        motif_memory, settings, random_int,
      )
      Continue(MeasureState::{
        measure_pos: state.measure_pos + duration.to_beats(),
        beat_notes: state.beat_notes,
        stamina: new_stamina,
        last_midi: state.last_midi,
        last_was_rest: true,
        phrase: Playing(new_phrase_len),
        motif_memory: new_motif_memory,
        motif_first_note: true,
      })
    }
    None => Break(MeasureState::{ ..state, motif_memory, })
  }
}

///|
/// Handle the Playing phase: generate a note or triplet, or transition to Resting
fn handle_playing(
  state : MeasureState,
  notes_left : Int,
  chord : @music.Chord,
  ctx : MeasureContext,
  remaining : Double,
  settings : Settings,
  update_accidental : (@music.MidiNumber) -> @music.Accidental?,
  random_int : (Int) -> Int,
) -> StepResult {
  // Check for early phrase termination due to low stamina
  let should_end_early = notes_left > 1 &&
    state.stamina < settings.phrase_early_end_stamina &&
    ({
      let prob = effective_rest_probability(
        settings.rest_probability,
        state.stamina,
        settings.stamina_max,
        state.last_was_rest,
      )
      random_int(100) < prob
    })
  guard not(should_end_early) else {
    return Continue(MeasureState::{ ..state, phrase: Resting })
  }
  // Try to generate a triplet group (3 eighth triplets = 1 beat)
  guard not(
    should_generate_triplet(
      state.measure_pos,
      notes_left,
      remaining,
      settings.triplet_probability,
      random_int,
    ),
  ) else {
    return Continue(
      generate_triplet_group(
        state, chord, ctx, settings, update_accidental, random_int, notes_left,
      ),
    )
  }
  // Select note using motif-guided or normal selection
  let (midi_opt, tone_origin, new_motif_memory) = select_note_with_motif(
    state, chord, settings, random_int,
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
          let new_motif_memory = record_motif_interval(
            new_motif_memory,
            state.last_midi,
            midi,
            state.motif_first_note,
          )
          let beat_index = state.measure_pos.to_int()
          state.beat_notes[beat_index].push(@music.MeasureNote::{
            midi: Some(midi.value),
            duration,
            accidental: update_accidental(midi),
            tie: None,
            tone_origin,
          })
          let next_phrase = match notes_left {
            1 => Resting
            n => Playing(n - 1)
          }
          Continue(MeasureState::{
            measure_pos: state.measure_pos + duration.to_beats(),
            beat_notes: state.beat_notes,
            stamina: new_stamina,
            last_midi: Some(midi),
            last_was_rest: false,
            phrase: next_phrase,
            motif_memory: new_motif_memory,
            motif_first_note: false,
          })
        }
        None => Break(state)
      }
    None => Break(state)
  }
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
    let chord = ctx.chord_at(state.measure_pos)
    let result = match state.phrase {
      Resting => handle_resting(state, remaining, settings, random_int)
      Playing(notes_left) =>
        handle_playing(
          state, notes_left, chord, ctx, remaining, settings, update_accidental,
          random_int,
        )
    }
    match result {
      Continue(next) => continue next
      Break(final_state) => break final_state
    }
  }
}

///|
/// Get extended chord tones across multiple octaves
/// Octave offsets for extending tone sets: one octave below, same, one above
let octave_offsets : Array[Int] = [-1, 0, 1]

///|
fn extend_across_octaves(
  tones : Array[@music.MidiNumber],
) -> Array[@music.MidiNumber] {
  octave_offsets
  .iter()
  .flat_map(fn(octave_offset) {
    tones.iter().filter_map(fn(tone) { tone.shift_octave(octave_offset) })
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
/// Decide whether to generate a note or rest, and if note, which MIDI number.
/// Returns (midi, tone_origin) pair: both None for rests, both Some for notes.
/// Uses stamina-based weighted selection for chord tones.
fn decide_midi_number(
  chord : @music.Chord,
  last_midi : @music.MidiNumber?,
  stamina : Int,
  stamina_max : Int,
  last_was_rest : Bool,
  rest_probability : Int,
  scale_tone_weight_ratio : Int,
  tension_weight_ratio : Int,
  approach_weight_ratio : Int,
  enclosure_weight_ratio : Int,
  bebop_weight_ratio : Int,
  max_interval : Int,
  random_int : (Int) -> Int,
) -> (@music.MidiNumber?, @music.ToneOrigin?) {
  let actual_rest_prob = effective_rest_probability(
    rest_probability, stamina, stamina_max, last_was_rest,
  )
  guard random_int(100) >= actual_rest_prob else { return (None, None) }

  let chord_tones = extend_across_octaves(chord.tones())
  let tension_tones = extend_across_octaves(chord.tension_tones())
  let scale_tones = extend_across_octaves(chord.scale_tones())
  let approach_tones = extend_across_octaves(chord.approach_tones())
  let enclosure_tones = extend_across_octaves(chord.enclosure_tones())
  let bebop_tones = extend_across_octaves(chord.bebop_passing_tones())
  let root_midi = chord.root.midi()
  match last_midi {
    Some(prev) => {
      let weighted_tones : Array[(Int, @music.MidiNumber, @music.ToneOrigin)] = weighted_tone_candidates_tagged(
          chord_tones,
          prev,
          stamina,
          max_interval,
          100,
          @music.ChordTone,
        ) +
        weighted_tone_candidates_tagged(
          tension_tones,
          prev,
          stamina,
          max_interval,
          tension_weight_ratio,
          @music.Tension(0), // placeholder; will be replaced per-tone below
        ) +
        weighted_tone_candidates_tagged(
          scale_tones,
          prev,
          stamina,
          max_interval,
          scale_tone_weight_ratio,
          @music.ScaleTone,
        ) +
        weighted_tone_candidates_tagged(
          approach_tones,
          prev,
          stamina,
          max_interval,
          approach_weight_ratio,
          @music.ApproachTone,
        ) +
        weighted_tone_candidates_tagged(
          enclosure_tones,
          prev,
          stamina,
          max_interval,
          enclosure_weight_ratio,
          @music.Enclosure,
        ) +
        weighted_tone_candidates_tagged(
          bebop_tones,
          prev,
          stamina,
          max_interval,
          bebop_weight_ratio,
          @music.PassingTone,
        )
      // Fix tension degrees now that we have the candidates
      let fixed_tones = weighted_tones.map(fn(tuple) {
        let (weight, tone, origin) = tuple
        let fixed_origin = match origin {
          @music.Tension(_) => {
            let degree = tension_degree(root_midi, tone)
            @music.Tension(degree)
          }
          other => other
        }
        (weight, tone, fixed_origin)
      })
      match weighted_random_select_tagged(fixed_tones, random_int) {
        Some((midi, origin)) => (Some(midi), Some(origin))
        None => (None, None)
      }
    }
    None => {
      // First note: uniform random from chord tones only
      let index = random_int(chord_tones.length())
      (Some(chord_tones[index]), Some(@music.ChordTone))
    }
  }
}
