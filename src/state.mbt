///|
/// Playback mode tracks whether we're stopped or playing
/// This enum makes impossible states impossible - you can't be "playing at no position"
pub enum PlaybackMode {
  Stopped(Int) // position_ms: Paused at specific position
  Playing(
    Int, // started_at_ms: Date.now() when playback started
    Int, // started_from_position: Position offset in song
    Double
  ) // audio_ctx_start: AudioContext.currentTime anchor
} derive(Eq, Show)

///|
/// Check if currently playing
pub fn PlaybackMode::is_playing(self : PlaybackMode) -> Bool {
  match self {
    Stopped(_) => false
    Playing(_, _, _) => true
  }
}

///|
/// Get current playback position in milliseconds
pub fn PlaybackMode::get_position(
  self : PlaybackMode,
  current_time_ms : Int,
) -> Int {
  match self {
    Stopped(pos) => pos
    Playing(started_at, offset, _) => {
      let elapsed = current_time_ms - started_at
      offset + elapsed
    }
  }
}

///|
/// Application state - single source of truth
pub struct AppState {
  mode : PlaybackMode
  notes : Array[@music.Note]
  total_duration_ms : Int
  tempo_bpm : Int
  volume : Double
  is_muted : Bool
  chord_input : String
} derive(Show)

///|
/// Create default application state
pub fn AppState::default() -> AppState {
  AppState::{
    mode: PlaybackMode::Stopped(0), // position_ms
    notes: [],
    total_duration_ms: 0,
    tempo_bpm: 120,
    volume: 0.7,
    is_muted: false,
    chord_input: "Cm7 F7 Bbmaj7 Ebmaj7",
  }
}

///|
/// Check if currently playing
pub fn AppState::is_playing(self : AppState) -> Bool {
  self.mode.is_playing()
}

///|
/// Get current playback position
pub fn AppState::get_position(self : AppState, current_time_ms : Int) -> Int {
  self.mode.get_position(current_time_ms)
}
