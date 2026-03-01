///|
/// Controls whether melody is generated and played.
pub(all) enum MelodyMode {
  Full // Generate melody and play sound
  Silent // Generate melody (visible in score) but no audio
  Off // No melody generated or displayed
} derive(Eq, Show)

///|
/// Unified jazz style configuration for a performance session.
/// Controls swing feel, melody techniques, and accompaniment elements.
pub(all) struct JazzStyle {
  swing : @music.SwingConfig
  techniques : @generator.Techniques
  melody_mode : MelodyMode
  comping_enabled : Bool
  drums_enabled : Bool
  bass_enabled : Bool
  comping_style : @music.CompingStyle
  drum_pattern : @music.DrumPatternStyle
  bass_style : @music.BassStyle
} derive(Eq, Show)

///|
/// Default JazzStyle: hard swing, all techniques on, full accompaniment.
pub fn JazzStyle::default() -> JazzStyle {
  JazzStyle::{
    swing: @music.SwingConfig::triplet(),
    techniques: @generator.Techniques::{
      ..@generator.Techniques::default(),
      bebop_scales: true,
    },
    melody_mode: Full,
    comping_enabled: true,
    drums_enabled: true,
    bass_enabled: true,
    comping_style: @music.WithTensions,
    drum_pattern: @music.SwingRide,
    bass_style: @music.WalkingBass,
  }
}

///|
/// Straight: no swing, chord tones only, no accompaniment.
/// Good for hearing the basic melody structure.
pub fn JazzStyle::straight() -> JazzStyle {
  let all_off = @generator.Techniques::{
    tension_tones: false,
    chromatic_approach: false,
    enclosure: false,
    syncopation: false,
    triplets: false,
    bebop_scales: false,
    neighbor_tones: false,
  }
  JazzStyle::{
    swing: @music.SwingConfig::straight(),
    techniques: all_off,
    melody_mode: Full,
    comping_enabled: false,
    drums_enabled: false,
    bass_enabled: false,
    comping_style: @music.GuideTones,
    drum_pattern: @music.SwingRide,
    bass_style: @music.RootOnly,
  }
}

///|
/// Simple: triplet swing, core techniques, guide tone comping.
/// Good balance between readability and jazz character.
pub fn JazzStyle::simple() -> JazzStyle {
  let techniques = @generator.Techniques::{
    tension_tones: false,
    chromatic_approach: true,
    enclosure: false,
    syncopation: true,
    triplets: true,
    bebop_scales: false,
    neighbor_tones: false,
  }
  JazzStyle::{
    swing: @music.SwingConfig::triplet(),
    techniques,
    melody_mode: Full,
    comping_enabled: true,
    drums_enabled: true,
    bass_enabled: true,
    comping_style: @music.GuideTones,
    drum_pattern: @music.SwingRide,
    bass_style: @music.RootOnly,
  }
}

///|
/// All named presets: (label, constructor function)
pub let presets : Array[(String, () -> JazzStyle)] = [
  ("Straight", JazzStyle::straight),
  ("Simple", JazzStyle::simple),
  ("Default", JazzStyle::default),
]
