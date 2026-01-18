///|
test "NoteValue duration with bpm 120" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  inspect(
    Note(midi~, duration=Eighth).duration(bpm).to_milliseconds(),
    content="250",
  )
  inspect(
    Note(midi~, duration=Quarter).duration(bpm).to_milliseconds(),
    content="500",
  )
  inspect(
    Note(midi~, duration=Half).duration(bpm).to_milliseconds(),
    content="1000",
  )
  inspect(Rest(duration=Quarter).duration(bpm).to_milliseconds(), content="500")
}

///|
test "Dotted notes duration with bpm 120" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  inspect(
    Note(midi~, duration=DottedEighth).duration(bpm).to_milliseconds(),
    content="375",
  )
  inspect(
    Note(midi~, duration=DottedQuarter).duration(bpm).to_milliseconds(),
    content="750",
  )
  inspect(
    Note(midi~, duration=DottedHalf).duration(bpm).to_milliseconds(),
    content="1500",
  )
  inspect(
    Rest(duration=DottedQuarter).duration(bpm).to_milliseconds(),
    content="750",
  )
}
