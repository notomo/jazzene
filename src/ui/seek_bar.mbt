///|
/// Render seek_bar UI component
fn seek_bar(
  playback_position : @signal.Signal[@music.Duration],
  total_duration : () -> @music.Duration,
) -> @luna_dom.DomNode {
  let on_seek : @luna_dom.InputHandler = fn(e) {
    get_input_value(e)
    |> @js_global.parseFloat
    |> Option::map(fn(percent) {
      playback_position.set(
        @music.Duration::from_milliseconds(
          percent / 100.0 * total_duration().to_milliseconds(),
        ),
      )
    })
    |> ignore
  }
  @luna_dom.div(class="w-full flex gap-2 items-baseline bg-slate-800", [
    @luna_dom.div(
      class="flex justify-between text-sm text-slate-400 mb-2 text-nowrap",
      attrs=[("aria-label", @luna_dom.Attr::AttrString("time display"))],
      [
        @luna_dom.text_dyn(fn() {
          playback_position.get().format() + " / " + total_duration().format()
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
        let percent = playback_position.get().to_milliseconds() /
          total_duration().to_milliseconds() *
          100.0
        percent.to_int().to_string()
      },
      on=@luna_dom.events().input(on_seek),
    ),
  ])
}
