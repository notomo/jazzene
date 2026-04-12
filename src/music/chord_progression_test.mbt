///|
test "Chord transpose" {
  let cmaj7 = Chord::{ root: C, quality: Major7, bass: None }
  // Up 2 semitones: Cmaj7 -> Dmaj7
  let dmaj7 = cmaj7.transpose(2)
  assert_eq(dmaj7.root, D)
  assert_eq(dmaj7.quality, Major7)
  assert_eq(dmaj7.bass, None)
  // With slash bass: G7/D up 5 semitones -> C7/G
  let g7_d = Chord::{ root: G, quality: Dominant7, bass: Some(D) }
  let c7_g = g7_d.transpose(5)
  assert_eq(c7_g.root, C)
  assert_eq(c7_g.quality, Dominant7)
  assert_eq(c7_g.bass, Some(G))
}

///|
test "Chord tones" {
  let cmaj7 = Chord::{ root: C, quality: Major7, bass: None }
  // C E G B
  inspect(
    cmaj7.tones(),
    content="[{ value: 60 }, { value: 64 }, { value: 67 }, { value: 71 }]",
  )
}

///|
test "Chord tension tones - Major7" {
  let cmaj7 = Chord::{ root: C, quality: Major7, bass: None }
  // 9th(D=62), #11th(F#=66), 13th(A=69)
  inspect(
    cmaj7.tension_tones(),
    content="[{ value: 62 }, { value: 66 }, { value: 69 }]",
  )
}

///|
test "Chord tension tones - Minor7" {
  let dm7 = Chord::{ root: D, quality: Minor7, bass: None }
  // 9th(E=64), 11th(G=67), 13th(B=71)
  inspect(
    dm7.tension_tones(),
    content="[{ value: 64 }, { value: 67 }, { value: 71 }]",
  )
}

///|
test "Chord tension tones - Dominant7" {
  let g7 = Chord::{ root: G, quality: Dominant7, bass: None }
  // b9(Ab=68), 9(A=69), #9(Bb=70), #11(C#=73), b13(Eb=75), 13(E=76)
  inspect(
    g7.tension_tones(),
    content="[{ value: 68 }, { value: 69 }, { value: 70 }, { value: 73 }, { value: 75 }, { value: 76 }]",
  )
}

///|
test "Chord tension tones - Diminished7 has none" {
  let bdim7 = Chord::{ root: B, quality: Diminished7, bass: None }
  inspect(bdim7.tension_tones(), content="[]")
}

///|
test "Chord tension tones - HalfDiminished" {
  let bm7b5 = Chord::{ root: B, quality: HalfDiminished, bass: None }
  // 9th(C#=73), 11th(E=76), b13th(G=79)
  inspect(
    bm7b5.tension_tones(),
    content="[{ value: 73 }, { value: 76 }, { value: 79 }]",
  )
}

///|
test "format slash chord" {
  let chord = Chord::{ root: G, quality: Dominant7, bass: Some(D) }
  assert_eq(format_chord(chord), "G7/D")
}

///|
test "format chord without bass" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  assert_eq(format_chord(chord), "C△")
}

///|
/// Bebop passing tones: major 7th for Dominant7 (between b7 and root)
test "Chord::bebop_passing_tones - Dominant7 returns major 7th passing tone" {
  let chord = Chord::{ root: C, quality: Dominant7, bass: None }
  let tones = chord.bebop_passing_tones()
  // C7: root=C(60), major7=B(71) = interval 11
  let pitch_classes = tones.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[11]") // B (major 7th)
}

///|
/// Bebop passing tones: #5 for Major7 (between 5th and 6th)
test "Chord::bebop_passing_tones - Major7 returns sharp-5 passing tone" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  let tones = chord.bebop_passing_tones()
  // Cmaj7: root=C(60), #5=G#(68) = interval 8
  let pitch_classes = tones.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[8]") // G# (#5)
}

///|
/// Minor7 bebop passing tone: major 3rd (Bebop Dorian, between b3 and 4)
test "Chord::bebop_passing_tones - Minor7 returns major 3rd passing tone" {
  let chord = Chord::{ root: D, quality: Minor7, bass: None }
  let tones = chord.bebop_passing_tones()
  // Dm7: root=D, major 3rd = F# = interval 4
  let pitch_classes = tones.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[6]") // F# (major 3rd from D)
}

