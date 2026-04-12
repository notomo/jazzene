///|
/// Controls whether melody is generated and played.
pub(all) enum MelodyMode {
  On // Generate melody and play sound
  Silent // Generate melody (visible in score) but no audio
  Off // No melody generated or displayed
} derive(Eq, Debug)

///|
pub impl Show for MelodyMode with output(self, logger) {
  self.to_repr().output(logger)
}

///|
/// Controls whether comping is generated and played.
pub(all) enum CompingMode {
  On // Generate comping and play sound
  Silent // Generate comping (visible in piano roll) but no audio
  Off // No comping generated or displayed
} derive(Eq, Debug)

///|
pub impl Show for CompingMode with output(self, logger) {
  self.to_repr().output(logger)
}

///|
/// Unified jazz style configuration for a performance session.
/// Controls swing feel, melody techniques, and accompaniment elements.
pub(all) struct JazzStyle {
  swing : SwingConfig
  techniques : Techniques
  melody_mode : MelodyMode
  comping_mode : CompingMode
  drums_enabled : Bool
  bass_enabled : Bool
  comping_style : CompingStyle
  drum_pattern : DrumPatternStyle
  bass_style : BassStyle
  pitch_min : Int
  pitch_max : Int
} derive(Eq, Debug)

///|
pub impl Show for JazzStyle with output(self, logger) {
  self.to_repr().output(logger)
}

///|
/// Default JazzStyle: hard swing, all techniques on, full accompaniment.
pub fn JazzStyle::default() -> JazzStyle {
  JazzStyle::{
    swing: SwingConfig::triplet(),
    techniques: Techniques::{ ..Techniques::default(), bebop_scales: true },
    melody_mode: On,
    comping_mode: On,
    drums_enabled: true,
    bass_enabled: true,
    comping_style: WithTensions,
    drum_pattern: SwingRide,
    bass_style: WalkingBass,
    pitch_min: 48,
    pitch_max: 84,
  }
}

///|
/// Straight: no swing, chord tones only, no accompaniment.
/// Good for hearing the basic melody structure.
pub fn JazzStyle::straight() -> JazzStyle {
  let all_off = Techniques::{
    tension_tones: false,
    chromatic_approach: false,
    enclosure: false,
    syncopation: false,
    triplets: false,
    bebop_scales: false,
    neighbor_tones: false,
    sixteenth_runs: false,
  }
  JazzStyle::{
    swing: SwingConfig::straight(),
    techniques: all_off,
    melody_mode: On,
    comping_mode: Off,
    drums_enabled: false,
    bass_enabled: false,
    comping_style: GuideTones,
    drum_pattern: SwingRide,
    bass_style: RootOnly,
    pitch_min: 48,
    pitch_max: 84,
  }
}

///|
/// Simple: triplet swing, core techniques, guide tone comping.
/// Good balance between readability and jazz character.
pub fn JazzStyle::simple() -> JazzStyle {
  let techniques = Techniques::{
    tension_tones: false,
    chromatic_approach: true,
    enclosure: false,
    syncopation: true,
    triplets: true,
    bebop_scales: false,
    neighbor_tones: false,
    sixteenth_runs: false,
  }
  JazzStyle::{
    swing: SwingConfig::triplet(),
    techniques,
    melody_mode: On,
    comping_mode: On,
    drums_enabled: true,
    bass_enabled: true,
    comping_style: GuideTones,
    drum_pattern: SwingRide,
    bass_style: RootOnly,
    pitch_min: 48,
    pitch_max: 84,
  }
}
