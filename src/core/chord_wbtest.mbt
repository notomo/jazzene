///|
test "parse major 7 chord" {
  let result = parse_chord("Cmaj7")
  assert_eq(result, Ok(Chord::{ root: "C", quality: "maj7" }))
}

///|
test "parse minor 7 chord" {
  let result = parse_chord("Cm7")
  assert_eq(result, Ok(Chord::{ root: "C", quality: "m7" }))
}

///|
test "parse dominant 7 chord" {
  let result = parse_chord("F7")
  assert_eq(result, Ok(Chord::{ root: "F", quality: "7" }))
}

///|
test "parse chord with sharp" {
  let result = parse_chord("F#maj7")
  assert_eq(result, Ok(Chord::{ root: "F#", quality: "maj7" }))
}

///|
test "parse chord with flat" {
  let result = parse_chord("Bbm7")
  assert_eq(result, Ok(Chord::{ root: "Bb", quality: "m7" }))
}

///|
test "parse major triad (no quality)" {
  let result = parse_chord("C")
  assert_eq(result, Ok(Chord::{ root: "C", quality: "" }))
}

///|
test "parse empty string returns error" {
  let result = parse_chord("")
  assert_true(result is Err(_))
}

///|
test "parse chord progression" {
  let chords = parse_chord_progression("Cm7 F7 Bbmaj7 Ebmaj7")
  assert_eq(chords.length(), 4)
  assert_eq(chords[0].root, "C")
  assert_eq(chords[0].quality, "m7")
  assert_eq(chords[1].root, "F")
  assert_eq(chords[1].quality, "7")
  assert_eq(chords[2].root, "Bb")
  assert_eq(chords[2].quality, "maj7")
  assert_eq(chords[3].root, "Eb")
  assert_eq(chords[3].quality, "maj7")
}

///|
test "parse empty chord progression" {
  let chords = parse_chord_progression("")
  assert_eq(chords.length(), 0)
}

///|
test "parse chord progression with extra spaces" {
  let chords = parse_chord_progression("  Cm7   F7  ")
  assert_eq(chords.length(), 2)
}

///|
test "chord tones for Cmaj7" {
  let chord = Chord::{ root: "C", quality: "maj7" }
  let tones = chord.tones()
  assert_eq(tones, [60, 64, 67, 71]) // C, E, G, B
}

///|
test "chord tones for Cm7" {
  let chord = Chord::{ root: "C", quality: "m7" }
  let tones = chord.tones()
  assert_eq(tones, [60, 63, 67, 70]) // C, Eb, G, Bb
}
