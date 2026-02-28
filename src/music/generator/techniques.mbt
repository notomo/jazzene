///|
/// Toggle flags for jazz improvisation techniques.
/// Each flag controls whether the corresponding technique is enabled.
/// When disabled, the technique's weight/probability in ImprovisationConfig is zeroed out.
pub(all) struct Techniques {
  tension_tones : Bool // Tension notes (9th, 11th, 13th)
  scale_tones : Bool // Scale tones (diatonic non-chord tones)
  approach_tones : Bool // Approach tones (chromatic half-steps)
  enclosure_tones : Bool // Enclosure tones (2 semitones from chord tones)
  syncopation : Bool // Syncopation (off-beat phrase starts)
  triplets : Bool // Eighth-note triplets
  bebop_scales : Bool // Bebop passing tones (major 7th for dom7, #5 for maj7)
  neighbor_tones : Bool // Neighbor tone ornaments (CT→N→CT pattern)
} derive(Eq, Show)

///|
/// Default techniques: all enabled
pub fn Techniques::default() -> Techniques {
  Techniques::{
    tension_tones: true,
    scale_tones: true,
    approach_tones: true,
    enclosure_tones: true,
    syncopation: true,
    triplets: true,
    bebop_scales: false, // disabled by default; opt-in feature
    neighbor_tones: true,
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
    scale_tone_weight_ratio: if techniques.scale_tones {
      self.scale_tone_weight_ratio
    } else {
      0
    },
    chromatic_approach_ornament_probability: if techniques.approach_tones {
      self.chromatic_approach_ornament_probability
    } else {
      0
    },
    enclosure_ornament_probability: if techniques.enclosure_tones {
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
    bebop_weight_ratio: if techniques.bebop_scales {
      self.bebop_weight_ratio
    } else {
      0
    },
    neighbor_ornament_probability: if techniques.neighbor_tones {
      self.neighbor_ornament_probability
    } else {
      0
    },
  }
}
