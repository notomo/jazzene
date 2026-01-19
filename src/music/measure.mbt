///|
/// Measure representation for lead sheet visualization
/// Converts NoteValueSound arrays into measure-organized data structures

///|
/// Accidental types for note display
pub enum Accidental {
  Sharp
  Flat
  Natural
} derive(Eq, Show)

///|
/// Tie state for notes that span measure boundaries
pub enum TieState {
  None // No tie
  TieStart // Ties to next measure
  TieEnd // Tied from previous measure
  TieBoth // Spans 3+ measures (both in and out)
} derive(Eq, Show)

///|
/// Pitch state within a measure for accidental tracking
enum PitchState {
  Natural
  Sharpened
  Flattened
} derive(Eq)

///|
/// Represents one measure with its chord and notes
pub struct Measure {
  chord : Chord
  notes : Array[MeasureNote]
  start_time : Duration
  duration : Duration
  measure_index : Int
}

///|
/// A note positioned within a measure
pub struct MeasureNote {
  midi : Int? // None for rests
  duration : NoteDuration
  start_beat : Double // 0.0 to 4.0 for 4/4 time
  accidental : Accidental? // Sharp, Flat, or Natural symbol to display
  tie_state : TieState // Tie connection state for cross-measure notes
}

///|
/// Determine the required pitch state for a MIDI number
/// Based on C major key (no sharps/flats), so black keys need accidentals
fn midi_to_required_state(midi : Int) -> PitchState {
  let pitch_class = midi % 12
  match pitch_class {
    1 => Sharpened // C#
    3 => Flattened // Eb (prefer flat per ChordRoot convention)
    6 => Sharpened // F#
    8 => Flattened // Ab (prefer flat per ChordRoot convention)
    10 => Flattened // Bb (prefer flat per ChordRoot convention)
    _ => PitchState::Natural // White keys
  }
}

///|
/// Calculate the accidental to display based on current pitch states
/// Returns None if no accidental change is needed
fn calculate_accidental(
  midi : Int,
  pitch_states : Map[Int, PitchState],
) -> Accidental? {
  let pitch_class = midi % 12
  let required_state = midi_to_required_state(midi)
  let current_state = pitch_states
    .get(pitch_class)
    .unwrap_or(PitchState::Natural)
  if required_state == current_state {
    None // No change needed
  } else {
    // State change needed, return appropriate accidental
    match required_state {
      PitchState::Natural => Some(Accidental::Natural)
      Sharpened => Some(Sharp)
      Flattened => Some(Flat)
    }
  }
}

///|
/// Convert MIDI pitch class to diatonic steps from C
fn pitch_class_to_diatonic_step(pitch_class : Int) -> Int {
  match pitch_class {
    0 | 1 => 0 // C, C#
    2 | 3 => 1 // D, D#
    4 => 2 // E
    5 | 6 => 3 // F, F#
    7 | 8 => 4 // G, G#
    9 | 10 => 5 // A, A#
    11 => 6 // B
    _ => 0
  }
}

///|
/// Convert MIDI number to Y position on staff
/// E4 (MIDI 64) is the bottom line of treble clef
pub fn midi_to_staff_y(midi : Int, staff_y : Double) -> Double {
  let staff_line_spacing = 15.0

  // Calculate pitch class and octave
  let pitch_class = midi % 12
  let octave = midi / 12 - 1

  // Calculate diatonic steps from E4
  // E4 = pitch_class 4, octave 4
  let e4_pitch_class = 4
  let e4_octave = 4
  let note_diatonic_step = pitch_class_to_diatonic_step(pitch_class)
  let e4_diatonic_step = pitch_class_to_diatonic_step(e4_pitch_class)
  let total_diatonic_steps = (octave - e4_octave) * 7 +
    (note_diatonic_step - e4_diatonic_step)

  // E4 is on the bottom line (staff_y + 4 * staff_line_spacing)
  // Each diatonic step = half a line spacing
  let offset = total_diatonic_steps.to_double() * -(staff_line_spacing / 2.0)
  staff_y + staff_line_spacing * 4.0 + offset
}

///|
/// Intermediate representation of a note before accidental calculation
priv struct RawMeasureNote {
  midi : Int?
  duration : NoteDuration
  start_beat : Double
  tie_state : TieState
  measure_index : Int
}

