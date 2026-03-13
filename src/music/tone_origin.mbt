///|
/// Records which jazz improvisation technique produced a note.
/// Used for educational highlighting and visualization.
pub(all) enum ToneOrigin {
  ChordTone // Chord tone (1st, 3rd, 5th, 7th)
  Tension(Int) // Tension tone (9th, 11th, 13th etc.); Int is the jazz degree
  NeighborTone // Note ±1-2 semitones from a chord tone, used in CT→N→CT ornament
  ChromaticApproach // Chromatic approach tone (half-step above/below chord tone), used in AT→CT ornament
  Enclosure // Enclosure pattern (surrounding a chord tone from above and below)
  PassingTone // Passing tone (connecting scale tone)
  Imported // Note imported from a MIDI file
} derive(Eq, Show)
