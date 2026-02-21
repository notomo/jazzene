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
