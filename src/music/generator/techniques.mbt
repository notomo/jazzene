///|
pub fn ImprovisationConfig::with_pitch_range(
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
pub fn ImprovisationConfig::with_techniques(
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
