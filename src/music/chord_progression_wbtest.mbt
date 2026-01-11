///|
test "parse simple chord Cm7" {
  let result = parse_chord("Cm7")
  match result {
    Ok(chord) => {
      inspect(chord.root, content="C")
      inspect(chord.quality, content="Minor7")
    }
    Err(e) => abort("Failed to parse Cm7: " + e)
  }
}

///|
test "parse chord with sharp F#maj7" {
  let result = parse_chord("F#maj7")
  match result {
    Ok(chord) => {
      inspect(chord.root, content="FSharp")
      inspect(chord.quality, content="Major7")
    }
    Err(e) => abort("Failed to parse F#maj7: " + e)
  }
}

///|
test "parse dominant 7th chord" {
  let result = parse_chord("G7")
  match result {
    Ok(chord) => {
      inspect(chord.root, content="G")
      inspect(chord.quality, content="Dominant7")
    }
    Err(e) => abort("Failed to parse G7: " + e)
  }
}

///|
test "parse chord progression" {
  let result = parse_chord_progression("Cm7 F7 Bbmaj7 Ebmaj7")
  match result {
    Ok(chords) => {
      inspect(chords.length(), content="4")

      // Check first chord
      let c = chords[0]
      inspect(c.root, content="C")
      inspect(c.quality, content="Minor7")

      // Check last chord
      let eb = chords[3]
      inspect(eb.root, content="DSharp")
      inspect(eb.quality, content="Major7")
    }
    Err(e) => abort("Failed to parse progression: " + e)
  }
}

///|
test "parse empty progression" {
  let result = parse_chord_progression("")
  match result {
    Ok(chords) => inspect(chords.length(), content="0")
    Err(e) => abort("Failed to parse empty progression: " + e)
  }
}

///|
test "parse chord progression with invalid chord" {
  let result = parse_chord_progression("Cm7 InvalidChord F7")
  match result {
    Ok(_) => abort("Expected error for invalid chord")
    Err(e) =>
      inspect(e.contains("Failed to parse 'InvalidChord'"), content="true")
  }
}

///|
test "parse chord progression with mixed valid and invalid" {
  let result = parse_chord_progression("Cm7 XYZ F7 ABC")
  match result {
    Ok(_) => abort("Expected error for invalid chords")
    Err(e) => {
      inspect(e.contains("Failed to parse 'XYZ'"), content="true")
      inspect(e.contains("Failed to parse 'ABC'"), content="true")
    }
  }
}

///|
test "Chord tones" {
  let cmaj7 = Chord::{ root: C, quality: Major7 }
  inspect(cmaj7.tones(), content="[60, 64, 67, 71]") // C E G B
  let cm7 = Chord::{ root: C, quality: Minor7 }
  inspect(cm7.tones(), content="[60, 63, 67, 70]") // C Eb G Bb
  let f7 = Chord::{ root: F, quality: Dominant7 }
  inspect(f7.tones(), content="[65, 69, 72, 75]") // F A C Eb
}
