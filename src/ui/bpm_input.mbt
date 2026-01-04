///|
/// Render BPM input control
pub fn bpm_input(bpm : @signal.Signal[Int]) -> @luna_dom.DomNode {
  let on_input : @luna_dom.InputHandler = fn(e) {
    let target = e.target()
    let event_target = target.as_event_target()
    let value = event_target.as_any()._get("value").to_string()
    match @js_global.parseInt(value) {
      Some(x) => if x >= 30 && x <= 300 { bpm.set(x) }
      None => ()
    }
  }
  @luna_dom.div(class="flex items-center gap-2", [
    @luna_dom.label(class="text-sm text-slate-400", [@luna_dom.text("BPM:")]),
    @luna_dom.input(
      type_="number",
      class="w-20 px-3 py-2 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none text-center",
      attrs=[
        ("min", @luna_dom.Attr::AttrInt(30)),
        ("max", @luna_dom.Attr::AttrInt(300)),
      ],
      dyn_value=fn() { bpm.get().to_string() },
      on=@luna_dom.events().input(on_input),
    ),
  ])
}
