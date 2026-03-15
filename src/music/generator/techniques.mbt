///|
fn ImprovisationConfig::with_pitch_range(
  self : ImprovisationConfig,
  pitch_min : Int,
  pitch_max : Int,
) -> ImprovisationConfig {
  ImprovisationConfig::{ ..self, pitch_min, pitch_max }
}

///|
/// Return a copy of settings with disabled techniques zeroed out.
/// When a technique flag is false, the corresponding weight/probability
/// in settings is set to 0, effectively disabling it.
fn ImprovisationConfig::with_techniques(
  self : ImprovisationConfig,
  techniques : @music.Techniques,
) -> ImprovisationConfig {
  ImprovisationConfig::{
    ..self,
    tension_weight_ratio: if techniques.tension_tones {
      self.tension_weight_ratio
    } else {
      0
    },
    chromatic_approach_ornament_probability: if techniques.chromatic_approach {
      self.chromatic_approach_ornament_probability
    } else {
      0
    },
    enclosure_ornament_probability: if techniques.enclosure {
      self.enclosure_ornament_probability
    } else {
      0
    },
    syncopation_probability: if techniques.syncopation {
      self.syncopation_probability
    } else {
      0
    },
    triplet_probability: if techniques.triplets {
      self.triplet_probability
    } else {
      0
    },
    bebop_ornament_probability: if techniques.bebop_scales {
      self.bebop_ornament_probability
    } else {
      0
    },
    neighbor_ornament_probability: if techniques.neighbor_tones {
      self.neighbor_ornament_probability
    } else {
      0
    },
    sixteenth_run_probability: if techniques.sixteenth_runs {
      self.sixteenth_run_probability
    } else {
      0
    },
  }
}

///|
test "ImprovisationConfig::with_techniques preserves values when all enabled" {
  let s = ImprovisationConfig::default(42)
  let t = @music.Techniques::default()
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
  assert_eq(result.bebop_ornament_probability, 30)
}

///|
test "ImprovisationConfig::with_techniques enables bebop when flag is true" {
  // Set a non-zero bebop_ornament_probability and enable the flag
  let s = ImprovisationConfig::{
    ..ImprovisationConfig::default(42),
    bebop_ornament_probability: 40,
  }
  let t = @music.Techniques::{
    ..@music.Techniques::default(),
    bebop_scales: true,
  }
  let result = s.with_techniques(t)
  assert_eq(result.bebop_ornament_probability, 40)
}

///|
test "ImprovisationConfig::with_techniques zeros bebop when flag is false" {
  let s = ImprovisationConfig::{
    ..ImprovisationConfig::default(42),
    bebop_ornament_probability: 40,
  }
  let t = @music.Techniques::{
    ..@music.Techniques::default(),
    bebop_scales: false,
  }
  let result = s.with_techniques(t)
  assert_eq(result.bebop_ornament_probability, 0)
}

///|
test "ImprovisationConfig::with_techniques preserves neighbor_ornament_probability when enabled" {
  let s = ImprovisationConfig::default(42)
  let t = @music.Techniques::{
    ..@music.Techniques::default(),
    neighbor_tones: true,
  }
  let result = s.with_techniques(t)
  assert_eq(
    result.neighbor_ornament_probability,
    s.neighbor_ornament_probability,
  )
}

///|
test "ImprovisationConfig::with_techniques zeros neighbor_ornament_probability when disabled" {
  let s = ImprovisationConfig::default(42)
  let t = @music.Techniques::{
    ..@music.Techniques::default(),
    neighbor_tones: false,
  }
  let result = s.with_techniques(t)
  assert_eq(result.neighbor_ornament_probability, 0)
}

///|
test "ImprovisationConfig::with_techniques zeros tension when disabled" {
  let s = ImprovisationConfig::default(42)
  let t = @music.Techniques::{
    ..@music.Techniques::default(),
    tension_tones: false,
  }
  let result = s.with_techniques(t)
  assert_eq(result.tension_weight_ratio, 0)
}

///|
test "ImprovisationConfig::with_techniques zeros approach tones when disabled" {
  let s = ImprovisationConfig::default(42)
  let t = @music.Techniques::{
    ..@music.Techniques::default(),
    chromatic_approach: false,
  }
  let result = s.with_techniques(t)
  assert_eq(result.chromatic_approach_ornament_probability, 0)
}

///|
test "ImprovisationConfig::with_techniques zeros syncopation when disabled" {
  let s = ImprovisationConfig::default(42)
  let t = @music.Techniques::{
    ..@music.Techniques::default(),
    syncopation: false,
  }
  let result = s.with_techniques(t)
  assert_eq(result.syncopation_probability, 0)
}

///|
test "ImprovisationConfig::with_techniques zeros triplets when disabled" {
  let s = ImprovisationConfig::default(42)
  let t = @music.Techniques::{ ..@music.Techniques::default(), triplets: false }
  let result = s.with_techniques(t)
  assert_eq(result.triplet_probability, 0)
}

///|
test "ImprovisationConfig::with_techniques zeros multiple techniques" {
  let s = ImprovisationConfig::default(42)
  let t = @music.Techniques::{
    tension_tones: false,
    chromatic_approach: false,
    enclosure: false,
    syncopation: true,
    triplets: true,
    bebop_scales: false,
    neighbor_tones: true,
    sixteenth_runs: false,
  }
  let result = s.with_techniques(t)
  assert_eq(result.tension_weight_ratio, 0)
  assert_eq(result.chromatic_approach_ornament_probability, 0)
  assert_eq(result.enclosure_ornament_probability, 0)
  assert_eq(result.syncopation_probability, s.syncopation_probability)
  assert_eq(result.triplet_probability, s.triplet_probability)
}
