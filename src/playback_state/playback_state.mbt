///|
/// Playback state structure
pub(all) struct PlaybackState {
  current_note_index : Int
  playback_position_ms : Int
  total_duration_ms : Int
  scheduled_timeouts : Array[@js_global.Timer]
  is_paused : Bool
}

///|
/// Create a new PlaybackState
pub fn PlaybackState::new(
  current_note_index : Int,
  playback_position_ms : Int,
  total_duration_ms : Int,
  scheduled_timeouts : Array[@js_global.Timer],
  is_paused : Bool,
) -> PlaybackState {
  PlaybackState::{
    current_note_index,
    playback_position_ms,
    total_duration_ms,
    scheduled_timeouts,
    is_paused,
  }
}
