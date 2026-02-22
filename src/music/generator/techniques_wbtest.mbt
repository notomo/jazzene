///|
test "Techniques::default enables standard techniques, bebop disabled by default" {
  let t = Techniques::default()
  assert_true(t.tension_tones)
  assert_true(t.scale_tones)
  assert_true(t.approach_tones)
  assert_true(t.enclosure_tones)
  assert_true(t.syncopation)
  assert_true(t.triplets)
  assert_true(t.motif_reuse)
  // bebop_scales is opt-in; disabled by default
  assert_false(t.bebop_scales)
}

///|
test "Settings::with_techniques preserves values when all enabled" {
  let s = Settings::default(42)
  let t = Techniques::default()
  let result = s.with_techniques(t)
  assert_eq(result.tension_weight_ratio, s.tension_weight_ratio)
  assert_eq(result.scale_tone_weight_ratio, s.scale_tone_weight_ratio)
  assert_eq(result.approach_weight_ratio, s.approach_weight_ratio)
  assert_eq(result.enclosure_weight_ratio, s.enclosure_weight_ratio)
  assert_eq(result.syncopation_probability, s.syncopation_probability)
  assert_eq(result.triplet_probability, s.triplet_probability)
  assert_eq(result.motif_reuse_probability, s.motif_reuse_probability)
  assert_eq(result.bebop_weight_ratio, 0) // bebop disabled by default
}

///|
test "Settings::with_techniques enables bebop when flag is true" {
  // Set a non-zero bebop_weight_ratio and enable the flag
  let s = Settings::{ ..Settings::default(42), bebop_weight_ratio: 40 }
  let t = Techniques::{ ..Techniques::default(), bebop_scales: true }
  let result = s.with_techniques(t)
  assert_eq(result.bebop_weight_ratio, 40)
}

///|
test "Settings::with_techniques zeros bebop when flag is false" {
  let s = Settings::{ ..Settings::default(42), bebop_weight_ratio: 40 }
  let t = Techniques::{ ..Techniques::default(), bebop_scales: false }
  let result = s.with_techniques(t)
  assert_eq(result.bebop_weight_ratio, 0)
}

///|
test "Settings::with_techniques zeros tension when disabled" {
  let s = Settings::default(42)
  let t = Techniques::{ ..Techniques::default(), tension_tones: false }
  let result = s.with_techniques(t)
  assert_eq(result.tension_weight_ratio, 0)
  assert_eq(result.scale_tone_weight_ratio, s.scale_tone_weight_ratio)
}

///|
test "Settings::with_techniques zeros scale tones when disabled" {
  let s = Settings::default(42)
  let t = Techniques::{ ..Techniques::default(), scale_tones: false }
  let result = s.with_techniques(t)
  assert_eq(result.scale_tone_weight_ratio, 0)
  assert_eq(result.tension_weight_ratio, s.tension_weight_ratio)
}

///|
test "Settings::with_techniques zeros approach tones when disabled" {
  let s = Settings::default(42)
  let t = Techniques::{ ..Techniques::default(), approach_tones: false }
  let result = s.with_techniques(t)
  assert_eq(result.approach_weight_ratio, 0)
}

///|
test "Settings::with_techniques zeros syncopation when disabled" {
  let s = Settings::default(42)
  let t = Techniques::{ ..Techniques::default(), syncopation: false }
  let result = s.with_techniques(t)
  assert_eq(result.syncopation_probability, 0)
}

///|
test "Settings::with_techniques zeros triplets when disabled" {
  let s = Settings::default(42)
  let t = Techniques::{ ..Techniques::default(), triplets: false }
  let result = s.with_techniques(t)
  assert_eq(result.triplet_probability, 0)
}

///|
test "Settings::with_techniques zeros motif reuse when disabled" {
  let s = Settings::default(42)
  let t = Techniques::{ ..Techniques::default(), motif_reuse: false }
  let result = s.with_techniques(t)
  assert_eq(result.motif_reuse_probability, 0)
}

///|
test "Settings::with_techniques zeros multiple techniques" {
  let s = Settings::default(42)
  let t = Techniques::{
    tension_tones: false,
    scale_tones: false,
    approach_tones: false,
    enclosure_tones: false,
    syncopation: true,
    triplets: true,
    motif_reuse: false,
    bebop_scales: false,
  }
  let result = s.with_techniques(t)
  assert_eq(result.tension_weight_ratio, 0)
  assert_eq(result.scale_tone_weight_ratio, 0)
  assert_eq(result.approach_weight_ratio, 0)
  assert_eq(result.enclosure_weight_ratio, 0)
  assert_eq(result.syncopation_probability, s.syncopation_probability)
  assert_eq(result.triplet_probability, s.triplet_probability)
  assert_eq(result.motif_reuse_probability, 0)
}
