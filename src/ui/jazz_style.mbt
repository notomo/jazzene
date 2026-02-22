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
