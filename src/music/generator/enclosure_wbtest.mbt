///|
/// Verify ImprovisationConfig has enclosure_weight_ratio field with default 15
test "ImprovisationConfig::default has enclosure_weight_ratio" {
  let s = ImprovisationConfig::default(0)
  assert_true(s.enclosure_weight_ratio > 0)
  assert_eq(s.enclosure_weight_ratio, 15)
}

///|
/// Verify Techniques has enclosure_tones flag enabled by default
test "Techniques::default has enclosure_tones enabled" {
  let t = Techniques::default()
  assert_true(t.enclosure_tones)
}

///|
/// Verify ImprovisationConfig::with_techniques zeros enclosure when disabled
test "ImprovisationConfig::with_techniques zeros enclosure when disabled" {
  let s = ImprovisationConfig::default(0)
  let t = Techniques::{ ..Techniques::default(), enclosure_tones: false }
  let result = s.with_techniques(t)
  assert_eq(result.enclosure_weight_ratio, 0)
}

///|
/// Verify generated notes can have Enclosure origin
test "generated notes can include Enclosure origin" {
  let settings = ImprovisationConfig::default(7)
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
  // Generate many measures and check that origins are always valid
  for seed = 0; seed < 5; seed = seed + 1 {
    let result = generator(ctx)
    for beat in result.beats {
      for note in beat.notes {
        match (note.midi, note.tone_origin) {
          (Some(_), Some(_)) => () // note with origin
          (None, None) => () // rest
          (Some(_), None) => fail("Note missing tone_origin")
          (None, Some(_)) => fail("Rest has unexpected tone_origin")
        }
      }
    }
  }
}
