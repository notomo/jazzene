///|
/// Verify ChordScale::intervals returns correct interval sets
test "ChordScale::intervals - Ionian (major scale)" {
  let intervals = ChordScale::Ionian.intervals()
  inspect(intervals, content="[0, 2, 4, 5, 7, 9, 11]")
}

///|
test "ChordScale::intervals - Dorian" {
  let intervals = ChordScale::Dorian.intervals()
  inspect(intervals, content="[0, 2, 3, 5, 7, 9, 10]")
}

///|
test "ChordScale::intervals - Mixolydian" {
  let intervals = ChordScale::Mixolydian.intervals()
  inspect(intervals, content="[0, 2, 4, 5, 7, 9, 10]")
}

///|
test "ChordScale::intervals - BebopDominant has 8 notes" {
  let intervals = ChordScale::BebopDominant.intervals()
  assert_eq(intervals.length(), 8)
  inspect(intervals, content="[0, 2, 4, 5, 7, 9, 10, 11]")
}

///|
test "ChordScale::intervals - BebopMajor has 8 notes" {
  let intervals = ChordScale::BebopMajor.intervals()
  assert_eq(intervals.length(), 8)
  inspect(intervals, content="[0, 2, 4, 5, 7, 8, 9, 11]")
}

///|
/// Verify chord quality → chord scale mapping
test "ChordQuality::chord_scale - Major7 → Ionian" {
  inspect(ChordQuality::Major7.chord_scale(), content="Ionian")
}

///|
test "ChordQuality::chord_scale - Minor7 → Dorian" {
  inspect(ChordQuality::Minor7.chord_scale(), content="Dorian")
}

///|
test "ChordQuality::chord_scale - Dominant7 → Mixolydian" {
  inspect(ChordQuality::Dominant7.chord_scale(), content="Mixolydian")
}

///|
test "ChordQuality::chord_scale - HalfDiminished → Locrian" {
  inspect(ChordQuality::HalfDiminished.chord_scale(), content="Locrian")
}

///|
test "ChordQuality::chord_scale - Diminished7 → Diminished" {
  inspect(ChordQuality::Diminished7.chord_scale(), content="Diminished")
}

///|
test "ChordQuality::chord_scale - MinorMajor7 → MelodicMinor" {
  inspect(ChordQuality::MinorMajor7.chord_scale(), content="MelodicMinor")
}

///|
test "ChordQuality::chord_scale - Augmented → WholeTone" {
  inspect(ChordQuality::Augmented.chord_scale(), content="WholeTone")
}

///|
/// Verify Chord::scale_tones uses chord scale theory (not just major scale)
test "Chord::scale_tones - Cmaj7 in C (Ionian from C)" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  let scale_tones = chord.scale_tones()
  // Ionian from C: [0,2,4,5,7,9,11]; chord tones Cmaj7: [0,4,7,11]
  // Tensions Major7: [2,6,9] → D(2), F#(6), A(9) excluded
  // Scale tone: F(5) only — natural 11 (avoid note, not a tension)
  let pitch_classes = scale_tones.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[5]")
}

///|
test "Chord::scale_tones - Dm7 (Dorian from D = D E F G A B C)" {
  let chord = Chord::{ root: D, quality: Minor7, bass: None }
  let scale_tones = chord.scale_tones()
  // Dorian from D (root=62): [0,2,3,5,7,9,10]
  // D(62)=chord, E(64)=scale, F(65)=chord, G(67)=scale, A(69)=chord, B(71)=scale, C(72)=chord
  // Tensions Minor7: [2,5,9] → E(4), G(7), B(11) all excluded (all scale tones are tensions)
  let pitch_classes = scale_tones.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[]")
}

///|
test "Chord::scale_tones - G7 (Mixolydian from G = G A B C D E F)" {
  let chord = Chord::{ root: G, quality: Dominant7, bass: None }
  let scale_tones = chord.scale_tones()
  // Mixolydian from G (root=67): [0,2,4,5,7,9,10]
  // G7 chord tones: G(7), B(11), D(2), F(5)
  // Non-chord: A(9), C(0), E(4)
  // Tensions Dominant7: [1,2,3,6,8,9] → pitch classes [8,9,10,1,3,4]; A(9) and E(4) excluded
  // Scale tone: C(0) only — natural 11 (avoid note)
  let pitch_classes = scale_tones.map(fn(m) { m.pitch_class() })
  assert_false(pitch_classes.contains(9)) // A is tension (9th)
  assert_true(pitch_classes.contains(0)) // C is pure scale tone (natural 11)
  assert_false(pitch_classes.contains(4)) // E is tension (13th)
  assert_false(pitch_classes.contains(7)) // G is chord tone
  assert_false(pitch_classes.contains(11)) // B is chord tone
}

///|
test "Chord::scale_tones - none are chord tones" {
  let chord = Chord::{ root: C, quality: Minor7, bass: None }
  let chord_pcs = chord.tones().map(fn(m) { m.pitch_class() })
  let scale_tones = chord.scale_tones()
  for tone in scale_tones {
    assert_false(chord_pcs.contains(tone.pitch_class()))
  }
}
