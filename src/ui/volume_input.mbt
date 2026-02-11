///|
/// Render volume control with popup
fn volume_input(volume : @signal.Signal[Double]) -> @luna_dom.DomNode {
  let show_popup = @signal.signal(false)
  let on_input : @luna_dom.InputHandler = fn(e) {
    get_input_value(e)
    |> @js_global.parseFloat
    |> Option::map(fn(percent) { volume.set(percent / 100.0) })
    |> ignore
  }

  @luna_dom.div(class="relative", [
    @luna_dom.button(
      class="h-10 w-10 flex items-center justify-center bg-slate-700 hover:bg-slate-600 rounded-lg transition-colors shadow-lg text-sm",
      on=@luna_dom.events().click(fn(_) { show_popup.update(fn(v) { !v }) }),
      attrs=[("aria-label", @luna_dom.Attr::AttrString("Volume control"))],
      [@luna_dom.text("🔊")],
    ),
    @luna_dom.div(
      dyn_class=fn() {
        if show_popup.get() {
          "absolute z-10 top-full left-1/2 -translate-x-1/2 mt-2 bg-slate-800 p-3 rounded-lg shadow-xl border border-slate-600"
        } else {
          "hidden"
        }
      },
      [
        @luna_dom.input(
          type_="range",
          class="h-32 w-12 accent-blue-500 cursor-pointer [writing-mode:vertical-lr] [direction:rtl]",
          attrs=[
            ("min", @luna_dom.Attr::AttrInt(0)),
            ("max", @luna_dom.Attr::AttrInt(100)),
            ("step", @luna_dom.Attr::AttrInt(1)),
            ("orient", @luna_dom.Attr::AttrString("vertical")),
            ("aria-label", @luna_dom.Attr::AttrString("Volume")),
          ],
          dyn_value=fn() { (volume.get() * 100.0).to_int().to_string() },
          on=@luna_dom.events().input(on_input),
        ),
      ],
    ),
  ])
}
