///|
test "ChordRoot from_string" {
  inspect(ChordRoot::from_string("C"), content="Some(C)")
  inspect(ChordRoot::from_string("C#"), content="Some(CSharp)")
  inspect(ChordRoot::from_string("Db"), content="Some(CSharp)")
  inspect(ChordRoot::from_string("F#"), content="Some(FSharp)")
  inspect(ChordRoot::from_string("Gb"), content="Some(FSharp)")
  inspect(ChordRoot::from_string("Invalid"), content="None")
}

///|
test "ChordRoot midi" {
  inspect(C.midi(), content="60") // C4
  inspect(CSharp.midi(), content="61")
  inspect(A.midi(), content="69") // A4 = 440Hz
  inspect(B.midi(), content="71")
}
