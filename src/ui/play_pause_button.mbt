///|
/// Render play/pause button
pub fn render_play_pause_button(
  note_values : @signal.Signal[Array[@music.NoteValue]],
  mode : @signal.Signal[PlaybackMode],
  tempo : @signal.Signal[Int],
) -> @luna_dom.DomNode {
  // Event handler
  let on_play_pause : @luna_dom.MouseHandler = fn(_) {
    if note_values.get().length() == 0 {
      return
    }
    match mode.get() {
      Stopped(position_ms~) => {
        // Calculate total duration
        let total_duration = @audio.calculate_total_duration(
          note_values.get(),
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
        mode.set(PlaybackMode::playing(now_ms, start_position))
      }
      Playing(started_at_ms=started_at, started_from_position=started_from) => {
        // Stop and preserve position
        let now_ms = @date.Date::now()
        let current_pos = started_from + (now_ms - started_at)
        mode.set(PlaybackMode::stopped(current_pos))
      }
    }
  }
  let is_playing = @signal.memo(fn() {
    match mode.get() {
      Stopped(..) => false
      Playing(..) => true
    }
  })
  @luna_dom.button(
    dyn_class=fn() {
      if is_playing() {
        "px-4 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
      } else {
        "px-4 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
      }
    },
    on=@luna_dom.events().click(on_play_pause),
    [@luna_dom.text_dyn(fn() { if is_playing() { "■" } else { "▶" } })],
  )
}
