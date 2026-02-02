///|
/// Measure representation for lead sheet visualization

///|
/// Tie state for notes that span measure or beat boundaries
pub(all) enum Tie {
  TieStart // Ties to next note
  TieEnd // Tied from previous note
  TieBoth // Spans 3+ segments (both in and out)
} derive(Eq, Show)

///|
/// A single beat within a measure
pub(all) struct Beat {
  count : Int // 0-indexed beat number (0,1,2,3 for 4/4)
  notes : Array[MeasureNote]
}

///|
/// Represents one measure with its chords and beats
pub(all) struct Measure {
  chords : Array[Chord]
  beats : Array[Beat]
  start_time : Duration
}

///|
/// A note positioned within a beat
pub(all) struct MeasureNote {
  midi : Int? // None for rests
  duration : NoteDuration
  accidental : Accidental? // Sharp, Flat, or Natural symbol to display
  tie : Tie? // Tie connection state
}

///|
/// Flatten beats into (absolute_start_beat, note) pairs.
/// Computes position from beat.count + cumulative durations within the beat.
pub fn Measure::positioned_notes(
  self : Measure,
) -> Array[(Double, MeasureNote)] {
  self.beats
  .iter()
  .flat_map(fn(beat) {
    let mut offset = 0.0
    beat.notes
    .iter()
    .map(fn(note) {
      let pos = beat.count.to_double() + offset
      offset = offset + note.duration.to_beats()
      (pos, note)
    })
  })
  .collect()
}

///|
/// Flat list of all notes without positions.
pub fn Measure::all_notes(self : Measure) -> Array[MeasureNote] {
  self.beats.iter().flat_map(fn(beat) { beat.notes.iter() }).collect()
}
