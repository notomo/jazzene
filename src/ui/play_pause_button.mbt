///|
/// Render play/pause button
fn play_pause_button(
  is_playing : @signal.Signal[Bool],
  playback_position : @signal.Signal[@music.Duration],
  total_duration : () -> @music.Duration,
) -> @luna_dom.DomNode {
  let on_click : @luna_dom.MouseHandler = fn(_) {
    if is_playing.get() {
      is_playing.set(false)
      return
    }
    // If at the end, restart from beginning
    let position = playback_position.get()
    let start_position = if position >= total_duration() {
      @music.Duration::from_milliseconds(0)
    } else {
      position
    }
    is_playing.set(true)
    playback_position.set(start_position)
  }

  @luna_dom.button(
    class="w-12 h-12 bg-blue-600 hover:bg-blue-500 text-white rounded-lg font-semibold transition-colors shadow-lg flex items-center justify-center",
    on=@luna_dom.events().click(on_click),
    [@luna_dom.text_dyn(fn() { if is_playing.get() { "■" } else { "▶" } })],
  )
}
