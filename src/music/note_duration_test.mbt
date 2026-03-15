///|
test "NoteDuration to_beats" {
  assert_eq(@music.Eighth.to_beats(), 0.5)
  assert_eq(@music.Quarter.to_beats(), 1.0)
  assert_eq(@music.Half.to_beats(), 2.0)
  assert_eq(@music.Sixteenth.to_beats(), 0.25)
}

///|
test "NoteDuration fit" {
  assert_eq(NoteDuration::fit(4.0), Some(@music.Whole))
  assert_eq(NoteDuration::fit(1.0), Some(@music.Quarter))
  assert_eq(NoteDuration::fit(0.5), Some(@music.Eighth))
  assert_eq(NoteDuration::fit(0.25), Some(@music.Sixteenth))
  assert_eq(NoteDuration::fit(0.34), Some(@music.EighthTriplet))
  assert_eq(NoteDuration::fit(0.1), None)
}

///|
test "Sixteenth is_beamable" {
  assert_true(@music.Sixteenth.is_beamable())
}

///|
test "EighthTriplet to_beats" {
  // 3 triplet eighths = 1 beat
  let triplet_beat = @music.EighthTriplet.to_beats()
  assert_true((triplet_beat - 1.0 / 3.0).abs() < 0.001)
  assert_true((triplet_beat * 3.0 - 1.0).abs() < 0.001)
}

///|
test "EighthTriplet is_beamable" {
  assert_true(@music.EighthTriplet.is_beamable())
}
