///|
/// Verify that decide_midi_number assigns ChordTone for first note (no previous)
test "decide_midi_number first note always returns ChordTone" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let key = @music.KeySignature::c_major()
  let rng = create_random_int(0)
  let (midi, origin) = decide_midi_number(
    chord,
    key,
    None,
    50,
    50,
    false,
    0,
    30,
    50,
    20,
    7,
    rng,
  )
  assert_true(midi is Some(_))
  inspect(origin, content="Some(ChordTone)")
}

///|
/// Verify that decide_midi_number returns None for rest (both midi and origin)
test "decide_midi_number rest returns None for both midi and origin" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let key = @music.KeySignature::c_major()
  // Force rest by passing rest_probability=100
  let always_rest = fn(_max : Int) -> Int { 0 } // always 0, so 0 < 100 → rest
  let (midi, origin) = decide_midi_number(
    chord,
    key,
    Some(@music.MidiNumber::new(60).unwrap()),
    50,
    50,
    false,
    100,
    30,
    50,
    20,
    7,
    always_rest,
  )
  inspect(midi, content="None")
  inspect(origin, content="None")
}

///|
/// Verify that chord tone selection produces ChordTone origin
test "decide_midi_number chord tone returns ChordTone origin" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let key = @music.KeySignature::c_major()
  // Use weight ratios that only enable chord tones (scale/tension/approach all 0)
  let rng = create_random_int(42)
  let (midi, origin) = decide_midi_number(
    chord,
    key,
    Some(@music.MidiNumber::new(60).unwrap()),
    50,
    50,
    false,
    0,
    0,
    0,
    0,
    7,
    rng,
  )
  // Only chord tones enabled → origin must be ChordTone or None (rest)
  match origin {
    Some(@music.ChordTone) | None => () // expected
    _ => fail("Expected ChordTone or None, got: \{origin}")
  }
  // If midi is Some, origin must be ChordTone
  match (midi, origin) {
    (Some(_), Some(@music.ChordTone)) => ()
    (None, None) => ()
    _ => fail("Unexpected combination: midi=\{midi}, origin=\{origin}")
  }
}

///|
/// Verify that decide_midi_number returns valid origin types for all categories
test "decide_midi_number origin is always a valid ToneOrigin variant" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let key = @music.KeySignature::c_major()
  let valid_origins : Array[@music.ToneOrigin] = [
    @music.ChordTone,
    @music.Tension(9),
    @music.Tension(11),
    @music.Tension(13),
    @music.ScaleTone,
    @music.ApproachTone,
  ]
  // Run many trials with different seeds and verify all origins are valid
  for seed = 0; seed < 20; seed = seed + 1 {
    let rng = create_random_int(seed)
    let (midi, origin) = decide_midi_number(
      chord,
      key,
      Some(@music.MidiNumber::new(60).unwrap()),
      50,
      50,
      false,
      0,
      30,
      50,
      20,
      7,
      rng,
    )
    match (midi, origin) {
      (None, None) => () // rest is valid
      (Some(_), Some(o)) => {
        // Origin must be a recognized tone category
        let is_valid = match o {
          @music.ChordTone | @music.ScaleTone | @music.ApproachTone => true
          @music.Tension(degree) => degree >= 9 && degree <= 13
          _ => false
        }
        assert_true(is_valid)
        ignore(valid_origins)
      }
      _ => fail("Inconsistent midi/origin pair")
    }
  }
}

///|
/// Verify that when tension tones are selected, degree is a valid jazz degree
test "Tension origin carries valid jazz degree" {
  let chord = @music.Chord::{
    root: @music.G,
    quality: @music.Dominant7,
    bass: None,
  }
  let key = @music.KeySignature::c_major()
  // Run many trials and collect all Tension origins to verify degrees
  for seed = 0; seed < 50; seed = seed + 1 {
    let rng = create_random_int(seed)
    let (_, origin) = decide_midi_number(
      chord,
      key,
      Some(@music.MidiNumber::new(62).unwrap()),
      50,
      50,
      false,
      0,
      0,
      100,
      0,
      12,
      rng, // high max_interval to reach tensions
    )
    match origin {
      Some(@music.Tension(degree)) => {
        // Valid jazz tension degrees: 9, 11, 13
        let valid = degree == 9 || degree == 11 || degree == 13
        assert_true(valid)
      }
      _ => ()
    }
  }
}

///|
/// Verify that MeasureNote carries tone_origin set during generation
test "generated MeasureNote carries tone_origin" {
  let settings = Settings::default(0)
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let generator = create_measure_generator(settings)
  let ctx = MeasureContext::{
    chords: create_chord_segments([chord], 4.0),
    incoming_tie: None,
    key: @music.KeySignature::c_major(),
    time_signature: @music.TimeSignature::default(),
    beats_per_measure: 4.0,
    incoming_stamina: 50,
    incoming_last_midi: None,
    incoming_phrase: None,
    incoming_motif_memory: MotifMemory::empty(),
  }
  let result = generator(ctx)
  // All non-rest notes must have a tone_origin; rests must have None
  for beat in result.beats {
    for note in beat.notes {
      match (note.midi, note.tone_origin) {
        (Some(_), Some(_)) => () // note with origin: expected
        (None, None) => () // rest with no origin: expected
        (Some(_), None) => fail("Note with midi but no tone_origin")
        (None, Some(_)) => fail("Rest with unexpected tone_origin")
      }
    }
  }
}

///|
/// Verify tension_degree helper returns valid jazz degree values
test "tension_degree returns valid jazz degrees" {
  // Root C = MIDI 60
  let root_midi = 60
  // 9th: interval 2 semitones above root
  let d2 = @music.MidiNumber::new(62).unwrap()
  assert_eq(tension_degree(root_midi, d2), 9)
  // 11th: interval 5 semitones
  let d5 = @music.MidiNumber::new(65).unwrap()
  assert_eq(tension_degree(root_midi, d5), 11)
  // #11: interval 6 semitones
  let d6 = @music.MidiNumber::new(66).unwrap()
  assert_eq(tension_degree(root_midi, d6), 11)
  // 13th: interval 9 semitones
  let d9 = @music.MidiNumber::new(69).unwrap()
  assert_eq(tension_degree(root_midi, d9), 13)
}
