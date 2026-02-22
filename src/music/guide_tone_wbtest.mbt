///|
/// Empty progression returns empty result
test "guide_tone_line - empty chords returns empty" {
  let result = guide_tone_line([])
  assert_eq(result.length(), 0)
}

///|
/// Single chord returns one pair with reasonable guide tones
test "guide_tone_line - single Cmaj7 chord" {
  let chord = Chord::{ root: C, quality: Major7, bass: None }
  let result = guide_tone_line([chord])
  assert_eq(result.length(), 1)
  // Cmaj7: 3rd=E (interval 4), 7th=B (interval 11)
  // E near MIDI 60: E4(64) or E3(52); B near 60: B3(59) or B4(71)
  assert_eq(result[0].third.pitch_class(), 4) // E
  assert_eq(result[0].seventh.pitch_class(), 11) // B
}

///|
/// Classic II-V-I resolution: 7th of G7 (F) resolves to 3rd of Cmaj7 (E) by half-step
test "guide_tone_line - G7 to Cmaj7 shows half-step resolution" {
  let g7 = Chord::{ root: G, quality: Dominant7, bass: None }
  let cmaj7 = Chord::{ root: C, quality: Major7, bass: None }
  let result = guide_tone_line([g7, cmaj7])
  assert_eq(result.length(), 2)
  // G7 guide tones: 3rd=B (interval 4), 7th=F (interval 10)
  assert_eq(result[0].third.pitch_class(), 11) // B
  assert_eq(result[0].seventh.pitch_class(), 5) // F
  // Cmaj7 guide tones: 3rd=E (interval 4), 7th=B (interval 11)
  // F → E (half-step down), B → B (same)
  assert_eq(result[1].third.pitch_class(), 4) // E
  assert_eq(result[1].seventh.pitch_class(), 11) // B
}

///|
/// Full II-V-I: Dm7 → G7 → Cmaj7
test "guide_tone_line - Dm7 G7 Cmaj7 progression" {
  let dm7 = Chord::{ root: D, quality: Minor7, bass: None }
  let g7 = Chord::{ root: G, quality: Dominant7, bass: None }
  let cmaj7 = Chord::{ root: C, quality: Major7, bass: None }
  let result = guide_tone_line([dm7, g7, cmaj7])
  assert_eq(result.length(), 3)
  // Dm7: 3rd=F (interval 3), 7th=C (interval 10)
  assert_eq(result[0].third.pitch_class(), 5) // F
  assert_eq(result[0].seventh.pitch_class(), 0) // C
  // G7: 3rd=B (interval 4), 7th=F (interval 10)
  // F → B (up 6 or down-6); C → F (up a 4th or down a 5th) — smooth
  assert_eq(result[1].third.pitch_class(), 11) // B
  assert_eq(result[1].seventh.pitch_class(), 5) // F
  // Cmaj7: 3rd=E, 7th=B
  assert_eq(result[2].third.pitch_class(), 4) // E
  assert_eq(result[2].seventh.pitch_class(), 11) // B
}

///|
/// Result length matches input chord count
test "guide_tone_line - result length matches chord count" {
  let chords = [
    Chord::{ root: C, quality: Major7, bass: None },
    Chord::{ root: A, quality: Minor7, bass: None },
    Chord::{ root: D, quality: Minor7, bass: None },
    Chord::{ root: G, quality: Dominant7, bass: None },
  ]
  let result = guide_tone_line(chords)
  assert_eq(result.length(), 4)
}

///|
/// Guide tones stay in a comfortable MIDI range (C2=36 to C6=84)
test "guide_tone_line - guide tones stay in comfortable range" {
  let chords = [
    Chord::{ root: C, quality: Major7, bass: None },
    Chord::{ root: F, quality: Major7, bass: None },
    Chord::{ root: ASharp, quality: Dominant7, bass: None },
    Chord::{ root: DSharp, quality: Major7, bass: None },
  ]
  let result = guide_tone_line(chords)
  for pair in result {
    assert_true(pair.third.value >= 36 && pair.third.value <= 84)
    assert_true(pair.seventh.value >= 36 && pair.seventh.value <= 84)
  }
}

///|
/// Triad uses 3rd and 5th instead of 3rd and 7th
test "guide_tone_line - triad uses 3rd and 5th" {
  let chord = Chord::{ root: C, quality: Major, bass: None }
  let result = guide_tone_line([chord])
  assert_eq(result.length(), 1)
  // Major triad: [0, 4, 7]; 3rd=E(4), 5th=G(7)
  assert_eq(result[0].third.pitch_class(), 4) // E
  assert_eq(result[0].seventh.pitch_class(), 7) // G
}

///|
/// Consecutive chords move by minimal interval (smooth voice leading)
test "guide_tone_line - voice leading is smooth for repeated chord" {
  // Same chord twice: guide tones should not jump octaves
  let chord = Chord::{ root: G, quality: Dominant7, bass: None }
  let result = guide_tone_line([chord, chord])
  assert_eq(result.length(), 2)
  // Third to third: same pitch class, distance should be 0 (same note)
  let third_distance = result[0].third.distance(result[1].third)
  assert_true(third_distance <= 6) // within a tritone
  let seventh_distance = result[0].seventh.distance(result[1].seventh)
  assert_true(seventh_distance <= 6)
}
