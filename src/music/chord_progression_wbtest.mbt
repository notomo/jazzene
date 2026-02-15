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
  let dc = DegreeChord::{
    accidental: 0,
    degree: II,
    quality: Minor7,
    bass: None,
  }
  let chord = dc.resolve(ASharp) // Bb
  assert_eq(chord.root, C)
  assert_eq(chord.quality, Minor7)
}

///|
test "resolve V7 in Bb major" {
  // V of Bb = F, so V7 -> F7
  let dc = DegreeChord::{
    accidental: 0,
    degree: V,
    quality: Dominant7,
    bass: None,
  }
  let chord = dc.resolve(ASharp)
  assert_eq(chord.root, F)
  assert_eq(chord.quality, Dominant7)
}

///|
test "resolve Imaj7 in Bb major" {
  let dc = DegreeChord::{
    accidental: 0,
    degree: I,
    quality: Major7,
    bass: None,
  }
  let chord = dc.resolve(ASharp)
  assert_eq(chord.root, ASharp) // Bb
  assert_eq(chord.quality, Major7)
}

///|
test "resolve IVmaj7 in Bb major" {
  // IV of Bb = Eb
  let dc = DegreeChord::{
    accidental: 0,
    degree: IV,
    quality: Major7,
    bass: None,
  }
  let chord = dc.resolve(ASharp)
  assert_eq(chord.root, DSharp) // Eb
  assert_eq(chord.quality, Major7)
}

///|
test "resolve bVII in C major" {
  // bVII of C = Bb
  let dc = DegreeChord::{
    accidental: -1,
    degree: VII,
    quality: Major,
    bass: None,
  }
  let chord = dc.resolve(C)
  assert_eq(chord.root, ASharp) // Bb
  assert_eq(chord.quality, Major)
}

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
    content="[{value: 60}, {value: 64}, {value: 67}, {value: 71}]",
  )
}

///|
test "Chord tension tones - Major7" {
  let cmaj7 = Chord::{ root: C, quality: Major7, bass: None }
  // 9th(D=62), #11th(F#=66), 13th(A=69)
  inspect(
    cmaj7.tension_tones(),
    content="[{value: 62}, {value: 66}, {value: 69}]",
  )
}

///|
test "Chord tension tones - Minor7" {
  let dm7 = Chord::{ root: D, quality: Minor7, bass: None }
  // 9th(E=64), 11th(G=67), 13th(B=71)
  inspect(
    dm7.tension_tones(),
    content="[{value: 64}, {value: 67}, {value: 71}]",
  )
}

///|
test "Chord tension tones - Dominant7" {
  let g7 = Chord::{ root: G, quality: Dominant7, bass: None }
  // 9th(A=69), #11th(C#=73), 13th(E=76)
  inspect(g7.tension_tones(), content="[{value: 69}, {value: 73}, {value: 76}]")
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
    content="[{value: 73}, {value: 76}, {value: 79}]",
  )
}

///|
test "parse measure progression without delimiter treats all as single measure" {
  let measures = @helper.unwrap_or_fail(
    parse_measure_progression("IIm7 V7 Imaj7 IVmaj7"),
  )
  assert_eq(measures.length(), 1)
  // All chords in single measure
  assert_eq(measures[0].chords.length(), 4)
  assert_eq(measures[0].chords[0].degree, II)
  assert_eq(measures[0].chords[1].degree, V)
  assert_eq(measures[0].chords[2].degree, I)
  assert_eq(measures[0].chords[3].degree, IV)
}

///|
test "parse measure progression" {
  let measures = @helper.unwrap_or_fail(
    parse_measure_progression("IIm7 V7 | Imaj7 | IVmaj7"),
  )
  assert_eq(measures.length(), 3)
  // First measure has 2 chords
  assert_eq(measures[0].chords.length(), 2)
  assert_eq(measures[0].chords[0].degree, II)
  assert_eq(measures[0].chords[1].degree, V)
  // Second measure has 1 chord
  assert_eq(measures[1].chords.length(), 1)
  assert_eq(measures[1].chords[0].degree, I)
  // Third measure has 1 chord
  assert_eq(measures[2].chords.length(), 1)
  assert_eq(measures[2].chords[0].degree, IV)
}

