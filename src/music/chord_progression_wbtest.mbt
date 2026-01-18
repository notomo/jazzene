///|
test "parse simple chord" {
  let chord = @helper.unwrap_or_fail(parse_chord("Cm7"))
  assert_eq(chord.root, C)
  assert_eq(chord.quality, Minor7)
}

///|
test "parse chord with sharp" {
  let chord = @helper.unwrap_or_fail(parse_chord("F#maj7"))
  assert_eq(chord.root, FSharp)
  assert_eq(chord.quality, Major7)
}

///|
test "parse dominant with flat" {
  let chord = @helper.unwrap_or_fail(parse_chord("Eb"))
  assert_eq(chord.root, DSharp)
  assert_eq(chord.quality, Major)
}

///|
test "parse chord progression" {
  let chords = @helper.unwrap_or_fail(
    parse_chord_progression("Cm7 F7 Bbmaj7 Ebmaj7"),
  )
  inspect(chords.length(), content="4")

  // first
  let c = chords[0]
  inspect(c.root, content="C")
  inspect(c.quality, content="Minor7")

  // last
  let eb = chords[3]
  inspect(eb.root, content="DSharp")
  inspect(eb.quality, content="Major7")
}

///|
test "parse empty progression" {
  let chords = @helper.unwrap_or_fail(parse_chord_progression(""))
  inspect(chords.length(), content="0")
}

///|
test "parse chord progression with invalid chord" {
  guard parse_chord_progression("Cm7 InvalidChord F7") is Err(e) else {
    fail("Expected error for invalid chord")
  }
  inspect(e.contains("Failed to parse 'InvalidChord'"), content="true")
}

///|
test "parse chord progression with mixed valid and invalid" {
  guard parse_chord_progression("Cm7 XYZ F7 ABC") is Err(e) else {
    fail("Expected error for invalid chords")
  }
  inspect(e.contains("Failed to parse 'XYZ'"), content="true")
  inspect(e.contains("Failed to parse 'ABC'"), content="true")
}

///|
test "Chord tones" {
  let cmaj7 = Chord::{ root: C, quality: Major7 }
  inspect(cmaj7.tones(), content="[60, 64, 67, 71]") // C E G B
}
