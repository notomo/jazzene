///|
/// Chord with type-safe root and quality, optional bass for slash chords
pub(all) struct Chord {
  root : ChordRoot
  quality : ChordQuality
  bass : ChordRoot?
} derive(Eq, Debug)

///|
pub impl Show for Chord with output(self, logger) {
  self.to_repr().output(logger)
}

///|
/// Get MIDI numbers for chord tones
pub fn Chord::tones(self : Chord) -> Array[MidiNumber] {
  let root_midi = self.root.midi()
  let intervals = self.quality.intervals()
  intervals.filter_map(fn(interval) { MidiNumber::new(root_midi + interval) })
}

///|
/// Transpose a chord's root by a semitone offset
pub fn Chord::transpose(self : Chord, offset : Int) -> Chord {
  let new_pc = (self.root.midi() - 60 + offset + 120) % 12
  let new_root = ChordRoot::from_pitch_class(new_pc)
  let new_bass = self.bass.map(fn(b) {
    let bp = (b.midi() - 60 + offset + 120) % 12
    ChordRoot::from_pitch_class(bp)
  })
  Chord::{ root: new_root, quality: self.quality, bass: new_bass }
}

///|
/// Format complete chord symbol
pub fn format_chord(chord : Chord) -> String {
  let base = chord.root.to_string() + chord.quality.to_string()
  match chord.bass {
    None => base
    Some(bass) => base + "/" + bass.to_string()
  }
}

///|
/// Get tension tones (9th, 11th, 13th) as MIDI numbers in octave 4
pub fn Chord::tension_tones(self : Chord) -> Array[MidiNumber] {
  let root_midi = self.root.midi()
  let tensions = self.quality.tensions()
  tensions.filter_map(fn(interval) { MidiNumber::new(root_midi + interval) })
}

///|
/// Get chromatic approach tones (half-step above and below each chord tone)
/// Returns MIDI numbers that are NOT already chord tones
pub fn Chord::approach_tones(self : Chord) -> Array[MidiNumber] {
  let chord_pitch_classes : Array[Int] = self
    .tones()
    .map(fn(tone) { tone.pitch_class() })
  self
  .tones()
  .iter()
  .flat_map(fn(tone) {
    // Half-step below and above each chord tone
    [tone.value - 1, tone.value + 1]
    .iter()
    .filter_map(fn(v) {
      match MidiNumber::new(v) {
        None => None
        Some(midi) =>
          // Exclude if it's already a chord tone
          if chord_pitch_classes.contains(midi.pitch_class()) {
            None
          } else {
            Some(midi)
          }
      }
    })
  })
  .collect()
}

///|
/// Get enclosure tones: notes 2 semitones away from each chord tone.
/// These form the "outer" note of an enclosure approach pattern,
/// creating a strong directional pull toward the target chord tone.
/// Returns MIDI numbers that are NOT already chord tones or approach tones.
pub fn Chord::enclosure_tones(self : Chord) -> Array[MidiNumber] {
  let chord_pitch_classes : Array[Int] = self
    .tones()
    .map(fn(tone) { tone.pitch_class() })
  let approach_pitch_classes : Array[Int] = self
    .approach_tones()
    .map(fn(tone) { tone.pitch_class() })
  self
  .tones()
  .iter()
  .flat_map(fn(tone) {
    // Two semitones below and above each chord tone
    [tone.value - 2, tone.value + 2]
    .iter()
    .filter_map(fn(v) {
      match MidiNumber::new(v) {
        None => None
        Some(midi) => {
          let pc = midi.pitch_class()
          // Exclude chord tones and approach tones (avoid duplicates)
          if chord_pitch_classes.contains(pc) ||
            approach_pitch_classes.contains(pc) {
            None
          } else {
            Some(midi)
          }
        }
      }
    })
  })
  .collect()
}

///|
/// Get scale tones for this chord using chord-scale theory.
/// Uses the appropriate scale for the chord quality (e.g., Dorian for m7, Mixolydian for 7).
/// Returns diatonic tones that are neither chord tones nor tension tones (9th/11th/13th).
pub fn Chord::scale_tones(self : Chord) -> Array[MidiNumber] {
  let chord_scale = self.quality.chord_scale()
  let scale_intervals = chord_scale.intervals()
  let root_midi = self.root.midi()
  let chord_pitch_classes : Array[Int] = self
    .tones()
    .map(fn(tone) { tone.pitch_class() })
  let tension_pitch_classes : Array[Int] = self.quality
    .tensions()
    .map(fn(interval) { (root_midi + interval) % 12 })
  scale_intervals
  .iter()
  .filter_map(fn(interval) {
    let midi_value = root_midi + interval
    let pitch_class = midi_value % 12
    guard !chord_pitch_classes.contains(pitch_class) else { return None }
    guard !tension_pitch_classes.contains(pitch_class) else { return None }
    MidiNumber::new(midi_value)
  })
  .collect()
}

///|
/// Get bebop passing tones: the extra notes added by bebop scales.
/// For Dominant7: the major 7th (half-step between b7 and root when descending)
/// For Major7: the #5 (half-step between 5th and 6th)
/// These are distinct from chord tones and regular scale tones.
pub fn Chord::bebop_passing_tones(self : Chord) -> Array[MidiNumber] {
  let root_midi = self.root.midi()
  let passing_intervals = match self.quality {
    Dominant7 => [11] // Major 7th passing tone (between b7=10 and octave root)
    Major7 => [8] // #5 passing tone (between 5th=7 and 6th=9)
    Minor7 => [4] // Major 3rd passing tone / Bebop Dorian (between b3=3 and 4=5)
    HalfDiminished => [7] // Natural 5th passing tone / Bebop Locrian (between b5=6 and b6=8)
    _ => []
  }
  passing_intervals.filter_map(fn(interval) {
    MidiNumber::new(root_midi + interval)
  })
}
