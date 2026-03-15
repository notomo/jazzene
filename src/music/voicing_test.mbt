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
/// tension_voicing: Cmaj7 with no key → A form (root C) with 9th: [3, 5, 7, 9]
test "tension_voicing - Cmaj7 A form with 9th" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  let v = tension_voicing(chord, None, KeySignature::from_root(C))
  // C root → A form; Major7, no key → use_ninth=true, use_thirteenth=false
  // A form 3579: [E(4), G(7), B(11), D(2)]
  assert_eq(v.notes.length(), 4)
  assert_eq(v.notes[0].pitch_class(), 4) // E (3rd)
  assert_eq(v.notes[1].pitch_class(), 7) // G (5th)
  assert_eq(v.notes[2].pitch_class(), 11) // B (7th)
  assert_eq(v.notes[3].pitch_class(), 2) // D (9th)
}

///|
/// tension_voicing: G7 with no key → B form with 9th+13th: [7, 9, 3, 13]
test "tension_voicing - G7 B form with 9th and 13th" {
  let chord = Chord::{ root: G, quality: Dominant7, bass: None }
  let v = tension_voicing(chord, None, KeySignature::from_root(C))
  // G root → B form; Dominant7, no key → use_ninth=true, use_thirteenth=true
  // B form 7 9 3 13: [F(5), A(9), B(11), E(4)]
  assert_eq(v.notes.length(), 4)
  assert_eq(v.notes[0].pitch_class(), 5) // F (7th)
  assert_eq(v.notes[1].pitch_class(), 9) // A (9th)
  assert_eq(v.notes[2].pitch_class(), 11) // B (3rd)
  assert_eq(v.notes[3].pitch_class(), 4) // E (13th)
}

///|
/// tension_voicing: Diminished7 with no key → A form, no tensions: [3, 5, 7, 1]
test "tension_voicing - Diminished7 in key C uses 9th" {
  let chord = Chord::{ root: C, quality: Diminished7, bass: None }
  let v = tension_voicing(chord, None, KeySignature::from_root(C))
  // C root → A form; semitones=0 in key C → (true, false) → 9th only
  // A form 3579: [Eb(3), Gb(6), A(9), D(2)]
  assert_eq(v.notes.length(), 4)
  assert_eq(v.notes[0].pitch_class(), 3) // Eb (3rd)
  assert_eq(v.notes[1].pitch_class(), 6) // Gb (5th)
  assert_eq(v.notes[2].pitch_class(), 9) // A (7th)
  assert_eq(v.notes[3].pitch_class(), 2) // D (9th)
}

///|
/// tension_voicing: Em7 in key C (IIIm7) → B form, no tensions: [7, 1, 3, 5]
test "tension_voicing - Em7 in key C is IIIm7: no tensions" {
  let chord = Chord::{ root: E, quality: Minor7, bass: None }
  let key = KeySignature::from_root(C)
  let v = tension_voicing(chord, None, key)
  // E root → B form; IIIm7 in key C (4 semitones) → (false, false)
  // B form 7135: [D(2), E(4), G(7), B(11)]
  assert_eq(v.notes.length(), 4)
  assert_eq(v.notes[0].pitch_class(), 2) // D (7th of Em7)
  assert_eq(v.notes[1].pitch_class(), 4) // E (root)
  assert_eq(v.notes[2].pitch_class(), 7) // G (3rd)
  assert_eq(v.notes[3].pitch_class(), 11) // B (5th)
}

///|
/// tension_voicing: Bm7b5 in key C (VIIm7♭5) → B form, no tensions
test "tension_voicing - Bm7b5 in key C is VIIm7b5: no tensions" {
  let chord = Chord::{ root: B, quality: HalfDiminished, bass: None }
  let key = KeySignature::from_root(C)
  let v = tension_voicing(chord, None, key)
  // B root → B form; VIIm7♭5 in key C (11 semitones) → (false, false)
  // HalfDiminished intervals [0,3,6,10]; B form 7135: [A(9), B(11), D(2), F(5)]
  assert_eq(v.notes.length(), 4)
  assert_eq(v.notes[0].pitch_class(), 9) // A (7th of Bm7b5)
  assert_eq(v.notes[1].pitch_class(), 11) // B (root)
  assert_eq(v.notes[2].pitch_class(), 2) // D (3rd)
  assert_eq(v.notes[3].pitch_class(), 5) // F (5th)
}

