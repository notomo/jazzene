///|
/// Render time signature selection dropdown
fn time_signature_select(
  time_signature : @signal.Signal[@music.TimeSignature],
) -> @luna_dom.DomNode {
  let all_time_signatures = @music.TimeSignature::all()

  @luna_dom.div(class="flex items-center gap-2", [
    @luna_dom.label(class="text-sm text-slate-400", [@luna_dom.text("Time:")]),
    @luna_dom.create_element(
      "select",
      [
        (
          "class",
          @luna_dom.AttrValue::Static(
            "px-3 py-2 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none",
          ),
        ),
        ("aria-label", @luna_dom.AttrValue::Static("time signature")),
        (
          "value",
          @luna_dom.AttrValue::Dynamic(fn() { time_signature.get().to_string() }),
        ),
        (
          "change",
          @luna_dom.AttrValue::Handler(fn(e) {
            get_event_target_value(e)
            |> @music.TimeSignature::from_string
            |> Result::map(fn(ts) {
              time_signature.set(ts)
              set_query_param("time", ts.to_string())
            })
            |> ignore
          }),
        ),
      ],
      {
        let initial_ts = time_signature.get().to_string()
        all_time_signatures.map(fn(ts) {
          let name = ts.to_string()
          let attrs : Array[(String, @luna_dom.AttrValue)] = [
            ("value", @luna_dom.AttrValue::Static(name)),
          ]
          if name == initial_ts {
            attrs.push(("selected", @luna_dom.AttrValue::Static("selected")))
          }
          @luna_dom.create_element("option", attrs, [@luna_dom.text(name)])
        })
      },
    ),
  ])
}
