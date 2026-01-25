///|
test "same seed produces deterministic sequence" {
  let chords = [@music.Chord::{ root: @music.C, quality: @music.Major7 }]
  let settings = Settings::default(chords, 42)
  Array::make(10, 0).each(fn(_) {
    assert_eq(
      create_note_value_generator(settings)(),
      create_note_value_generator(settings)(),
    )
  })
}

///|
test "rest_probability 0 produces note" {
  let chords = [@music.Chord::{ root: @music.C, quality: @music.Major7 }]
  let settings = Settings::{
    chords,
    seed: 123,
    rest_probability: 0,
    duration_weights: DurationWeights::default(),
  }
  let gen = create_note_value_generator(settings)
  Array::make(10, 0).each(fn(_) {
    guard gen() is @music.Note(_) else { fail("Expected Note") }
  })
}

///|
test "rest_probability 100 produces rest" {
  let chords = [@music.Chord::{ root: @music.C, quality: @music.Major7 }]
  let settings = Settings::{
    chords,
    seed: 456,
    rest_probability: 100,
    duration_weights: DurationWeights::default(),
  }
  let gen = create_note_value_generator(settings)
  Array::make(10, 0).each(fn(_) {
    guard gen() is @music.Rest(_) else { fail("Expected Rest") }
  })
}