///|
/// tension_voicing: G7 in key C (V7) → B form, 9th and 13th
test "tension_voicing - G7 in key C is V7: 9th and 13th" {
  let chord = Chord::{ root: G, quality: Dominant7, bass: None }
  let key = KeySignature::from_root(C)
  let v = tension_voicing(chord, None, key)
  // G root → B form; V7 in key C (7 semitones) → (true, true)
  // B form 7 9 3 13: [F(5), A(9), B(11), E(4)]
  assert_eq(v.notes.length(), 4)
  assert_eq(v.notes[0].pitch_class(), 5) // F (7th)
  assert_eq(v.notes[1].pitch_class(), 9) // A (9th)
  assert_eq(v.notes[2].pitch_class(), 11) // B (3rd)
  assert_eq(v.notes[3].pitch_class(), 4) // E (13th)
}

///|
/// tension_voicing: Dm7 in key C (IIm7) → A form, 9th only
test "tension_voicing - Dm7 in key C is IIm7: 9th only" {
  let chord = Chord::{ root: D, quality: Minor7, bass: None }
  let key = KeySignature::from_root(C)
  let v = tension_voicing(chord, None, key)
  // D root → A form; IIm7 in key C (2 semitones) → (true, false)
  // Minor7 intervals [0,3,7,10]; A form 3579: [F(5), A(9), C(0), E(4)]
  assert_eq(v.notes.length(), 4)
  assert_eq(v.notes[0].pitch_class(), 5) // F (3rd)
  assert_eq(v.notes[1].pitch_class(), 9) // A (5th)
  assert_eq(v.notes[2].pitch_class(), 0) // C (7th)
  assert_eq(v.notes[3].pitch_class(), 4) // E (9th)
}

///|
/// tension_voicing uses smooth voice leading across chord changes
test "tension_voicing - smooth voice leading G7 to Cmaj7" {
  let g7 = Chord::{ root: G, quality: Dominant7, bass: None }
  let cmaj7 = Chord::{ root: C, quality: Major7, bass: None }
  let v_g7 = tension_voicing(g7, None, KeySignature::from_root(C))
  let v_cmaj7 = tension_voicing(cmaj7, Some(v_g7), KeySignature::from_root(C))
  // G7 B form [F,A,B,E]; Cmaj7 A form [E,G,B,D]
  assert_eq(v_cmaj7.notes.length(), 4)
  assert_eq(v_cmaj7.notes[0].pitch_class(), 4) // E (3rd)
  assert_eq(v_cmaj7.notes[1].pitch_class(), 7) // G (5th)
  assert_eq(v_cmaj7.notes[2].pitch_class(), 11) // B (7th)
  assert_eq(v_cmaj7.notes[3].pitch_class(), 2) // D (9th)
  // Verify voice movement stays within a tritone
  for i in 0..<4 {
    let dist = v_g7.notes[i].distance(v_cmaj7.notes[i])
    assert_true(dist <= 6)
  }
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
  let key = KeySignature::from_root(C)
  let mut prev : Voicing? = None
  for chord in chords {
    let v = tension_voicing(chord, prev, key)
    prev = Some(v)
    for note in v.notes {
      assert_true(note.value >= 48) // >= C3
      assert_true(note.value <= 76) // <= E5
    }
  }
}

///|
/// tension_voicing falls back to shell_voicing for triads
test "tension_voicing - triad falls back to shell voicing" {
  let chord = Chord::{ root: C, quality: Major, bass: None }
  let v = tension_voicing(chord, None, KeySignature::from_root(C))
  // Major triad has only 3 intervals → shell_voicing fallback: 3rd and 5th
  assert_eq(v.notes.length(), 2)
  assert_eq(v.notes[0].pitch_class(), 4) // E (3rd)
  assert_eq(v.notes[1].pitch_class(), 7) // G (5th)
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
