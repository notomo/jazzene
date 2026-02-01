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
        ("aria-label", @luna_dom.AttrValue::Static("key")),
        (
          "value",
          @luna_dom.AttrValue::Dynamic(fn() { key.get().root.to_string() }),
        ),
        (
          "change",
          @luna_dom.AttrValue::Handler(fn(e) {
            get_event_target_value(e)
            |> @music.ChordRoot::from_string
            |> Result::map(fn(root) {
              let k = @music.KeySignature::from_root(root)
              key.set(k)
              set_query_param("key", root.to_string())
            })
            |> ignore
          }),
        ),
      ],
      {
        let initial_key = key.get().root.to_string()
        all_roots.map(fn(root) {
          let name = root.to_string()
          let attrs : Array[(String, @luna_dom.AttrValue)] = [
            ("value", @luna_dom.AttrValue::Static(name)),
          ]
          if name == initial_key {
            attrs.push(("selected", @luna_dom.AttrValue::Static("selected")))
          }
          @luna_dom.create_element("option", attrs, [@luna_dom.text(name)])
        })
      },
    ),
  ])
}
