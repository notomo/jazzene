///|
test "NoteDuration to_beats" {
  inspect(Eighth.to_beats(), content="0.5")
  inspect(Quarter.to_beats(), content="1")
  inspect(Half.to_beats(), content="2")
}

///|
test "NoteDuration to_ms with tempo 120" {
  let tempo = 120
  inspect(Eighth.to_ms(tempo), content="250")
  inspect(Quarter.to_ms(tempo), content="500")
  inspect(Half.to_ms(tempo), content="1000")
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
