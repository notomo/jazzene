///|
/// Render volume control with popup
pub fn render_volume_control(volume : @signal.Signal[Double]) -> @dom.DomNode {
  // Volume popup state
  let show_volume_popup = @signal.signal(false)

  // Event handlers
  let on_volume_change : @dom.InputHandler = fn(e) {
    let target = e.target()
    let event_target = target.as_event_target()
    let value = event_target.as_any()._get("value").to_string()
    match @js_global.parseFloat(value) {
      Some(percent) => volume.set(percent / 100.0)
      None => ()
    }
  }
  @dom.div(class="relative", [
    @dom.button(
      class="p-3 bg-slate-700 hover:bg-slate-600 rounded-lg transition-colors shadow-lg",
      on=@dom.events().click(fn(_) { show_volume_popup.update(fn(v) { !v }) }),
      attrs=[("aria-label", @dom.Attr::AttrString("Volume control"))],
      [@dom.text("🔊")],
    ),
    // Volume popup (vertical slider)
    @dom.div(
      dyn_class=fn() {
        if show_volume_popup.get() {
          "absolute z-10 top-full left-1/2 -translate-x-1/2 mt-2 bg-slate-800 p-3 rounded-lg shadow-xl border border-slate-600"
        } else {
          "hidden"
        }
      },
      [
        @dom.input(
          type_="range",
          class="h-32 w-12 accent-blue-500 cursor-pointer [-webkit-appearance:slider-vertical] [writing-mode:vertical-lr] rotate-180",
          attrs=[
            ("min", @dom.Attr::AttrInt(0)),
            ("max", @dom.Attr::AttrInt(100)),
            ("step", @dom.Attr::AttrInt(1)),
            ("orient", @dom.Attr::AttrString("vertical")),
            ("aria-label", @dom.Attr::AttrString("Volume")),
          ],
          dyn_value=fn() { (volume.get() * 100.0).to_int().to_string() },
          on=@dom.events().input(on_volume_change),
        ),
      ],
    ),
  ])
}
