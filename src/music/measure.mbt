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
/// Convert MIDI number to Y position on staff
/// E4 (MIDI 64) is the bottom line of treble clef
pub fn midi_to_staff_y(midi : Int, staff_y : Double) -> Double {
  let e4_midi = 64
  let steps_from_e4 = midi - e4_midi
  // Each semitone = 3.75 units (half of line spacing)
  let offset = steps_from_e4.to_double() * -3.75
  staff_y + 15.0 * 4.0 + offset // staff_line_spacing = 15.0
}

///|
/// Convert chord root to display string
pub fn chord_root_to_string(root : ChordRoot) -> String {
  match root {
    C => "C"
    CSharp => "C♯"
    D => "D"
    DSharp => "E♭" // Prefer flats
    E => "E"
    F => "F"
    FSharp => "F♯"
    G => "G"
    GSharp => "A♭"
    A => "A"
    ASharp => "B♭"
    B => "B"
  }
}

///|
/// Convert chord quality to display string
pub fn chord_quality_to_string(quality : ChordQuality) -> String {
  match quality {
    Major7 => "maj7"
    Minor7 => "m7"
    Dominant7 => "7"
    HalfDiminished => "m7♭5"
    Diminished7 => "°7"
    Augmented => "aug"
    Sus4 => "sus4"
    Major => ""
    Minor => "m"
  }
}

///|
/// Format complete chord symbol
pub fn format_chord(chord : Chord) -> String {
  chord_root_to_string(chord.root) + chord_quality_to_string(chord.quality)
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
