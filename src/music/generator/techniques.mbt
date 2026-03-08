///|
/// Toggle flags for jazz improvisation techniques.
/// Each flag controls whether the corresponding technique is enabled.
/// When disabled, the technique's weight/probability in ImprovisationConfig is zeroed out.
pub(all) struct Techniques {
  tension_tones : Bool // Tension notes (9th, 11th, 13th)
  chromatic_approach : Bool // Approach tones (chromatic half-steps)
  enclosure : Bool // Enclosure tones (2 semitones from chord tones)
  syncopation : Bool // Syncopation (off-beat phrase starts)
  triplets : Bool // Eighth-note triplets
  bebop_scales : Bool // Bebop passing tones (major 7th for dom7, #5 for maj7)
  neighbor_tones : Bool // Neighbor tone ornaments (CT→N→CT pattern)
  sixteenth_runs : Bool // Sixteenth-note run ornaments (P1 P2 P3 CT pattern)
} derive(Eq, Show)

///|
/// Default techniques: all enabled
pub fn Techniques::default() -> Techniques {
  Techniques::{
    tension_tones: true,
    chromatic_approach: true,
    enclosure: true,
    syncopation: true,
    triplets: true,
    bebop_scales: true,
    neighbor_tones: true,
    sixteenth_runs: true,
  }
}

///|
/// Return a copy of settings with disabled techniques zeroed out.
/// When a technique flag is false, the corresponding weight/probability
/// in settings is set to 0, effectively disabling it.
pub fn ImprovisationConfig::with_techniques(
  self : ImprovisationConfig,
  techniques : Techniques,
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
