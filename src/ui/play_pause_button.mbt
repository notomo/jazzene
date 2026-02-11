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
fn play_pause_button(
  is_playing : @signal.Signal[Bool],
  playback_position : @signal.Signal[@music.Duration],
  total_duration : () -> @music.Duration,
) -> @luna_dom.DomNode {
  fn toggle() -> Unit {
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

  add_spacebar_listener(toggle)
  @luna_dom.button(
    class="w-10 h-10 bg-blue-600 hover:bg-blue-500 text-white rounded-lg font-semibold transition-colors shadow-lg flex items-center justify-center text-sm",
    on=@luna_dom.events().click(fn(_) { toggle() }),
    [@luna_dom.text_dyn(fn() { if is_playing.get() { "■" } else { "▶" } })],
  )
}
