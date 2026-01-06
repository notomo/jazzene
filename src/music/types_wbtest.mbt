///|
test "NoteDuration to_beats" {
  inspect(Eighth.to_beats(), content="0.5")
  inspect(Quarter.to_beats(), content="1")
  inspect(Half.to_beats(), content="2")
}

///|
test "NoteDuration to_ms with bpm 120" {
  let bpm = 120
  inspect(Eighth.to_ms(bpm), content="250")
  inspect(Quarter.to_ms(bpm), content="500")
  inspect(Half.to_ms(bpm), content="1000")
}

///|
test "MidiNumber validation" {
  inspect(MidiNumber::new(60), content="Some({value: 60})")
  inspect(MidiNumber::new(0), content="Some({value: 0})")
  inspect(MidiNumber::new(127), content="Some({value: 127})")
  inspect(MidiNumber::new(-1), content="None")
  inspect(MidiNumber::new(128), content="None")
}

///|
test "NoteName from_string" {
  inspect(NoteName::from_string("C"), content="Some(C)")
  inspect(NoteName::from_string("C#"), content="Some(CSharp)")
  inspect(NoteName::from_string("Db"), content="Some(CSharp)")
  inspect(NoteName::from_string("F#"), content="Some(FSharp)")
  inspect(NoteName::from_string("Gb"), content="Some(FSharp)")
  inspect(NoteName::from_string("Invalid"), content="None")
}

///|
test "NoteName to_midi" {
  inspect(C.to_midi(), content="60") // C4
  inspect(CSharp.to_midi(), content="61")
  inspect(A.to_midi(), content="69") // A4 = 440Hz
  inspect(B.to_midi(), content="71")
}

///|
test "ChordQuality intervals" {
  inspect(Major7.intervals(), content="[0, 4, 7, 11]")
  inspect(Minor7.intervals(), content="[0, 3, 7, 10]")
  inspect(Dominant7.intervals(), content="[0, 4, 7, 10]")
  inspect(HalfDiminished.intervals(), content="[0, 3, 6, 10]")
}

///|
test "Chord tones" {
  let cmaj7 = Chord::{ root: C, quality: Major7 }
  inspect(cmaj7.tones(), content="[60, 64, 67, 71]") // C E G B
  let cm7 = Chord::{ root: C, quality: Minor7 }
  inspect(cm7.tones(), content="[60, 63, 67, 70]") // C Eb G Bb
  let f7 = Chord::{ root: F, quality: Dominant7 }
  inspect(f7.tones(), content="[65, 69, 72, 75]") // F A C Eb
}

///|
test "Note creation" {
  let note = Note::new(60, Quarter)
  inspect(note, content="Some({midi: {value: 60}, duration: Quarter})")
  let invalid = Note::new(128, Quarter)
  inspect(invalid, content="None")
}

///|
test "Note name" {
  let c4 = Note::new(60, Quarter).unwrap()
  inspect(c4.name(), content="C4")
  let a4 = Note::new(69, Quarter).unwrap()
  inspect(a4.name(), content="A4")
}

///|
test "calculate_total_duration with bpm 120" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()

  // Single quarter note: 500ms
  let notes1 = [Note(midi~, duration=Quarter)]
  inspect(
    calculate_total_duration(notes1, bpm).to_milliseconds(),
    content="500",
  )

  // Two quarter notes: 1000ms
  let notes2 = [Note(midi~, duration=Quarter), Note(midi~, duration=Quarter)]
  inspect(
    calculate_total_duration(notes2, bpm).to_milliseconds(),
    content="1000",
  )

  // Mixed durations: Half + Quarter + Eighth = 2 + 1 + 0.5 beats = 1750ms
  let notes3 = [
    Note(midi~, duration=Half),
    Note(midi~, duration=Quarter),
    Note(midi~, duration=Eighth),
  ]
  inspect(
    calculate_total_duration(notes3, bpm).to_milliseconds(),
    content="1750",
  )

  // With rests
  let notes4 = [
    Note(midi~, duration=Quarter),
    Rest(duration=Quarter),
    Note(midi~, duration=Quarter),
  ]
  inspect(
    calculate_total_duration(notes4, bpm).to_milliseconds(),
    content="1500",
  )
}

///|
test "calculate_total_duration with bpm 90" {
  let bpm = 90
  let midi = MidiNumber::new(60).unwrap()

  // Quarter note at 90 bpm: 60000/90 = 666.67ms ≈ 666ms
  let notes = [Note(midi~, duration=Quarter)]
  inspect(calculate_total_duration(notes, bpm).to_milliseconds(), content="666")

  // Half note: 2 beats = 1332ms (60000/90 * 2 = 666 * 2 = 1332 due to integer division)
  let notes2 = [Note(midi~, duration=Half)]
  inspect(
    calculate_total_duration(notes2, bpm).to_milliseconds(),
    content="1332",
  )
}

///|
test "calculate_total_duration empty array" {
  let notes : Array[NoteValue] = []
  inspect(calculate_total_duration(notes, 120).to_milliseconds(), content="0")
}
