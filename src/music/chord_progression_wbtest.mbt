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
  assert_eq(chords.length(), 4)

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
  assert_eq(chords.length(), 0)
}

///|
test "parse chord progression including invalid" {
  guard parse_chord_progression("Cm7 XYZ F7 ABC") is Err(e) else {
    fail("Expected error for invalid chords")
  }
  assert_true(e.contains("Failed to parse 'XYZ'"))
  assert_true(e.contains("Failed to parse 'ABC'"))
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
