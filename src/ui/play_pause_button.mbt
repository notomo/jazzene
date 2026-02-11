///|
extern "js" fn add_spacebar_listener(callback : () -> Unit) -> Unit =
  #|(callback) => {
  #|  document.addEventListener('keydown', (e) => {
  #|    if (e.code !== 'Space') return;
  #|    const tag = document.activeElement?.tagName;
  #|    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT' || tag === 'BUTTON') return;
  #|    e.preventDefault();
  #|    callback();
  #|  });
  #|}

///|
/// Render play/pause button
fn play_pause_button(is_playing : @signal.Signal[Bool]) -> @luna_dom.DomNode {
  fn toggle() -> Unit {
    is_playing.update(fn(v) { not(v) })
  }

  add_spacebar_listener(toggle)
  @luna_dom.button(
    class="w-10 h-10 bg-blue-600 hover:bg-blue-500 text-white rounded-lg font-semibold transition-colors shadow-lg flex items-center justify-center text-sm",
    on=@luna_dom.events().click(fn(_) { toggle() }),
    [@luna_dom.text_dyn(fn() { if is_playing.get() { "■" } else { "▶" } })],
  )
}
