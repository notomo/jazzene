///|
/// Extract target.value from a JS event object
extern "js" fn get_event_target_value(e : @js.Any) -> String =
  #|(e) => e.target.value

///|
/// Render key selection dropdown
fn key_select(key : @signal.Signal[@music.KeySignature]) -> @luna_dom.DomNode {
  let all_roots = @music.KeySignature::all_roots()
  @luna_dom.div(class="flex items-center gap-2", [
    @luna_dom.label(class="text-sm text-slate-400", [@luna_dom.text("Key:")]),
    @luna_dom.create_element(
      "select",
      [
        (
          "class",
          @luna_dom.AttrValue::Static(
            "px-3 py-2 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none",
          ),
        ),
        (
          "value",
          @luna_dom.AttrValue::Dynamic(fn() { key.get().root.to_string() }),
        ),
        (
          "change",
          @luna_dom.AttrValue::Handler(fn(e) {
            let value = get_event_target_value(e)
            match @music.ChordRoot::from_string(value) {
              Ok(root) => key.set(@music.KeySignature::from_root(root))
              Err(_) => ()
            }
          }),
        ),
      ],
      all_roots.map(fn(root) {
        let name = root.to_string()
        @luna_dom.create_element(
          "option",
          [("value", @luna_dom.AttrValue::Static(name))],
          [@luna_dom.text(name)],
        )
      }),
    ),
  ])
}