///|
/// HalfDiminished bebop passing tone: natural 5th (Bebop Locrian, between b5 and b6)
test "Chord::bebop_passing_tones - HalfDiminished returns natural 5th passing tone" {
  let chord = Chord::{ root: B, quality: HalfDiminished, bass: None }
  let tones = chord.bebop_passing_tones()
  // Bm7b5: root=B, natural 5th = F# = interval 7
  let pitch_classes = tones.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[6]") // F# (natural 5th from B)
}

///|
/// Passing tones are not chord tones
test "Chord::bebop_passing_tones - not a chord tone for Dominant7" {
  let chord = Chord::{ root: C, quality: Dominant7, bass: None }
  let chord_pcs = chord.tones().map(fn(m) { m.pitch_class() })
  let passing = chord.bebop_passing_tones()
  for tone in passing {
    assert_false(chord_pcs.contains(tone.pitch_class()))
  }
}

///|
/// Enclosure tones are 2 semitones from chord tones,
/// distinct from both chord tones and approach tones (1 semitone).
test "Chord::enclosure_tones - Cmaj7: 2 semitones from each chord tone" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  let enclosure = chord.enclosure_tones()
  // Cmaj7 chord tones: C(0), E(4), G(7), B(11)
  // 2-semitone neighbors: Bb(10), D(2)  from C; Db(1), F#(6) from E;
  //                       F(5)=chord-tone? no. Let's check manually:
  // C+2=D(2), C-2=Bb(10); E+2=F#(6), E-2=Db(1); G+2=A(9), G-2=F(5); B+2=Db(13)=Db(1), B-2=Ab(9)
  // Wait: approach_tones for Cmaj7 are: Db(1), Eb(3), F(5), F#(6), Ab(8), Bb(10)
  // So: D(2) is new (not approach, not chord) → enclosure
  //     F#(6) is approach → excluded
  //     Bb(10) is approach → excluded
  //     Db(1) is approach → excluded
  //     A(9) is new → enclosure
  //     F(5) is approach → excluded
  // So enclosure set should contain D(2) and A(9) at minimum
  let pitch_classes = enclosure.map(fn(m) { m.pitch_class() })
  // D=2 and A=9 should be present
  assert_true(pitch_classes.contains(2)) // D
  assert_true(pitch_classes.contains(9)) // A
  // Chord tones should not be present
  let chord_pcs = chord.tones().map(fn(m) { m.pitch_class() })
  for pc in pitch_classes {
    assert_false(chord_pcs.contains(pc))
  }
  // Approach tones (1-semitone) should not be present
  let approach_pcs = chord.approach_tones().map(fn(m) { m.pitch_class() })
  for pc in pitch_classes {
    assert_false(approach_pcs.contains(pc))
  }
}

///|
test "Chord::enclosure_tones - Dm7" {
  let chord = Chord::{ root: D, quality: Minor7, bass: None }
  let enclosure = chord.enclosure_tones()
  let chord_pcs = chord.tones().map(fn(m) { m.pitch_class() })
  let approach_pcs = chord.approach_tones().map(fn(m) { m.pitch_class() })
  let pitch_classes = enclosure.map(fn(m) { m.pitch_class() })
  // No enclosure should be a chord tone
  for pc in pitch_classes {
    assert_false(chord_pcs.contains(pc))
  }
  // No enclosure should be an approach tone
  for pc in pitch_classes {
    assert_false(approach_pcs.contains(pc))
  }
}

///|
/// The approach and enclosure pools together form a richer set of
/// neighbor notes around chord tones (1 and 2 semitones away)
test "approach + enclosure tones cover 1 and 2 semitone neighbors" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  let approach = chord.approach_tones()
  let enclosure = chord.enclosure_tones()
  let chord_pcs = chord.tones().map(fn(m) { m.pitch_class() })
  // Approach (1-semitone) and enclosure (2-semitone) should not overlap
  let approach_pcs = approach.map(fn(m) { m.pitch_class() })
  let enclosure_pcs = enclosure.map(fn(m) { m.pitch_class() })
  for pc in enclosure_pcs {
    assert_false(chord_pcs.contains(pc))
    assert_false(approach_pcs.contains(pc))
  }
}