///|
/// Split a sound across measure boundaries if needed
fn split_sound_across_measures(
  sound : NoteValueSound,
  measure_duration_ms : Double,
  measure_count : Int,
) -> Array[RawMeasureNote] {
  let result : Array[RawMeasureNote] = []
  let sound_start_ms = sound.start_time.to_milliseconds()
  let beat_duration_ms = measure_duration_ms / 4.0

  // Calculate which measure this sound starts in
  let start_measure_index = (sound_start_ms / measure_duration_ms).to_int()

  // If sound starts beyond our measures, skip it
  if start_measure_index >= measure_count {
    return result
  }

  // Calculate start beat within the measure
  let measure_start_ms = start_measure_index.to_double() * measure_duration_ms
  let start_beat = (sound_start_ms - measure_start_ms) / beat_duration_ms

  // Get MIDI and duration
  let midi = sound.note_value.midi().map(fn(m) { m.value })
  let total_beats = sound.note_value.note_duration().to_beats()

  // Rests cannot be tied - don't split them
  match midi {
    None => {
      result.push(RawMeasureNote::{
        midi: None,
        duration: sound.note_value.note_duration(),
        start_beat,
        tie_state: TieState::None,
        measure_index: start_measure_index,
      })
      return result
    }
    Some(_) => ()
  }

  // Check if note spans across measure boundaries
  let beats_until_measure_end = 4.0 - start_beat
  if total_beats <= beats_until_measure_end {
    // Note fits in this measure
    result.push(RawMeasureNote::{
      midi,
      duration: sound.note_value.note_duration(),
      start_beat,
      tie_state: TieState::None,
      measure_index: start_measure_index,
    })
  } else {
    // Note spans measures - split it
    let mut remaining_beats = total_beats
    let mut current_measure = start_measure_index
    let mut current_beat = start_beat
    let mut is_first = true
    while remaining_beats > 0.0 && current_measure < measure_count {
      let beats_until_end = 4.0 - current_beat
      if remaining_beats <= beats_until_end {
        // Remaining part fits in this measure
        let tie_state : TieState = if is_first {
          TieState::None
        } else {
          TieEnd
        }
        result.push(RawMeasureNote::{
          midi,
          duration: NoteDuration::from_beats(remaining_beats),
          start_beat: current_beat,
          tie_state,
          measure_index: current_measure,
        })
        remaining_beats = 0.0
      } else {
        // Spans to next measure
        let tie_state : TieState = if is_first { TieStart } else { TieBoth }
        result.push(RawMeasureNote::{
          midi,
          duration: NoteDuration::from_beats(beats_until_end),
          start_beat: current_beat,
          tie_state,
          measure_index: current_measure,
        })
        remaining_beats = remaining_beats - beats_until_end
        current_measure = current_measure + 1
        current_beat = 0.0
        is_first = false
      }
    }
  }
  result
}

///|
/// Calculate accidentals for a list of raw notes in a single measure
/// TieEnd notes don't get accidentals (pitch already established)
fn apply_accidentals_to_notes(
  raw_notes : Array[RawMeasureNote],
) -> Array[MeasureNote] {
  // Sort by start_beat to ensure correct accidental calculation order
  raw_notes.sort_by(fn(a, b) { a.start_beat.compare(b.start_beat) })
  let pitch_states : Map[Int, PitchState] = {}
  let measure_notes : Array[MeasureNote] = []
  for note in raw_notes {
    let accidental : Accidental? = match note.midi {
      Some(midi) => {
        // TieEnd notes don't show accidentals (pitch established in previous measure)
        let acc : Accidental? = match note.tie_state {
          TieEnd | TieBoth => None
          _ => calculate_accidental(midi, pitch_states)
        }
        // Update pitch state after calculating accidental
        let pitch_class = midi % 12
        pitch_states[pitch_class] = midi_to_required_state(midi)
        acc
      }
      None => None
    }
    measure_notes.push(MeasureNote::{
      midi: note.midi,
      duration: note.duration,
      start_beat: note.start_beat,
      accidental,
      tie_state: note.tie_state,
    })
  }
  measure_notes
}

///|
/// Convert sounds array to measures array
/// measure_count specifies the total number of measures (including leading rest)
/// Notes that span across measure boundaries are split with appropriate tie states
pub fn convert_sounds_to_measures(
  sounds : Array[NoteValueSound],
  chords : Array[Chord],
  bpm : Int,
  measure_count : Int,
) -> Array[Measure] {
  let measure_duration_ms = 60000.0 * 4.0 / bpm.to_double()

  // Step 1: Split all sounds across measure boundaries
  let all_raw_notes : Array[RawMeasureNote] = []
  for sound in sounds {
    let split_notes = split_sound_across_measures(
      sound, measure_duration_ms, measure_count,
    )
    for note in split_notes {
      all_raw_notes.push(note)
    }
  }

  // Step 2: Group raw notes by measure index
  let notes_by_measure : Map[Int, Array[RawMeasureNote]] = {}
  for note in all_raw_notes {
    match notes_by_measure.get(note.measure_index) {
      Some(arr) => arr.push(note)
      None => notes_by_measure[note.measure_index] = [note]
    }
  }

  // Step 3: Create measures with accidentals applied
  let measures : Array[Measure] = []

  // Add leading rest measure with dummy chord (always C major to avoid confusion)
  let dummy_chord = Chord::{ root: ChordRoot::C, quality: Major }
  let leading_rest_raw = notes_by_measure.get(0).unwrap_or([])
  let leading_rest_notes = apply_accidentals_to_notes(leading_rest_raw)
  measures.push(Measure::{
    chord: dummy_chord,
    notes: leading_rest_notes,
    start_time: Duration::from_milliseconds(0.0),
    duration: Duration::from_milliseconds(measure_duration_ms),
    measure_index: 0,
  })

  // Calculate number of chord measures needed (total - 1 for leading rest)
  let chord_measures_needed = measure_count - 1

  // If no chords or no measures needed, return just the leading rest
  if chords.length() == 0 || chord_measures_needed <= 0 {
    return measures
  }

  // Create chord measures
  for i = 0; i < chord_measures_needed; i = i + 1 {
    let chord = chords[i % chords.length()]
    let measure_index = i + 1
    let measure_start = measure_index.to_double() * measure_duration_ms

    // Get raw notes for this measure and apply accidentals
    let raw_notes = notes_by_measure.get(measure_index).unwrap_or([])
    let measure_notes = apply_accidentals_to_notes(raw_notes)
    measures.push(Measure::{
      chord,
      notes: measure_notes,
      start_time: Duration::from_milliseconds(measure_start),
      duration: Duration::from_milliseconds(measure_duration_ms),
      measure_index,
    })
  }
  measures
}
