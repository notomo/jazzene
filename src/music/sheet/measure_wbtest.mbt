///|
test "key_signature_layout_width - C major has zero width" {
  let key = @music.KeySignature::c_major()
  inspect(key_signature_layout_width(key), content="0")
}

///|
test "key_signature_layout_width - G major has width for 1 sharp" {
  let key = @music.KeySignature::from_root(@music.G)
  inspect(key_signature_layout_width(key), content="17")
}

///|
test "measure_position - first measure" {
  let key = @music.KeySignature::c_major()
  let (x, y) = measure_position(0, key)
  inspect(x, content="90") // MEASURE_START_X + CLEF_SPACE_WIDTH
  inspect(y, content="120") // STAFF_TOP
}

///|
test "measure_position - second row" {
  let key = @music.KeySignature::c_major()
  let (_, y) = measure_position(4, key)
  inspect(y, content="420") // STAFF_TOP + ROW_HEIGHT
}
