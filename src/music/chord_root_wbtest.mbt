///|
test "ChordRoot from_string" {
  inspect(ChordRoot::from_string("C"), content="Ok(C)")
  inspect(ChordRoot::from_string("C#"), content="Ok(CSharp)")
  inspect(ChordRoot::from_string("Db"), content="Ok(CSharp)")
  inspect(ChordRoot::from_string("F#"), content="Ok(FSharp)")
  inspect(ChordRoot::from_string("Gb"), content="Ok(FSharp)")
  inspect(
    ChordRoot::from_string("Invalid"),
    content="Err(\"Invalid chord root: Invalid\")",
  )
}

///|
test "ChordRoot midi" {
  assert_eq(C.midi(), 60) // C4
  assert_eq(CSharp.midi(), 61)
  assert_eq(A.midi(), 69) // A4 = 440Hz
  assert_eq(B.midi(), 71)
}
