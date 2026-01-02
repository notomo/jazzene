///|
/// Render play/pause button
pub fn render_play_pause_button(
  notes : @signal.Signal[Array[@music.Note]],
  mode : @signal.Signal[PlaybackMode],
  audio_ctx : @web_audio.AudioContext,
  tempo : @signal.Signal[Int],
) -> @dom.DomNode {
  // Event handler
  let on_play_pause : @dom.MouseHandler = fn(_) {
    if notes.get().length() == 0 {
      return
    }
    match mode.get() {
      Stopped(position_ms) => {
        // Calculate total duration
        let total_duration = @audio.calculate_total_duration(
          notes.get(),
          tempo.get(),
        )
        // If at the end, restart from beginning
        let start_position = if position_ms >= total_duration {
          0
        } else {
          position_ms
        }
        // Start playing
        let now_ms = @date.Date::now()
        let audio_start = audio_ctx.current_time()
        mode.set(PlaybackMode::playing(now_ms, start_position, audio_start))
      }
      Playing(started_at, started_from, _) => {
        // Stop and preserve position
        let now_ms = @date.Date::now()
        let current_pos = started_from + (now_ms - started_at)
        mode.set(PlaybackMode::stopped(current_pos))
      }
    }
  }
  let is_playing = @signal.memo(fn() {
    match mode.get() {
      Stopped(_) => false
      Playing(_, _, _) => true
    }
  })
  @dom.button(
    dyn_class=fn() {
      if is_playing() {
        "px-8 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
      } else {
        "px-8 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
      }
    },
    on=@dom.events().click(on_play_pause),
    [@dom.text_dyn(fn() { if is_playing() { "■" } else { "▶" } })],
  )
}
