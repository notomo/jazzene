///|
/// shell_voicing returns correct pitch classes for Cmaj7
test "shell_voicing - Cmaj7 guide tones" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  let v = shell_voicing(chord, None)
  // Cmaj7: intervals [0,4,7,11]; 3rd=E(4), 7th=B(11)
  assert_eq(v.notes.length(), 2)
  assert_eq(v.notes[0].pitch_class(), 4) // E (3rd)
  assert_eq(v.notes[1].pitch_class(), 11) // B (7th)
}

///|
/// shell_voicing returns correct pitch classes for G7
test "shell_voicing - G7 guide tones" {
  let chord = Chord::{ root: G, quality: Dominant7, bass: None }
  let v = shell_voicing(chord, None)
  // G7: intervals [0,4,7,10]; 3rd=B(11), 7th=F(5)
  assert_eq(v.notes[0].pitch_class(), 11) // B (3rd)
  assert_eq(v.notes[1].pitch_class(), 5) // F (7th)
}

///|
/// shell_voicing for a triad uses 3rd and 5th
test "shell_voicing - C major triad uses 3rd and 5th" {
  let chord = Chord::{ root: C, quality: Major, bass: None }
  let v = shell_voicing(chord, None)
  // Major triad: [0,4,7]; 3rd=E(4), 5th=G(7)
  assert_eq(v.notes.length(), 2)
  assert_eq(v.notes[0].pitch_class(), 4) // E (3rd)
  assert_eq(v.notes[1].pitch_class(), 7) // G (5th)
}

///|
/// shell_voicing with prev keeps notes close (smooth voice leading)
test "shell_voicing - smooth voice leading from G7 to Cmaj7" {
  let g7 = Chord::{ root: G, quality: Dominant7, bass: None }
  let cmaj7 = Chord::{ root: C, quality: Major7, bass: None }
  let v_g7 = shell_voicing(g7, None)
  let v_cmaj7 = shell_voicing(cmaj7, Some(v_g7))
  // G7: 3rd=B(~71), 7th=F(~65)
  // Cmaj7 with prev: 3rd=E should be close to B(71) → E4(64) or E5(76)
  //                  7th=B should be close to F(65) → B3(59) or B4(71)
  // Smooth: E4(64) is closest to B4(71), B3(59) is closest to F4(65)
  assert_eq(v_cmaj7.notes[0].pitch_class(), 4) // E (3rd)
  assert_eq(v_cmaj7.notes[1].pitch_class(), 11) // B (7th)
  // Verify voice movement is small (within a tritone)
  let dist0 = v_g7.notes[0].distance(v_cmaj7.notes[0])
  let dist1 = v_g7.notes[1].distance(v_cmaj7.notes[1])
  assert_true(dist0 <= 6)
  assert_true(dist1 <= 6)
}

///|
/// full_voicing includes all four chord tones
test "full_voicing - Cmaj7 has all 4 chord tones" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  let v = full_voicing(chord, None)
  // Cmaj7: root=C(0), 3rd=E(4), 5th=G(7), 7th=B(11)
  assert_eq(v.notes.length(), 4)
  assert_eq(v.notes[0].pitch_class(), 0) // C (root)
  assert_eq(v.notes[1].pitch_class(), 4) // E (3rd)
  assert_eq(v.notes[2].pitch_class(), 7) // G (5th)
  assert_eq(v.notes[3].pitch_class(), 11) // B (7th)
}

///|
/// full_voicing uses smooth voice leading from previous voicing
test "full_voicing - smooth voice leading Dm7 to G7" {
  let dm7 = Chord::{ root: D, quality: Minor7, bass: None }
  let g7 = Chord::{ root: G, quality: Dominant7, bass: None }
  let v_dm7 = full_voicing(dm7, None)
  let v_g7 = full_voicing(g7, Some(v_dm7))
  // Both have 4 notes
  assert_eq(v_g7.notes.length(), 4)
  // Pitch classes should be G7: root=G(7), 3rd=B(11), 5th=D(2), 7th=F(5)
  assert_eq(v_g7.notes[0].pitch_class(), 7) // G (root)
  assert_eq(v_g7.notes[1].pitch_class(), 11) // B (3rd)
  assert_eq(v_g7.notes[2].pitch_class(), 2) // D (5th)
  assert_eq(v_g7.notes[3].pitch_class(), 5) // F (7th)
}

