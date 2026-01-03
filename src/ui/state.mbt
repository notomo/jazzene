///|
/// Playback mode tracks whether we're stopped or playing
/// Both variants hold the current playback position in milliseconds
pub enum PlaybackMode {
  Stopped(position_ms~ : Int)
  Playing(position_ms~ : Int)
} derive(Eq, Show)

///|
/// Create a Stopped mode at a specific position
pub fn PlaybackMode::stopped(position_ms : Int) -> PlaybackMode {
  PlaybackMode::Stopped(position_ms~)
}

///|
/// Create a Playing mode
pub fn PlaybackMode::playing(position_ms : Int) -> PlaybackMode {
  PlaybackMode::Playing(position_ms~)
}
