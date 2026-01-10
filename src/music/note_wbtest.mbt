///|
test "NoteDuration to_beats" {
  inspect(Eighth.to_beats(), content="0.5")
  inspect(Quarter.to_beats(), content="1")
  inspect(Half.to_beats(), content="2")
}

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
test "calculate_total_duration with bpm 120" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()

  // Single quarter note: 500ms
  let notes1 = [Note(midi~, duration=Quarter)]
  let sounds1 = NoteValueSound::from_note_values(notes1, bpm)
  inspect(calculate_total_duration(sounds1).to_milliseconds(), content="500")

  // Two quarter notes: 1000ms
  let notes2 = [Note(midi~, duration=Quarter), Note(midi~, duration=Quarter)]
  let sounds2 = NoteValueSound::from_note_values(notes2, bpm)
  inspect(calculate_total_duration(sounds2).to_milliseconds(), content="1000")

  // Mixed durations: Half + Quarter + Eighth = 2 + 1 + 0.5 beats = 1750ms
  let notes3 = [
    Note(midi~, duration=Half),
    Note(midi~, duration=Quarter),
    Note(midi~, duration=Eighth),
  ]
  let sounds3 = NoteValueSound::from_note_values(notes3, bpm)
  inspect(calculate_total_duration(sounds3).to_milliseconds(), content="1750")

  // With rests
  let notes4 = [
    Note(midi~, duration=Quarter),
    Rest(duration=Quarter),
    Note(midi~, duration=Quarter),
  ]
  let sounds4 = NoteValueSound::from_note_values(notes4, bpm)
  inspect(calculate_total_duration(sounds4).to_milliseconds(), content="1500")
}

///|
test "calculate_total_duration with bpm 90" {
  let bpm = 90
  let midi = MidiNumber::new(60).unwrap()

  // Quarter note at 90 bpm: 60000/90 = 666.6666666666666ms
  let notes = [Note(midi~, duration=Quarter)]
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  inspect(
    calculate_total_duration(sounds).to_milliseconds(),
    content="666.6666666666666",
  )

  // Half note: 2 beats = 1333.3333333333333ms (60000/90 * 2)
  let notes2 = [Note(midi~, duration=Half)]
  let sounds2 = NoteValueSound::from_note_values(notes2, bpm)
  inspect(
    calculate_total_duration(sounds2).to_milliseconds(),
    content="1333.3333333333333",
  )
}

///|
test "calculate_total_duration empty array" {
  let notes : Array[NoteValue] = []
  let sounds = NoteValueSound::from_note_values(notes, 120)
  inspect(calculate_total_duration(sounds).to_milliseconds(), content="0")
}
