///|
/// Render play/pause button
pub fn render_play_pause_button(
  on_play_pause : () -> Unit,
  is_playing : () -> Bool,
) -> @dom.DomNode {
  @dom.button(
    dyn_class=fn() {
      if is_playing() {
        "px-8 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
      } else {
        "px-8 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
      }
    },
    on=@dom.events().click(fn(_) { on_play_pause() }),
    [@dom.text_dyn(fn() { if is_playing() { "Stop" } else { "Play" } })],
  )
}
