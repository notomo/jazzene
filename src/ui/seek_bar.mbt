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
  notes : @signal.Signal[Array[@music.Note]],
  mode : @signal.Signal[PlaybackMode],
  tempo : @signal.Signal[Int],
  audio_ctx : @audio.AudioContext,
) -> @dom.DomNode {
  // Computed values
  let total_duration_ms = @signal.memo(fn() {
    if notes.get().length() > 0 {
      @audio.calculate_total_duration(notes.get(), tempo.get())
    } else {
      0
    }
  })
  let position_ms = @signal.memo(fn() {
    match mode.get() {
      Stopped(pos) => pos
      Playing(started_at, started_from, _) => {
        let now_ms = @date.Date::now()
        started_from + (now_ms - started_at)
      }
    }
  })
  let has_notes = @signal.memo(fn() { notes.get().length() > 0 })

  // Event handler
  let on_seek : @dom.InputHandler = fn(e) {
    if notes.get().length() == 0 {
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
          Stopped(_) =>
            // Just update position
            mode.set(PlaybackMode::stopped(new_position_ms))
          Playing(_, _, _) => {
            // Restart from new position
            let now_ms = @date.Date::now()
            let audio_start = audio_ctx.current_time()
            mode.set(
              PlaybackMode::playing(now_ms, new_position_ms, audio_start),
            )
          }
        }
      }
      None => ()
    }
  }
  @dom.div(class="p-4 bg-slate-800", [
    // Time display: "0:00 / 2:30"
    @dom.div(
      class="flex justify-between text-sm text-slate-400 mb-2",
      attrs=[("aria-label", @dom.Attr::AttrString("time display"))],
      [
        @dom.text_dyn(fn() {
          format_time(position_ms()) + " / " + format_time(total_duration_ms())
        }),
      ],
    ),

    // Range slider with Tailwind styling
    @dom.input(
      type_="range",
      class="w-full h-2 bg-slate-700 rounded-lg cursor-pointer accent-blue-500 disabled:opacity-50 disabled:cursor-not-allowed",
      attrs=[
        ("min", @dom.Attr::AttrInt(0)),
        ("max", @dom.Attr::AttrInt(100)),
        ("step", @dom.Attr::AttrInt(1)),
        ("aria-label", @dom.Attr::AttrString("playback position")),
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
      on=@dom.events().input(on_seek),
    ),
  ])
}
