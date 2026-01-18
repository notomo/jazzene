///|
test "NoteDuration to_beats" {
  inspect(Eighth.to_beats(), content="0.5")
  inspect(Quarter.to_beats(), content="1")
  inspect(Half.to_beats(), content="2")
}

///|
test "NoteDuration to_beats for dotted notes" {
  inspect(DottedEighth.to_beats(), content="0.75")
  inspect(DottedQuarter.to_beats(), content="1.5")
  inspect(DottedHalf.to_beats(), content="3")
}
