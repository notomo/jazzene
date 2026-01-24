///|
/// Render seed input control for random number generation
pub fn seed_input(seed : @signal.Signal[Int]) -> @luna_dom.DomNode {
  let on_input : @luna_dom.InputHandler = fn(e) {
    get_input_value(e)
    |> @js_global.parseInt
    |> Option::map(fn(x) { seed.set(x) })
    |> ignore
  }
  @luna_dom.div(class="flex items-center gap-2", [
    @luna_dom.label(class="text-sm text-slate-400", [@luna_dom.text("Seed:")]),
    @luna_dom.input(
      type_="number",
      class="w-24 px-3 py-2 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none text-center",
      attrs=[
        ("min", @luna_dom.Attr::AttrInt(0)),
        ("step", @luna_dom.Attr::AttrInt(1)),
      ],
      dyn_value=fn() { seed.get().to_string() },
      on=@luna_dom.events().input(on_input),
      placeholder="0",
    ),
  ])
}
