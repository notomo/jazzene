///|
/// Format milliseconds as "M:SS"
fn format_time(ms : Int) -> String {
  let total_seconds = ms / 1000
  let minutes = total_seconds / 60
  let seconds = total_seconds % 60
  minutes.to_string() +
  ":" +
  (if seconds < 10 { "0" } else { "" }) +
  seconds.to_string()
}

///|
/// Render seek_bar UI component
pub fn render_seek_bar(
  position_ms : () -> Int,
  total_duration_ms : () -> Int,
  has_notes : () -> Bool,
  on_seek : (Double) -> Unit,
) -> @dom.DomNode {
  @dom.div(class="p-4 bg-slate-800", [
    // Time display: "0:00 / 2:30"
    @dom.div(class="flex justify-between text-sm text-slate-400 mb-2", [
      @dom.text_dyn(fn() {
        format_time(position_ms()) + " / " + format_time(total_duration_ms())
      }),
    ]),

    // Range slider with Tailwind styling
    @dom.input(
      type_="range",
      class="w-full h-2 bg-slate-700 rounded-lg cursor-pointer accent-blue-500 disabled:opacity-50 disabled:cursor-not-allowed",
      attrs=[
        ("min", @dom.Attr::AttrInt(0)),
        ("max", @dom.Attr::AttrInt(100)),
        ("step", @dom.Attr::AttrInt(1)),
      ],
      dyn_value=fn() {
        let total = total_duration_ms()
        if total == 0 {
          "0"
        } else {
          let percent = position_ms().to_double() / total.to_double() * 100.0
          percent.to_int().to_string()
        }
      },
      dyn_disabled=fn() { not(has_notes()) },
      on=@dom.events().change(fn(e) {
        let target = e.target()
        let event_target = target.as_event_target()
        let value = event_target.as_any()._get("value").to_string()
        match @js_global.parseFloat(value) {
          Some(percent) => on_seek(percent)
          None => ()
        }
      }),
    ),
  ])
}
