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
/// - shell_voicing:   notes[0] = 3rd, notes[1] = 7th (or 5th for triads)
/// - full_voicing:    notes follow chord interval order (root, 3rd, 5th, 7th)
/// - tension_voicing: A form = [3rd, 5th, 7th, R/9th], B form = [7th, R/9th, 3rd, 5th/13th]
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

///|
/// A form (true) when chord root is C or D; B form (false) for all other roots.
/// A form places the 3rd in the lowest voice; B form places the 7th lowest.
fn is_a_form(root : ChordRoot) -> Bool {
  match root {
    C | D => true
    _ => false
  }
}

///|
/// Tension usage based on chord degree in key: (use_ninth, use_thirteenth).
/// Key-aware rules (diatonic major key):
///   IIIm7 (4 semitones) and VIIm7♭5 (11 semitones) — no tensions
///   V7 (7 semitones) — 9th and 13th
///   All others — 9th only
fn tension_degrees(chord : Chord, key : KeySignature) -> (Bool, Bool) {
  let key_root_pc = key.root.midi() % 12
  let chord_root_pc = chord.root.midi() % 12
  let semitones = (chord_root_pc - key_root_pc + 12) % 12
  match (semitones, chord.quality) {
    (4, Minor7) | (11, HalfDiminished) => (false, false)
    (7, Dominant7) => (true, true)
    _ => (true, false)
  }
}

///|
/// Tension voicing: 4-voice voicing using A form or B form with appropriate tensions.
///
/// A form vs B form is selected by chord root (C, D → A form; others → B form):
///   A form no tensions:  [3, 5, 7, 1]
///   A form with 9th:     [3, 5, 7, 9]
///   A form with 9th+13th:[3, 13, 7, 9]
///   B form no tensions:  [7, 1, 3, 5]
///   B form with 9th:     [7, 9, 3, 5]
///   B form with 9th+13th:[7, 9, 3, 13]
///
/// Falls back to shell_voicing for triads (fewer than 4 chord tones).
/// Uses smooth voice leading by minimizing distance from the previous voicing.
pub fn tension_voicing(
  chord : Chord,
  prev : Voicing?,
  key : KeySignature,
) -> Voicing {
  let intervals = chord.quality.intervals()
  if intervals.length() < 4 {
    return shell_voicing(chord, prev)
  }
  let root_midi = chord.root.midi()
  let pc3 = (root_midi + intervals[1]) % 12
  let pc5 = (root_midi + intervals[2]) % 12
  let pc7 = (root_midi + intervals[3]) % 12
  let pc1 = root_midi % 12
  let pc9 = (root_midi + 2) % 12
  let pc13 = (root_midi + 9) % 12
  let (use_ninth, use_thirteenth) = tension_degrees(chord, key)
  let a_form = is_a_form(chord.root)
  let voice_pcs = if a_form {
    match (use_ninth, use_thirteenth) {
      (false, _) => [pc3, pc5, pc7, pc1]
      (true, false) => [pc3, pc5, pc7, pc9]
      (true, true) => [pc3, pc13, pc7, pc9]
    }
  } else {
    match (use_ninth, use_thirteenth) {
      (false, _) => [pc7, pc1, pc3, pc5]
      (true, false) => [pc7, pc9, pc3, pc5]
      (true, true) => [pc7, pc9, pc3, pc13]
    }
  }
  let refs : Array[Int] = match prev {
    Some(v) if v.notes.length() >= 4 =>
      [v.notes[0].value, v.notes[1].value, v.notes[2].value, v.notes[3].value]
    Some(v) if v.notes.length() >= 2 =>
      [v.notes[0].value, v.notes[0].value, v.notes[1].value, v.notes[1].value]
    _ =>
      [
        voicing_default_ref, voicing_default_ref, voicing_default_ref, voicing_default_ref,
      ]
  }
  let notes = voice_pcs
    .mapi(fn(i, pc) { closest_voicing_midi(pc, refs[i]) })
    .filter_map(fn(v) { MidiNumber::new(v) })
  Voicing::{ notes, }
}
