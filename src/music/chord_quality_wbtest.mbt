///|
test "ChordQuality intervals" {
  inspect(Major7.intervals(), content="[0, 4, 7, 11]")
  inspect(Minor7.intervals(), content="[0, 3, 7, 10]")
  inspect(Dominant7.intervals(), content="[0, 4, 7, 10]")
  inspect(HalfDiminished.intervals(), content="[0, 3, 6, 10]")
}
