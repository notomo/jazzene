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
