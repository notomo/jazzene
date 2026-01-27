///|
/// Render play/pause button
pub fn play_pause_button(
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
    dyn_class=fn() {
      cn([
        "px-4 py-3 text-white rounded-lg font-semibold transition-colors shadow-lg",
        if is_playing.get() {
          "bg-red-600 hover:bg-red-700"
        } else {
          "bg-green-600 hover:bg-green-700"
        },
      ])
    },
    on=@luna_dom.events().click(on_click),
    [@luna_dom.text_dyn(fn() { if is_playing.get() { "■" } else { "▶" } })],
  )
}
