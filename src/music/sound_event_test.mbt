///|
test "SoundEvent duration" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  assert_eq(
    @music.Note(midi~, duration=@music.Eighth).duration(bpm).to_milliseconds(),
    250.0,
  )
  assert_eq(
    @music.Note(midi~, duration=@music.Quarter).duration(bpm).to_milliseconds(),
    500.0,
  )
}

///|
test "SoundEvent with_duration" {
  let midi = MidiNumber::new(60).unwrap()
  assert_eq(
    @music.Note(midi~, duration=@music.Quarter).with_duration(@music.Eighth),
    @music.Note(midi~, duration=@music.Eighth),
  )
  assert_eq(
    @music.Rest(duration=@music.Quarter).with_duration(@music.Half),
    @music.Rest(duration=@music.Half),
  )
}
