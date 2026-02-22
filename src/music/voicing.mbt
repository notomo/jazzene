///|
/// Jazz chord voicing with smooth voice leading.
///
/// A voicing is a concrete arrangement of chord tones as MIDI pitch values.
/// Shell voicing uses only guide tones (3rd and 7th), while full voicing
/// includes all chord tones. Both use smooth voice leading to minimize
/// melodic distance from the previous voicing.

///|
/// A specific chord voicing with concrete MIDI note placements.
///
/// Notes are stored in voice-assignment order (not necessarily ascending):
/// - shell_voicing: notes[0] = 3rd, notes[1] = 7th (or 5th for triads)
/// - full_voicing:  notes follow chord interval order (root, 3rd, 5th, 7th)
///
/// This consistent ordering allows smooth voice leading across chord changes.
pub(all) struct Voicing {
  notes : Array[MidiNumber]
}

///|
/// Comfortable MIDI range for comping voicings (C3 to E5)
let voicing_min : Int = 48 // C3

///|
let voicing_max : Int = 76 // E5

///|
let voicing_default_ref : Int = 60 // C4 as default reference when no prev

///|
/// Find the MIDI number with the given pitch class (0-11) closest to a
/// reference MIDI value, clamped to the comfortable voicing range.
fn closest_voicing_midi(pitch_class : Int, reference : Int) -> Int {
  // Find base: pitch class placed in the same octave region as reference
  let base = reference / 12 * 12 + pitch_class
  // Compare base-12, base, base+12 and pick the one closest to reference
  let candidates = [base - 12, base, base + 12]
  let best = candidates.fold(init=base, fn(best, c) {
    if (c - reference).abs() < (best - reference).abs() {
      c
    } else {
      best
    }
  })
  // Clamp to comfortable voicing range by octave transposition
  let mut m = best
  while m < voicing_min {
    m = m + 12
  }
  while m > voicing_max {
    m = m - 12
  }
  m
}

///|
/// Shell voicing: guide tones only (3rd and 7th, or 3rd and 5th for triads).
///
/// Uses smooth voice leading by minimizing distance from the previous voicing.
/// notes[0] = 3rd, notes[1] = 7th/5th — consistent across chords for
/// reliable voice tracking through a chord progression.
pub fn shell_voicing(chord : Chord, prev : Voicing?) -> Voicing {
  let intervals = chord.quality.intervals()
  let root_midi = chord.root.midi()
  // Guide tones: 3rd (idx 1) and 7th (idx 3) for 7th chords,
  // 3rd (idx 1) and 5th (idx 2) for triads
  let (gi1, gi2) = if intervals.length() >= 4 {
    (intervals[1], intervals[3])
  } else if intervals.length() >= 3 {
    (intervals[1], intervals[2])
  } else {
    // Edge case: 2-note chord
    (intervals[0], intervals[1])
  }
  let pc1 = (root_midi + gi1) % 12
  let pc2 = (root_midi + gi2) % 12
  let (ref1, ref2) = match prev {
    Some(v) if v.notes.length() >= 2 => (v.notes[0].value, v.notes[1].value)
    _ => (voicing_default_ref, voicing_default_ref)
  }
  let notes = [closest_voicing_midi(pc1, ref1), closest_voicing_midi(pc2, ref2)].filter_map(fn(
      v,
    ) {
      MidiNumber::new(v)
    },
  )
  Voicing::{ notes, }
}

///|
/// Full voicing: all chord tones in interval order (root, 3rd, 5th, 7th...).
///
/// Uses smooth voice leading by minimizing distance from the previous voicing.
/// notes[i] corresponds to intervals[i] — consistent ordering across chords.
pub fn full_voicing(chord : Chord, prev : Voicing?) -> Voicing {
  let intervals = chord.quality.intervals()
  let root_midi = chord.root.midi()
  let refs : Array[Int] = match prev {
    Some(v) =>
      if v.notes.length() == intervals.length() {
        v.notes.map(fn(n) { n.value })
      } else {
        Array::makei(intervals.length(), fn(_) { voicing_default_ref })
      }
    None => Array::makei(intervals.length(), fn(_) { voicing_default_ref })
  }
  let notes = intervals
    .mapi(fn(i, interval) {
      let pc = (root_midi + interval) % 12
      let ref_val = refs[i]
      closest_voicing_midi(pc, ref_val)
    })
    .filter_map(fn(v) { MidiNumber::new(v) })
  Voicing::{ notes, }
}
