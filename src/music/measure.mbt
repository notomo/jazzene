///|
/// Measure representation for lead sheet visualization
/// Converts NoteValueSound arrays into measure-organized data structures

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
/// Convert sounds array to measures array
pub fn convert_sounds_to_measures(
  sounds : Array[NoteValueSound],
  chords : Array[Chord],
  bpm : Int,
) -> Array[Measure] {
  let measure_duration_ms = 60000.0 * 4.0 / bpm.to_double()
  let measures = []

  // Account for leading rest (1 measure = 4 beats)
  let leading_rest_duration = measure_duration_ms
  for i = 0; i < chords.length(); {
    let chord = chords[i]
    // Offset measure start by leading rest duration
    let measure_start = leading_rest_duration +
      i.to_double() * measure_duration_ms
    let measure_end = measure_start + measure_duration_ms

    // Filter sounds within this measure
    let measure_notes : Array[MeasureNote] = []
    for sound in sounds {
      let sound_start = sound.start_time.to_milliseconds()
      if sound_start >= measure_start && sound_start < measure_end {
        let beat_offset = (sound_start - measure_start) /
          (measure_duration_ms / 4.0)
        measure_notes.push(MeasureNote::{
          midi: sound.note_value.midi().map(fn(m) { m.value }),
          duration: sound.note_value.note_duration(),
          start_beat: beat_offset,
        })
      }
    }
    measures.push(Measure::{
      chord,
      notes: measure_notes,
      start_time: Duration::from_milliseconds(measure_start),
      duration: Duration::from_milliseconds(measure_duration_ms),
      measure_index: i,
    })
    continue i + 1
  }
  measures
}
