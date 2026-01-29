///|
/// Setup animation loop
pub fn setup_loop(
  is_playing : @signal.Signal[Bool],
  tick : (Double) -> Bool,
) -> Unit {
  let request_id : Ref[Int?] = { val: None }
  let previous_time : Ref[Double?] = { val: None }
  fn cancel() -> Unit {
    match request_id.val {
      Some(id) => {
        @js_dom.window().cancelAnimationFrame(id)
        request_id.val = None
        previous_time.val = None
      }
      None => ()
    }
  }

  let _ = @signal.effect(fn() {
    if not(is_playing.get()) {
      cancel()
      return
    }
    fn loop_fn(current_time : Double) -> Unit {
      let elapsed_ms = current_time - previous_time.val.unwrap_or(current_time)
      let stopped = tick(elapsed_ms)
      if stopped {
        cancel()
        is_playing.set(false)
        return
      }
      request_id.val = Some(@js_dom.window().requestAnimationFrame(loop_fn))
      previous_time.val = Some(current_time)
    }

    request_id.val = Some(@js_dom.window().requestAnimationFrame(loop_fn))
  })

}

///|
/// Render the application UI
pub fn render(
  is_playing : @signal.Signal[Bool],
  playback_position : @signal.Signal[@music.Duration],
  volume : @signal.Signal[Double],
  bpm : @signal.Signal[Int],
  raw_chord_progression : @signal.Signal[String],
  seed : @signal.Signal[Int],
  measure_count : @signal.Signal[Int],
  sounds : @signal.Signal[Array[@music.NoteValueSound]],
  total_duration : () -> @music.Duration,
  loop_enabled : @signal.Signal[Bool],
  loop_a_time : @signal.Signal[@music.Duration],
  loop_b_time : @signal.Signal[@music.Duration?],
  chord_parse_error : @signal.Signal[String?],
  measures : () -> Array[@music.Measure],
  key : @signal.Signal[@music.KeySignature],
) -> Unit {
  let app = @luna_dom.div(
    class="flex flex-col h-dvh overflow-hidden w-dvw bg-gradient-to-br from-slate-950 to-slate-900 text-white",
    [
      @luna_dom.div(
        class="p-2 bg-slate-800 border-2 border-slate-700",
        attrs=[("aria-label", @luna_dom.Attr::AttrString("lead sheet"))],
        [
          @luna_dom.div([
            @luna_dom.div(class="flex gap-4 items-center p-1", [
              key_select(key),
              chord_progression_input(raw_chord_progression, chord_parse_error),
              seed_input(seed),
              measure_count_input(measure_count),
              bpm_input(bpm),
            ]),
            @luna_dom.div(class="flex gap-4 items-baseline p-1", [
              play_pause_button(is_playing, playback_position, total_duration),
              volume_input(volume),
              @luna_dom.div(class="flex gap-2 w-full items-center", [
                seek_bar(playback_position, total_duration),
                ab_loop(loop_enabled, loop_a_time, loop_b_time, total_duration),
              ]),
            ]),
          ]),
        ],
      ),
      @luna_dom.div(
        class="flex h-full min-h-0",
        attrs=[("aria-label", @luna_dom.Attr::AttrString("visualization"))],
        [
          @luna_dom.div(class="flex-2 min-h-0", [
            @sheet.lead_sheet(measures, playback_position, bpm, key),
          ]),
          @luna_dom.div(
            class="flex flex-col flex-3 min-h-0",
            attrs=[("aria-label", @luna_dom.Attr::AttrString("visualization"))],
            [
              @piano_roll.note_display(
                sounds, playback_position, bpm, total_duration,
              ),
              @piano_roll.keyboard(sounds, playback_position),
            ],
          ),
        ],
      ),
    ],
  )
  @js_dom.document().getElementById("app")
  |> Option::map(fn(e) {
    @luna_dom.DomElement::from_dom(e) |> @luna_dom.render(app)
  })
  |> ignore
}
