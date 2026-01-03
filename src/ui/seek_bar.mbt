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
  note_values : @signal.Signal[Array[@music.NoteValue]],
  mode : @signal.Signal[PlaybackMode],
  tempo : @signal.Signal[Int],
  frame_count : @signal.Signal[Int],
) -> @luna_dom.DomNode {
  // Computed values
  let total_duration_ms = @signal.memo(fn() {
    if note_values.get().length() > 0 {
      @audio.calculate_total_duration(note_values.get(), tempo.get())
    } else {
      0
    }
  })
  let position_ms = @signal.memo(fn() {
    // Reference frame_count to trigger updates every frame
    let _ = frame_count.get()
    match mode.get() {
      Stopped(position_ms=pos) => pos
      Playing(started_at_ms=started_at, started_from_position=started_from) => {
        let now_ms = @date.Date::now()
        started_from + (now_ms - started_at)
      }
    }
  })
  let has_notes = @signal.memo(fn() { note_values.get().length() > 0 })

  // Event handler
  let on_seek : @luna_dom.InputHandler = fn(e) {
    if note_values.get().length() == 0 {
      return
    }
    let target = e.target()
    let event_target = target.as_event_target()
    let value = event_target.as_any()._get("value").to_string()
    match @js_global.parseFloat(value) {
      Some(position_percent) => {
        let new_position_ms = (position_percent /
        100.0 *
        total_duration_ms().to_double()).to_int()
        match mode.get() {
          Stopped(..) =>
            // Just update position
            mode.set(PlaybackMode::stopped(new_position_ms))
          Playing(..) => {
            // Restart from new position
            let now_ms = @date.Date::now()
            mode.set(PlaybackMode::playing(now_ms, new_position_ms))
          }
        }
      }
      None => ()
    }
  }
  @luna_dom.div(class="flex gap-2 items-baseline bg-slate-800", [
    // Time display: "0:00 / 2:30"
    @luna_dom.div(
      class="flex justify-between text-sm text-slate-400 mb-2 text-nowrap",
      attrs=[("aria-label", @luna_dom.Attr::AttrString("time display"))],
      [
        @luna_dom.text_dyn(fn() {
          format_time(position_ms()) + " / " + format_time(total_duration_ms())
        }),
      ],
    ),

    // Range slider with Tailwind styling
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
        let total = total_duration_ms()
        if total == 0 {
          "0"
        } else {
          let percent = position_ms().to_double() / total.to_double() * 100.0
          percent.to_int().to_string()
        }
      },
      dyn_disabled=fn() { not(has_notes()) },
      on=@luna_dom.events().input(on_seek),
    ),
  ])
}
