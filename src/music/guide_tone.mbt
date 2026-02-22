///|
/// Guide tone line: smooth 3rd/7th voice leading through a chord progression.
///
/// In jazz harmony, guide tones are the 3rd and 7th of each chord.
/// They define the harmonic quality and tend to move by half-step or whole-step
/// between chords (e.g., the 7th of G7 resolves down a half-step to the 3rd of Cmaj7).
/// This function pre-calculates that smooth voice-leading path.

///|
/// A pair of guide tones (3rd and 7th) for one chord in the progression.
pub(all) struct GuideTonePair {
  third : MidiNumber // The 3rd of the chord (defines major/minor quality)
  seventh : MidiNumber // The 7th (or 5th for triads)
} derive(Eq, Show)

///|
/// Get the guide tone intervals (3rd and 7th) for a chord quality.
/// For triads, returns 3rd and 5th instead of 3rd and 7th.
fn guide_tone_intervals(quality : ChordQuality) -> (Int, Int) {
  let intervals = quality.intervals()
  let third = intervals[1]
  let seventh = if intervals.length() >= 4 {
    intervals[3]
  } else {
    intervals[2]
  }
  (third, seventh)
}

///|
/// Generate all octave candidates for a pitch class around a target MIDI value.
/// Returns MIDI numbers within a comfortable range (36-84, C2-C6).
fn octave_candidates(root_midi : Int, interval : Int) -> Array[MidiNumber] {
  let base = root_midi + interval
  [-2, -1, 0, 1, 2]
  .iter()
  .filter_map(fn(offset) { MidiNumber::new(base + offset * 12) })
  .filter(fn(m) { m.value >= 36 && m.value <= 84 })
  .collect()
}

///|
/// Find the candidate closest to a reference MIDI value.
/// If candidates is empty, falls back to the reference itself.
fn closest_to(
  candidates : Array[MidiNumber],
  reference : MidiNumber,
) -> MidiNumber {
  guard not(candidates.is_empty()) else { return reference }
  candidates
  .iter()
  .fold(init=candidates[0], fn(best, candidate) {
    if candidate.distance(reference) < best.distance(reference) {
      candidate
    } else {
      best
    }
  })
}

///|
/// Calculate the guide tone line for a sequence of chords.
/// Returns one GuideTonePair per chord, with smooth voice leading
/// (each guide tone moves to the nearest available tone in the next chord).
///
/// The initial register targets the middle octave (MIDI 48-72 range).
pub fn guide_tone_line(chords : Array[Chord]) -> Array[GuideTonePair] {
  guard not(chords.is_empty()) else { return [] }

  // Seed: start with first chord's guide tones in a comfortable octave.
  // Targeting root + interval in octave 4 (C4=60), but clamped to 36-84.
  let first_chord = chords[0]
  let (first_third_interval, first_seventh_interval) = guide_tone_intervals(
    first_chord.quality,
  )
  let first_root = first_chord.root.midi()
  // Place initial guide tones in octave that puts them near middle C (60)
  // Root-octave 4 is midi 60+; subtract 12 to get root below middle C if needed
  let first_third = closest_to(
    octave_candidates(first_root, first_third_interval),
    MidiNumber::{ value: 60 },
  )
  let first_seventh = closest_to(
    octave_candidates(first_root, first_seventh_interval),
    MidiNumber::{ value: 60 },
  )

  let result : Array[GuideTonePair] = [
    GuideTonePair::{ third: first_third, seventh: first_seventh },
  ]

  // For each subsequent chord, find the guide tones nearest to the previous pair.
  for i = 1; i < chords.length(); i = i + 1 {
    let chord = chords[i]
    let prev = result[i - 1]
    let (third_interval, seventh_interval) = guide_tone_intervals(chord.quality)
    let root = chord.root.midi()
    let new_third = closest_to(
      octave_candidates(root, third_interval),
      prev.third,
    )
    let new_seventh = closest_to(
      octave_candidates(root, seventh_interval),
      prev.seventh,
    )
    result.push(GuideTonePair::{ third: new_third, seventh: new_seventh })
  }
  result
}
