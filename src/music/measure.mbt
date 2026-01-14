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
/// Helper to create MeasureNotes with accidentals calculated
fn create_measure_notes_with_accidentals(
  sounds : Array[NoteValueSound],
  measure_start_ms : Double,
  measure_end_ms : Double,
  measure_duration_ms : Double,
) -> Array[MeasureNote] {
  // Collect raw note data with timing
  let raw_notes : Array[(Int?, NoteDuration, Double)] = []
  for sound in sounds {
    let sound_start = sound.start_time.to_milliseconds()
    if sound_start >= measure_start_ms && sound_start < measure_end_ms {
      let beat_offset = (sound_start - measure_start_ms) /
        (measure_duration_ms / 4.0)
      raw_notes.push(
        (
          sound.note_value.midi().map(fn(m) { m.value }),
          sound.note_value.note_duration(),
          beat_offset,
        ),
      )
    }
  }

  // Sort by start_beat to ensure correct accidental calculation order
  raw_notes.sort_by(fn(a, b) { a.2.compare(b.2) })

  // Calculate accidentals with pitch state tracking
  let pitch_states : Map[Int, PitchState] = {}
  let measure_notes : Array[MeasureNote] = []
  for note in raw_notes {
    let (midi_opt, duration, start_beat) = note
    let accidental = match midi_opt {
      Some(midi) => {
        let acc = calculate_accidental(midi, pitch_states)
        // Update pitch state after calculating accidental
        let pitch_class = midi % 12
        pitch_states[pitch_class] = midi_to_required_state(midi)
        acc
      }
      None => None
    }
    measure_notes.push(MeasureNote::{
      midi: midi_opt,
      duration,
      start_beat,
      accidental,
    })
  }
  measure_notes
}

///|
/// Convert sounds array to measures array
/// measure_count specifies the total number of measures (including leading rest)
pub fn convert_sounds_to_measures(
  sounds : Array[NoteValueSound],
  chords : Array[Chord],
  bpm : Int,
  measure_count : Int,
) -> Array[Measure] {
  let measure_duration_ms = 60000.0 * 4.0 / bpm.to_double()
  let measures = []

  // Account for leading rest (1 measure = 4 beats)
  let leading_rest_duration = measure_duration_ms

  // Create leading rest measure with accidentals
  let leading_rest_notes = create_measure_notes_with_accidentals(
    sounds, 0.0, leading_rest_duration, measure_duration_ms,
  )

  // Add leading rest measure with dummy chord (always C major to avoid confusion)
  let dummy_chord = Chord::{ root: ChordRoot::C, quality: Major }
  measures.push(Measure::{
    chord: dummy_chord,
    notes: leading_rest_notes,
    start_time: Duration::from_milliseconds(0.0),
    duration: Duration::from_milliseconds(measure_duration_ms),
    measure_index: 0, // Leading rest is measure 0
  })

  // Calculate number of chord measures needed (total - 1 for leading rest)
  let chord_measures_needed = measure_count - 1

  // If no chords or no measures needed, return just the leading rest
  if chords.length() == 0 || chord_measures_needed <= 0 {
    return measures
  }

  // Create measures, cycling through chords as needed
  for i = 0; i < chord_measures_needed; {
    let chord = chords[i % chords.length()]
    // Offset measure start by leading rest duration
    let measure_start = leading_rest_duration +
      i.to_double() * measure_duration_ms
    let measure_end = measure_start + measure_duration_ms

    // Create measure notes with accidentals
    let measure_notes = create_measure_notes_with_accidentals(
      sounds, measure_start, measure_end, measure_duration_ms,
    )
    measures.push(Measure::{
      chord,
      notes: measure_notes,
      start_time: Duration::from_milliseconds(measure_start),
      duration: Duration::from_milliseconds(measure_duration_ms),
      measure_index: i + 1, // Offset by 1 to account for leading rest
    })
    continue i + 1
  }
  measures
}
