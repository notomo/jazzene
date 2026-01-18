///|
test "ChordRoot from_string" {
  inspect(ChordRoot::from_string("C"), content="Ok(C)")
  inspect(
    ChordRoot::from_string("Invalid"),
    content="Err(\"Invalid chord root: Invalid\")",
  )
}

///|
test "ChordRoot midi" {
  assert_eq(C.midi(), 60) // C4
  assert_eq(CSharp.midi(), 61)
}
