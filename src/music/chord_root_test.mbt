///|
test "ChordRoot from_string" {
  debug_inspect(@music.ChordRoot::from_string("C"), content="Ok(C)")
  debug_inspect(
    @music.ChordRoot::from_string("Invalid"),
    content=(
      #|Err("Invalid chord root: Invalid")
    ),
  )
}

///|
test "ChordRoot midi" {
  assert_eq(@music.C.midi(), 60) // C4
  assert_eq(@music.CSharp.midi(), 61)
}