///|
test "parse measure progression with multiple chords per measure" {
  let measures = @helper.unwrap_or_fail(
    parse_measure_progression("IIm7 V7 | Imaj7 VIm7 | IVmaj7 IIIm7"),
  )
  assert_eq(measures.length(), 3)
  assert_eq(measures[0].chords.length(), 2)
  assert_eq(measures[1].chords.length(), 2)
  assert_eq(measures[2].chords.length(), 2)
}

///|
test "parse measure progression empty string" {
  let measures = @helper.unwrap_or_fail(parse_measure_progression(""))
  assert_eq(measures.length(), 0)
}

///|
test "parse measure progression empty measure error" {
  guard parse_measure_progression("IIm7 | | V7") is Err(e) else {
    fail("Expected error for empty measure")
  }
  assert_true(e.contains("Empty measure"))
}

///|
test "DegreeMeasure resolve" {
  let dm = DegreeMeasure::{
    chords: [
      DegreeChord::{ accidental: 0, degree: II, quality: Minor7, bass: None },
      DegreeChord::{ accidental: 0, degree: V, quality: Dominant7, bass: None },
    ],
  }
  let resolved = dm.resolve(C)
  assert_eq(resolved.length(), 2)
  assert_eq(resolved[0].root, D) // II of C
  assert_eq(resolved[0].quality, Minor7)
  assert_eq(resolved[1].root, G) // V of C
  assert_eq(resolved[1].quality, Dominant7)
}

///|
test "parse degree chord with slash bass V7/II" {
  let dc = @helper.unwrap_or_fail(parse_degree_chord("V7/II"))
  assert_eq(dc.degree, V)
  assert_eq(dc.quality, Dominant7)
  assert_eq(dc.accidental, 0)
  assert_eq(dc.bass, Some(DegreeBass::{ accidental: 0, degree: II }))
}

///|
test "parse degree chord with flat bass IIm7/bVII" {
  let dc = @helper.unwrap_or_fail(parse_degree_chord("IIm7/bVII"))
  assert_eq(dc.degree, II)
  assert_eq(dc.quality, Minor7)
  assert_eq(dc.bass, Some(DegreeBass::{ accidental: -1, degree: VII }))
}

///|
test "parse degree chord without slash has None bass" {
  let dc = @helper.unwrap_or_fail(parse_degree_chord("IIm7"))
  assert_eq(dc.bass, None)
}

///|
test "resolve slash chord V7/II in C major" {
  // V7 = G7, bass II = D
  let dc = DegreeChord::{
    accidental: 0,
    degree: V,
    quality: Dominant7,
    bass: Some(DegreeBass::{ accidental: 0, degree: II }),
  }
  let chord = dc.resolve(C)
  assert_eq(chord.root, G)
  assert_eq(chord.quality, Dominant7)
  assert_eq(chord.bass, Some(D))
}

///|
test "format slash chord" {
  let chord = Chord::{ root: G, quality: Dominant7, bass: Some(D) }
  assert_eq(format_chord(chord), "G7/D")
}

///|
test "format chord without bass" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  assert_eq(format_chord(chord), "Cmaj7")
}

///|
test "parse measure progression with slash chord" {
  let measures = @helper.unwrap_or_fail(
    parse_measure_progression("IIm7 V7/II | Imaj7"),
  )
  assert_eq(measures.length(), 2)
  assert_eq(measures[0].chords.length(), 2)
  assert_eq(
    measures[0].chords[1].bass,
    Some(DegreeBass::{ accidental: 0, degree: II }),
  )
}
