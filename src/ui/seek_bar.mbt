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
pub fn seek_bar(
  is_playing : @signal.Signal[Bool],
  playback_position_ms : @signal.Signal[Int],
  total_duration : () -> Int,
  start_playing : (Int) -> Unit,
) -> @luna_dom.DomNode {
  let on_seek : @luna_dom.InputHandler = fn(e) {
    if total_duration() == 0 {
      return
    }
    let target = e.target()
    let event_target = target.as_event_target()
    let value = event_target.as_any()._get("value").to_string()
    match @js_global.parseFloat(value) {
      Some(position_percent) => {
        let new_position_ms = (position_percent /
        100.0 *
        total_duration().to_double()).to_int()
        if is_playing.get() {
          start_playing(new_position_ms)
        } else {
          playback_position_ms.set(new_position_ms)
        }
      }
      None => ()
    }
  }
  @luna_dom.div(class="flex gap-2 items-baseline bg-slate-800", [
    @luna_dom.div(
      class="flex justify-between text-sm text-slate-400 mb-2 text-nowrap",
      attrs=[("aria-label", @luna_dom.Attr::AttrString("time display"))],
      [
        @luna_dom.text_dyn(fn() {
          format_time(playback_position_ms.get()) +
          " / " +
          format_time(total_duration())
        }),
      ],
    ),
    @luna_dom.input(
      type_="range",
      class="w-full h-2 bg-slate-700 rounded-lg cursor-pointer accent-blue-500 disabled:opacity-50 disabled:cursor-not-allowed",
      attrs=[
        ("min", @luna_dom.Attr::AttrInt(0)),
        ("max", @luna_dom.Attr::AttrInt(100)),
        ("step", @luna_dom.Attr::AttrInt(1)),
        ("aria-label", @luna_dom.Attr::AttrString("playback position")),
      ],
      dyn_value=fn() {
        if total_duration() == 0 {
          "0"
        } else {
          let percent = playback_position_ms.get().to_double() /
            total_duration().to_double() *
            100.0
          percent.to_int().to_string()
        }
      },
      dyn_disabled=fn() { total_duration() == 0 },
      on=@luna_dom.events().input(on_seek),
    ),
  ])
}
