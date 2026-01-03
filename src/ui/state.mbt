///|
/// Playback mode tracks whether we're stopped or playing
/// This enum makes impossible states impossible - you can't be "playing at no position"
pub enum PlaybackMode {
  Stopped(position_ms~ : Int)
  Playing(started_at_ms~ : Int, started_from_position~ : Int)
} derive(Eq, Show)

///|
/// Create a Stopped mode at a specific position
pub fn PlaybackMode::stopped(position_ms : Int) -> PlaybackMode {
  PlaybackMode::Stopped(position_ms~)
}

///|
/// Create a Playing mode
pub fn PlaybackMode::playing(
  started_at_ms : Int,
  started_from_position : Int,
) -> PlaybackMode {
  PlaybackMode::Playing(started_at_ms~, started_from_position~)
}
