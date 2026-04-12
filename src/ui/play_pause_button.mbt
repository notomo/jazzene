///|
fn add_spacebar_listener(callback : () -> Unit) -> Unit {
  @js_dom.document()
  .as_event_target()
  .addEventListener("keydown", fn(e) {
    let code : String = e._get("code").cast()
    if code != "Space" {
      return
    }
    let active_el : @js_dom.Element? = @js.identity_option(
      @js_dom.document().as_any()._get("activeElement"),
    )
    let tag = match active_el {
      Some(el) => el.tagName()
      None => ""
    }
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT" || tag == "BUTTON" {
      return
    }
    e._call("preventDefault", []) |> ignore
    callback()
  })
}

///|
/// Render play/pause button
fn play_pause_button(is_playing : @signals.Signal[Bool]) -> @luna_dom.DomNode {
  fn toggle() -> Unit {
    is_playing.update(fn(v) { !v })
  }

  add_spacebar_listener(toggle)
  @luna_dom.button(
    class="w-8 lg:w-10 bg-blue-600 hover:bg-blue-500 text-white rounded-lg font-semibold transition-colors shadow-lg flex items-center justify-center text-sm shrink-0",
    on=@luna_dom.events().click(fn(_) { toggle() }),
  ) <| [
    @luna_dom.text_dyn(fn() { if is_playing.get() { "■" } else { "▶" } }),
  ]
}
