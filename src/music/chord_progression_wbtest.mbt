///|
test "parse degree chord IIm7" {
  let dc = @helper.unwrap_or_fail(parse_degree_chord("IIm7"))
  assert_eq(dc.degree, II)
  assert_eq(dc.quality, Minor7)
  assert_eq(dc.accidental, 0)
}

///|
test "parse degree chord V7" {
  let dc = @helper.unwrap_or_fail(parse_degree_chord("V7"))
  assert_eq(dc.degree, V)
  assert_eq(dc.quality, Dominant7)
  assert_eq(dc.accidental, 0)
}

///|
test "parse degree chord Imaj7" {
  let dc = @helper.unwrap_or_fail(parse_degree_chord("Imaj7"))
  assert_eq(dc.degree, I)
  assert_eq(dc.quality, Major7)
  assert_eq(dc.accidental, 0)
}

///|
test "parse degree chord with flat accidental" {
  let dc = @helper.unwrap_or_fail(parse_degree_chord("bVIImaj7"))
  assert_eq(dc.degree, VII)
  assert_eq(dc.quality, Major7)
  assert_eq(dc.accidental, -1)
}

///|
test "parse degree chord with sharp accidental" {
  let dc = @helper.unwrap_or_fail(parse_degree_chord("#IVm7b5"))
  assert_eq(dc.degree, IV)
  assert_eq(dc.quality, HalfDiminished)
  assert_eq(dc.accidental, 1)
}

///|
test "parse degree chord lowercase roman numeral" {
  let dc = @helper.unwrap_or_fail(parse_degree_chord("ii7"))
  assert_eq(dc.degree, II)
  assert_eq(dc.quality, Dominant7)
  assert_eq(dc.accidental, 0)
}

///|
test "parse degree progression" {
  let chords = @helper.unwrap_or_fail(
    parse_degree_progression("IIm7 V7 Imaj7 IVmaj7"),
  )
  assert_eq(chords.length(), 4)
  assert_eq(chords[0].degree, II)
  assert_eq(chords[0].quality, Minor7)
  assert_eq(chords[1].degree, V)
  assert_eq(chords[1].quality, Dominant7)
  assert_eq(chords[2].degree, I)
  assert_eq(chords[2].quality, Major7)
  assert_eq(chords[3].degree, IV)
  assert_eq(chords[3].quality, Major7)
}

///|
test "parse empty degree progression" {
  let chords = @helper.unwrap_or_fail(parse_degree_progression(""))
  assert_eq(chords.length(), 0)
}

///|
test "parse degree progression with invalid token" {
  guard parse_degree_progression("IIm7 XYZ V7") is Err(e) else {
    fail("Expected error for invalid degree chord")
  }
  assert_true(e.contains("Failed to parse 'XYZ'"))
}

///|
test "resolve IIm7 in Bb major" {
  // II of Bb = C, so IIm7 -> Cm7
  let dc = DegreeChord::{ accidental: 0, degree: II, quality: Minor7 }
  let chord = dc.resolve(ASharp) // Bb
  assert_eq(chord.root, C)
  assert_eq(chord.quality, Minor7)
}

///|
test "resolve V7 in Bb major" {
  // V of Bb = F, so V7 -> F7
  let dc = DegreeChord::{ accidental: 0, degree: V, quality: Dominant7 }
  let chord = dc.resolve(ASharp)
  assert_eq(chord.root, F)
  assert_eq(chord.quality, Dominant7)
}

///|
test "resolve Imaj7 in Bb major" {
  let dc = DegreeChord::{ accidental: 0, degree: I, quality: Major7 }
  let chord = dc.resolve(ASharp)
  assert_eq(chord.root, ASharp) // Bb
  assert_eq(chord.quality, Major7)
}

///|
test "resolve IVmaj7 in Bb major" {
  // IV of Bb = Eb
  let dc = DegreeChord::{ accidental: 0, degree: IV, quality: Major7 }
  let chord = dc.resolve(ASharp)
  assert_eq(chord.root, DSharp) // Eb
  assert_eq(chord.quality, Major7)
}

///|
test "resolve bVII in C major" {
  // bVII of C = Bb
  let dc = DegreeChord::{ accidental: -1, degree: VII, quality: Major }
  let chord = dc.resolve(C)
  assert_eq(chord.root, ASharp) // Bb
  assert_eq(chord.quality, Major)
}

///|
test "Chord tones" {
  let cmaj7 = Chord::{ root: C, quality: Major7 }
  // C E G B
  inspect(
    cmaj7.tones(),
    content="[{value: 60}, {value: 64}, {value: 67}, {value: 71}]",
  )
}
