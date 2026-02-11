///|
/// Shared select dropdown component
fn select_input(
  label~ : String,
  aria_label~ : String,
  options~ : Array[String],
  initial~ : String,
  on_change~ : (String) -> Unit,
  value~ : () -> String,
) -> @luna_dom.DomNode {
  @luna_dom.div(class="flex items-center gap-2", [
    @luna_dom.label(class="text-sm text-slate-400", [@luna_dom.text(label)]),
    @luna_dom.create_element(
      "select",
      [
        (
          "class",
          @luna_dom.AttrValue::Static(
            "px-3 py-2 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none",
          ),
        ),
        ("aria-label", @luna_dom.AttrValue::Static(aria_label)),
        ("value", @luna_dom.AttrValue::Dynamic(value)),
        (
          "change",
          @luna_dom.AttrValue::Handler(fn(e) {
            on_change(get_event_target_value(e))
          }),
        ),
      ],
      options.map(fn(name) {
        let attrs : Array[(String, @luna_dom.AttrValue)] = [
          ("value", @luna_dom.AttrValue::Static(name)),
        ]
        if name == initial {
          attrs.push(("selected", @luna_dom.AttrValue::Static("selected")))
        }
        @luna_dom.create_element("option", attrs, [@luna_dom.text(name)])
      }),
    ),
  ])
}
