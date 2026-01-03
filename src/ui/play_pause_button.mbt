///|
/// Render play/pause button
pub fn render_play_pause_button(
  note_values : @signal.Signal[Array[@music.NoteValue]],
  is_playing : @signal.Signal[Bool],
  playback_position_ms : @signal.Signal[Int],
  tempo : @signal.Signal[Int],
  start_playing : (Int) -> Unit,
) -> @luna_dom.DomNode {
  // Event handler
  let on_play_pause : @luna_dom.MouseHandler = fn(_) {
    if note_values.get().length() == 0 {
      return
    }
    if is_playing.get() {
      is_playing.set(false)
    } else {
      // Calculate total duration
      let total_duration = @audio.calculate_total_duration(
        note_values.get(),
        tempo.get(),
      )
      // If at the end, restart from beginning
      let position = playback_position_ms.get()
      let start_position = if position >= total_duration { 0 } else { position }
      start_playing(start_position)
    }
  }
  @luna_dom.button(
    dyn_class=fn() {
      if is_playing.get() {
        "px-4 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
      } else {
        "px-4 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
      }
    },
    on=@luna_dom.events().click(on_play_pause),
    [@luna_dom.text_dyn(fn() { if is_playing.get() { "■" } else { "▶" } })],
  )
}
