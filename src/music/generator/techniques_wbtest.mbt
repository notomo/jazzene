///|
test "Techniques::default enables standard techniques, bebop disabled by default" {
  let t = Techniques::default()
  assert_true(t.tension_tones)
  assert_true(t.approach_tones)
  assert_true(t.enclosure_tones)
  assert_true(t.syncopation)
  assert_true(t.triplets)
  // bebop_scales is enabled by default
  assert_true(t.bebop_scales)
  // neighbor_tones enabled by default
  assert_true(t.neighbor_tones)
}

///|
test "ImprovisationConfig::with_techniques preserves values when all enabled" {
  let s = ImprovisationConfig::default(42)
  let t = Techniques::default()
  let result = s.with_techniques(t)
  assert_eq(result.tension_weight_ratio, s.tension_weight_ratio)
  assert_eq(
    result.chromatic_approach_ornament_probability,
    s.chromatic_approach_ornament_probability,
  )
  assert_eq(
    result.enclosure_ornament_probability,
    s.enclosure_ornament_probability,
  )
  assert_eq(result.syncopation_probability, s.syncopation_probability)
  assert_eq(result.triplet_probability, s.triplet_probability)
  assert_eq(result.bebop_weight_ratio, 0) // bebop_weight_ratio is 0 in ImprovisationConfig::default
}

///|
test "ImprovisationConfig::with_techniques enables bebop when flag is true" {
  // Set a non-zero bebop_weight_ratio and enable the flag
  let s = ImprovisationConfig::{
    ..ImprovisationConfig::default(42),
    bebop_weight_ratio: 40,
  }
  let t = Techniques::{ ..Techniques::default(), bebop_scales: true }
  let result = s.with_techniques(t)
  assert_eq(result.bebop_weight_ratio, 40)
}

///|
test "ImprovisationConfig::with_techniques zeros bebop when flag is false" {
  let s = ImprovisationConfig::{
    ..ImprovisationConfig::default(42),
    bebop_weight_ratio: 40,
  }
  let t = Techniques::{ ..Techniques::default(), bebop_scales: false }
  let result = s.with_techniques(t)
  assert_eq(result.bebop_weight_ratio, 0)
}

///|
test "ImprovisationConfig::with_techniques preserves neighbor_ornament_probability when enabled" {
  let s = ImprovisationConfig::default(42)
  let t = Techniques::{ ..Techniques::default(), neighbor_tones: true }
  let result = s.with_techniques(t)
  assert_eq(
    result.neighbor_ornament_probability,
    s.neighbor_ornament_probability,
  )
}

///|
test "ImprovisationConfig::with_techniques zeros neighbor_ornament_probability when disabled" {
  let s = ImprovisationConfig::default(42)
  let t = Techniques::{ ..Techniques::default(), neighbor_tones: false }
  let result = s.with_techniques(t)
  assert_eq(result.neighbor_ornament_probability, 0)
}

///|
test "ImprovisationConfig::with_techniques zeros tension when disabled" {
  let s = ImprovisationConfig::default(42)
  let t = Techniques::{ ..Techniques::default(), tension_tones: false }
  let result = s.with_techniques(t)
  assert_eq(result.tension_weight_ratio, 0)
}

///|
test "ImprovisationConfig::with_techniques zeros approach tones when disabled" {
  let s = ImprovisationConfig::default(42)
  let t = Techniques::{ ..Techniques::default(), approach_tones: false }
  let result = s.with_techniques(t)
  assert_eq(result.chromatic_approach_ornament_probability, 0)
}

///|
test "ImprovisationConfig::with_techniques zeros syncopation when disabled" {
  let s = ImprovisationConfig::default(42)
  let t = Techniques::{ ..Techniques::default(), syncopation: false }
  let result = s.with_techniques(t)
  assert_eq(result.syncopation_probability, 0)
}

///|
test "ImprovisationConfig::with_techniques zeros triplets when disabled" {
  let s = ImprovisationConfig::default(42)
  let t = Techniques::{ ..Techniques::default(), triplets: false }
  let result = s.with_techniques(t)
  assert_eq(result.triplet_probability, 0)
}

///|
test "ImprovisationConfig::with_techniques zeros multiple techniques" {
  let s = ImprovisationConfig::default(42)
  let t = Techniques::{
    tension_tones: false,
    approach_tones: false,
    enclosure_tones: false,
    syncopation: true,
    triplets: true,
    bebop_scales: false,
    neighbor_tones: true,
  }
  let result = s.with_techniques(t)
  assert_eq(result.tension_weight_ratio, 0)
  assert_eq(result.chromatic_approach_ornament_probability, 0)
  assert_eq(result.enclosure_ornament_probability, 0)
  assert_eq(result.syncopation_probability, s.syncopation_probability)
  assert_eq(result.triplet_probability, s.triplet_probability)
}