///|
/// tension_voicing returns guide tones (3rd, 7th) plus a valid tension
test "tension_voicing - Cmaj7 has guide tones plus one tension" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  let v = tension_voicing(chord, None, 0)
  // Guide tones same as shell_voicing: 3rd=E(4), 7th=B(11)
  assert_eq(v.notes.length(), 3)
  assert_eq(v.notes[0].pitch_class(), 4) // E (3rd)
  assert_eq(v.notes[1].pitch_class(), 11) // B (7th)
  // Tension must be one of Cmaj7 tensions: 9(2)=D, #11(6)=F#, 13(9)=A
  let tension_pc = v.notes[2].pitch_class()
  assert_true([2, 6, 9].iter().any(fn(pc) { pc == tension_pc }))
}

///|
/// tension_voicing falls back to 2 notes when chord has no tensions (Diminished7)
test "tension_voicing - Diminished7 has no tensions: returns 2 notes" {
  let chord = Chord::{ root: C, quality: Diminished7, bass: None }
  let v = tension_voicing(chord, None, 0)
  // Diminished7 tensions() = [] → no 3rd note appended
  assert_eq(v.notes.length(), 2)
  // Guide tones: intervals [0,3,6,9], gi1=3(Eb), gi2=9(A)
  assert_eq(v.notes[0].pitch_class(), 3) // Eb (3rd)
  assert_eq(v.notes[1].pitch_class(), 9) // A (7th)
}

///|
/// tension_voicing uses smooth voice leading for the first two notes
test "tension_voicing - smooth voice leading G7 to Cmaj7" {
  let g7 = Chord::{ root: G, quality: Dominant7, bass: None }
  let cmaj7 = Chord::{ root: C, quality: Major7, bass: None }
  let v_g7 = tension_voicing(g7, None, 0)
  let v_cmaj7 = tension_voicing(cmaj7, Some(v_g7), 0)
  // Pitch classes of guide tones are correct
  assert_eq(v_cmaj7.notes[0].pitch_class(), 4) // E (3rd)
  assert_eq(v_cmaj7.notes[1].pitch_class(), 11) // B (7th)
  // Guide tone movement stays within a tritone
  let dist0 = v_g7.notes[0].distance(v_cmaj7.notes[0])
  let dist1 = v_g7.notes[1].distance(v_cmaj7.notes[1])
  assert_true(dist0 <= 6)
  assert_true(dist1 <= 6)
}

///|
/// tension_voicing notes stay in comfortable range (C3-E5)
test "tension_voicing - notes stay in voicing range" {
  let chords = [
    Chord::{ root: C, quality: Major7, bass: None },
    Chord::{ root: F, quality: Dominant7, bass: None },
    Chord::{ root: ASharp, quality: Minor7, bass: None },
    Chord::{ root: DSharp, quality: HalfDiminished, bass: None },
  ]
  let mut prev : Voicing? = None
  for chord in chords {
    let v = tension_voicing(chord, prev, 42)
    prev = Some(v)
    for note in v.notes {
      assert_true(note.value >= 48) // >= C3
      assert_true(note.value <= 76) // <= E5
    }
  }
}

///|
/// tension_voicing with different seeds selects different tensions
test "tension_voicing - different seeds produce different tensions for Dominant7" {
  // Dominant7 has 6 tensions [1,2,3,6,8,9] — enough variety for seed variation
  let chord = Chord::{ root: C, quality: Dominant7, bass: None }
  let tensions_seen : Array[Int] = []
  for seed in [0, 1, 7, 99, 1000] {
    let v = tension_voicing(chord, None, seed)
    assert_eq(v.notes.length(), 3)
    let pc = v.notes[2].pitch_class()
    assert_true([1, 2, 3, 6, 8, 9].iter().any(fn(t) { t == pc }))
    if not(tensions_seen.iter().any(fn(t) { t == pc })) {
      tensions_seen.push(pc)
    }
  }
  // At least 2 distinct tensions selected across 5 seeds
  assert_true(tensions_seen.length() >= 2)
}

///|
/// All voicing notes stay in comfortable range
test "shell_voicing - notes stay in voicing range" {
  let chords = [
    Chord::{ root: C, quality: Major7, bass: None },
    Chord::{ root: F, quality: Major7, bass: None },
    Chord::{ root: ASharp, quality: Dominant7, bass: None },
    Chord::{ root: DSharp, quality: Major7, bass: None },
  ]
  let mut prev : Voicing? = None
  for chord in chords {
    let v = shell_voicing(chord, prev)
    prev = Some(v)
    for note in v.notes {
      assert_true(note.value >= 48) // >= C3
      assert_true(note.value <= 76) // <= E5
    }
  }
}
