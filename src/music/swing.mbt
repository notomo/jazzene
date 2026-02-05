///|
/// Configuration for swing feel in playback
pub struct SwingConfig {
  /// Ratio for eighth note division within a beat
  /// 0.5 = straight (equal 8ths), 0.67 = triplet feel, 0.75 = heavy swing
  ratio : Double
} derive(Eq, Show)

///|
/// Create a straight feel (no swing)
pub fn SwingConfig::straight() -> SwingConfig {
  SwingConfig::{ ratio: 0.5 }
}

///|
/// Create a triplet swing feel
pub fn SwingConfig::triplet() -> SwingConfig {
  SwingConfig::{ ratio: 2.0 / 3.0 }
}

///|
/// Calculate the swing delay for a given beat position
/// Only applies to off-beat eighth notes (positions like 0.5, 1.5, 2.5, etc.)
/// Returns the delay in milliseconds to add to the note's start time
pub fn swing_offset(
  beat_position : Double,
  beat_duration_ms : Double,
  swing : SwingConfig,
) -> Double {
  let fraction = beat_position - beat_position.floor()
  // Check if this is an off-beat eighth note (fraction ≈ 0.5)
  if (fraction - 0.5).abs() < 0.01 {
    (swing.ratio - 0.5) * beat_duration_ms
  } else {
    0.0
  }
}
