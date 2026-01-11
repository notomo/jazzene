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
  inspect(C.midi(), content="60") // C4
  inspect(CSharp.midi(), content="61")
  inspect(A.midi(), content="69") // A4 = 440Hz
  inspect(B.midi(), content="71")
}
