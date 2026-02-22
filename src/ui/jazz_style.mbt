///|
/// Unified jazz style configuration for a performance session.
/// Controls swing feel, melody techniques, and accompaniment elements.
pub(all) struct JazzStyle {
  swing : @music.SwingConfig
  techniques : @generator.Techniques
  comping_enabled : Bool
  drums_enabled : Bool
  bass_enabled : Bool
  comping_style : @music.CompingStyle
  drum_pattern : @music.DrumPatternStyle
  bass_style : @music.BassStyle
} derive(Eq, Show)

///|
/// Default JazzStyle: triplet swing, all techniques on, full accompaniment.
pub fn JazzStyle::default() -> JazzStyle {
  JazzStyle::{
    swing: @music.SwingConfig::triplet(),
    techniques: @generator.Techniques::default(),
    comping_enabled: true,
    drums_enabled: true,
    bass_enabled: true,
    comping_style: @music.GuideTones,
    drum_pattern: @music.Basic,
    bass_style: @music.WalkingBass,
  }
}

///|
/// Straight: no swing, chord tones only, no accompaniment.
/// Good for hearing the basic melody structure.
pub fn JazzStyle::straight() -> JazzStyle {
  let all_off = @generator.Techniques::{
    tension_tones: false,
    scale_tones: false,
    approach_tones: false,
    enclosure_tones: false,
    syncopation: false,
    triplets: false,
    motif_reuse: false,
    bebop_scales: false,
  }
  JazzStyle::{
    swing: @music.SwingConfig::straight(),
    techniques: all_off,
    comping_enabled: false,
    drums_enabled: false,
    bass_enabled: false,
    comping_style: @music.GuideTones,
    drum_pattern: @music.Basic,
    bass_style: @music.RootOnly,
  }
}

///|
/// Light Jazz: gentle swing, basic harmonics, minimal accompaniment.
pub fn JazzStyle::light_jazz() -> JazzStyle {
  JazzStyle::{
    swing: @music.SwingConfig::light_swing(),
    techniques: @generator.Techniques::{
      tension_tones: true,
      scale_tones: true,
      approach_tones: false,
      enclosure_tones: false,
      syncopation: false,
      triplets: false,
      motif_reuse: false,
      bebop_scales: false,
    },
    comping_enabled: true,
    drums_enabled: true,
    bass_enabled: false,
    comping_style: @music.GuideTones,
    drum_pattern: @music.Basic,
    bass_style: @music.RootOnly,
  }
}

///|
/// Bebop: strong swing, all techniques on, full energy.
pub fn JazzStyle::bebop() -> JazzStyle {
  JazzStyle::{
    swing: @music.SwingConfig::hard_swing(),
    techniques: @generator.Techniques::{
      ..@generator.Techniques::default(),
      enclosure_tones: true,
      bebop_scales: true,
    },
    comping_enabled: true,
    drums_enabled: true,
    bass_enabled: true,
    comping_style: @music.GuideTones,
    drum_pattern: @music.SwingRide,
    bass_style: @music.WalkingBass,
  }
}

///|
/// Cool Jazz: medium swing, tension-focused, understated drums.
pub fn JazzStyle::cool_jazz() -> JazzStyle {
  JazzStyle::{
    swing: @music.SwingConfig::medium_swing(),
    techniques: @generator.Techniques::{
      tension_tones: true,
      scale_tones: true,
      approach_tones: true,
      enclosure_tones: false,
      syncopation: true,
      triplets: false,
      motif_reuse: true,
      bebop_scales: false,
    },
    comping_enabled: true,
    drums_enabled: true,
    bass_enabled: true,
    comping_style: @music.GuideTones,
    drum_pattern: @music.Brushes,
    bass_style: @music.WalkingBass,
  }
}

///|
/// Modal: medium swing, scale-tone focus, walking bass.
pub fn JazzStyle::modal() -> JazzStyle {
  JazzStyle::{
    swing: @music.SwingConfig::triplet(),
    techniques: @generator.Techniques::{
      tension_tones: true,
      scale_tones: true,
      approach_tones: false,
      enclosure_tones: false,
      syncopation: true,
      triplets: true,
      motif_reuse: true,
      bebop_scales: false,
    },
    comping_enabled: true,
    drums_enabled: true,
    bass_enabled: true,
    comping_style: @music.FullVoicing,
    drum_pattern: @music.Basic,
    bass_style: @music.WalkingBass,
  }
}

///|
/// Full Band: all jazz elements on at full strength.
pub fn JazzStyle::full_band() -> JazzStyle {
  JazzStyle::{
    swing: @music.SwingConfig::triplet(),
    techniques: @generator.Techniques::{
      ..@generator.Techniques::default(),
      bebop_scales: true,
    },
    comping_enabled: true,
    drums_enabled: true,
    bass_enabled: true,
    comping_style: @music.FullVoicing,
    drum_pattern: @music.SwingRide,
    bass_style: @music.WalkingBass,
  }
}

///|
/// All named presets: (label, constructor function)
pub let presets : Array[(String, () -> JazzStyle)] = [
  ("Straight", JazzStyle::straight),
  ("Light Jazz", JazzStyle::light_jazz),
  ("Default", JazzStyle::default),
  ("Cool Jazz", JazzStyle::cool_jazz),
  ("Modal", JazzStyle::modal),
  ("Bebop", JazzStyle::bebop),
  ("Full Band", JazzStyle::full_band),
]
