///|
test "same seed produces deterministic sequence" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings1 = GeneratorSettings::default(chords, 42)
  let settings2 = GeneratorSettings::default(chords, 42)
  let gen1 = create_note_value_generator(settings1)
  let gen2 = create_note_value_generator(settings2)
  // Generate 10 notes from each and compare
  for i = 0; i < 10; i = i + 1 {
    let note1 = gen1()
    let note2 = gen2()
    inspect(note1 == note2, content="true")
  }
}

///|
test "different seeds produce different sequences" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings1 = GeneratorSettings::default(chords, 1)
  let settings2 = GeneratorSettings::default(chords, 2)
  let gen1 = create_note_value_generator(settings1)
  let gen2 = create_note_value_generator(settings2)
  // Generate multiple notes and check that at least one differs
  let notes1 : Array[NoteValue] = []
  let notes2 : Array[NoteValue] = []
  for i = 0; i < 20; i = i + 1 {
    notes1.push(gen1())
    notes2.push(gen2())
  }
  let mut has_difference = false
  for i = 0; i < notes1.length(); i = i + 1 {
    if notes1[i] != notes2[i] {
      has_difference = true
    }
  }
  inspect(has_difference, content="true")
}

///|
test "rest_probability 0 produces all notes" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings = GeneratorSettings::{
    chords,
    seed: 123,
    rest_probability: 0,
    duration_weights: DurationWeights::default(),
  }
  let gen = create_note_value_generator(settings)
  // Generate 20 notes and verify none are rests
  for i = 0; i < 20; i = i + 1 {
    match gen() {
      Note(..) => ()
      Rest(..) => fail("Expected note, got rest at index \{i}")
    }
  }
}

///|
test "rest_probability 100 produces all rests" {
  let chords = [Chord::{ root: C, quality: Major7 }]
  let settings = GeneratorSettings::{
    chords,
    seed: 456,
    rest_probability: 100,
    duration_weights: DurationWeights::default(),
  }
  let gen = create_note_value_generator(settings)
  // Generate 20 notes and verify all are rests
  for i = 0; i < 20; i = i + 1 {
    match gen() {
      Rest(..) => ()
      Note(..) => fail("Expected rest, got note at index \{i}")
    }
  }
}

///|
test "generator cycles through chords" {
  let chords = [
    Chord::{ root: C, quality: Major7 },
    Chord::{ root: F, quality: Dominant7 },
  ]
  let settings = GeneratorSettings::{
    chords,
    seed: 789,
    rest_probability: 0, // All notes to verify MIDI values
    duration_weights: DurationWeights::default(),
  }
  let gen = create_note_value_generator(settings)
  // Generate notes and verify they come from different chords
  let c_tones = chords[0].tones()
  let f_tones = chords[1].tones()
  let mut found_c_tone = false
  let mut found_f_tone = false
  for i = 0; i < 100; i = i + 1 {
    match gen() {
      Note(midi~, ..) => {
        let midi_val = midi.value
        // Check against extended octaves
        for j = 0; j < c_tones.length(); j = j + 1 {
          let t = c_tones[j]
          let offsets = [-12, 0, 12]
          for k = 0; k < offsets.length(); k = k + 1 {
            if midi_val == t + offsets[k] {
              found_c_tone = true
            }
          }
        }
        for j = 0; j < f_tones.length(); j = j + 1 {
          let t = f_tones[j]
          let offsets = [-12, 0, 12]
          for k = 0; k < offsets.length(); k = k + 1 {
            if midi_val == t + offsets[k] {
              found_f_tone = true
            }
          }
        }
      }
      Rest(..) => ()
    }
  }
  inspect(found_c_tone && found_f_tone, content="true")
}
