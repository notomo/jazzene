///|
test "KeySignature::from_root C major has no alterations" {
  let key = KeySignature::from_root(C)
  inspect(key.altered_steps.length(), content="0")
  inspect(key.accidental_type, content="Natural")
}

///|
test "KeySignature::from_root G major has F#" {
  let key = KeySignature::from_root(G)
  inspect(key.altered_steps, content="[3]")
  inspect(key.accidental_type, content="Sharp")
}

///|
test "KeySignature::from_root F major has Bb" {
  let key = KeySignature::from_root(F)
  inspect(key.altered_steps, content="[6]")
  inspect(key.accidental_type, content="Flat")
}

///|
test "KeySignature::from_root D major has F# C#" {
  let key = KeySignature::from_root(D)
  inspect(key.altered_steps, content="[3, 0]")
  inspect(key.accidental_type, content="Sharp")
}

///|
test "KeySignature::from_root Bb major has Bb Eb" {
  let key = KeySignature::from_root(ASharp)
  inspect(key.altered_steps, content="[6, 2]")
  inspect(key.accidental_type, content="Flat")
}

///|
test "pitch_class_to_diatonic_step C major" {
  let key = KeySignature::c_major()
  inspect(key.pitch_class_to_diatonic_step(0), content="0") // C
  inspect(key.pitch_class_to_diatonic_step(2), content="1") // D
  inspect(key.pitch_class_to_diatonic_step(4), content="2") // E
  inspect(key.pitch_class_to_diatonic_step(5), content="3") // F
  inspect(key.pitch_class_to_diatonic_step(7), content="4") // G
  inspect(key.pitch_class_to_diatonic_step(9), content="5") // A
  inspect(key.pitch_class_to_diatonic_step(11), content="6") // B
}

///|
test "pitch_class_to_diatonic_step F major maps Bb to step 6" {
  let key = KeySignature::from_root(F)
  // Bb (pitch class 10) should map to step 6 (B-flat = diatonic B step)
  inspect(key.pitch_class_to_diatonic_step(10), content="6")
  // B natural (pitch class 11) should still map to step 6
  inspect(key.pitch_class_to_diatonic_step(11), content="6")
}

///|
test "pitch_class_accidental C major" {
  let key = KeySignature::c_major()
  // White keys -> Natural
  inspect(key.pitch_class_accidental(0), content="Natural") // C
  inspect(key.pitch_class_accidental(4), content="Natural") // E
  // Black keys -> Sharp (C major uses sharps by default)
  inspect(key.pitch_class_accidental(1), content="Sharp") // C#
  inspect(key.pitch_class_accidental(6), content="Sharp") // F#
}

///|
test "pitch_class_accidental F major" {
  let key = KeySignature::from_root(F)
  // Bb is in key signature -> Flat
  inspect(key.pitch_class_accidental(10), content="Flat") // Bb
  // B natural -> Natural (white key)
  inspect(key.pitch_class_accidental(11), content="Natural") // B
  // Other black keys in flat key -> Flat
  inspect(key.pitch_class_accidental(1), content="Flat") // Db
}

///|
test "pitch_class_accidental G major" {
  let key = KeySignature::from_root(G)
  // F# is in key signature -> Sharp
  inspect(key.pitch_class_accidental(6), content="Sharp") // F#
  // F natural -> Natural
  inspect(key.pitch_class_accidental(5), content="Natural") // F
  // Other black keys -> Sharp
  inspect(key.pitch_class_accidental(1), content="Sharp") // C#
}

///|
test "signature_midi_positions C major returns empty" {
  let key = KeySignature::c_major()
  inspect(key.signature_midi_positions().length(), content="0")
}

///|
test "signature_midi_positions G major returns one position" {
  let key = KeySignature::from_root(G)
  let positions = key.signature_midi_positions()
  inspect(positions.length(), content="1")
  inspect(positions[0], content="77") // F5
}

///|
test "signature_midi_positions F major returns one position" {
  let key = KeySignature::from_root(F)
  let positions = key.signature_midi_positions()
  inspect(positions.length(), content="1")
  inspect(positions[0], content="71") // B4
}

///|
test "signature_midi_positions D major returns two positions" {
  let key = KeySignature::from_root(D)
  let positions = key.signature_midi_positions()
  inspect(positions.length(), content="2")
  inspect(positions[0], content="77") // F5
  inspect(positions[1], content="72") // C5
}

///|
test "all_roots returns 12 keys" {
  let roots = KeySignature::all_roots()
  inspect(roots.length(), content="12")
  inspect(roots[0], content="C")
}
