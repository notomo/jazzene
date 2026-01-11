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
  sounds : @signal.Signal[Array[@music.NoteValueSound]],
  total_duration : () -> @music.Duration,
  loop_state : LoopState,
  chord_parse_error : @signal.Signal[String?],
) -> Unit {

  // Build UI tree
  let app = @luna_dom.div(
    class="h-svh bg-gradient-to-br from-slate-950 to-slate-900 text-white grid grid-rows-[min-content_1fr]",
    [
      @luna_dom.div(
        class="h-wit p-2 bg-slate-800 rounded-xl shadow-2xl border-2 border-slate-700",
        attrs=[("aria-label", @luna_dom.Attr::AttrString("lead sheet"))],
        [
          @luna_dom.div([
            @luna_dom.div(class="flex gap-4 items-center p-1", [
              chord_progression_input(raw_chord_progression, chord_parse_error),
              seed_input(seed),
              bpm_input(bpm),
            ]),
            @luna_dom.div(class="flex gap-4 items-baseline p-1", [
              play_pause_button(is_playing, playback_position, total_duration),
              volume_input(volume),
              @luna_dom.div(class="flex gap-2 w-full items-center", [
                seek_bar(playback_position, total_duration),
                ab_loop(loop_state, total_duration),
              ]),
            ]),
          ]),
        ],
      ),
      @luna_dom.div(
        class="bg-slate-950 shadow-2xl border-slate-700 h-full grid grid-rows-[80%_20%]",
        attrs=[("aria-label", @luna_dom.Attr::AttrString("visualization"))],
        [
          note_display(sounds, playback_position, bpm, total_duration),
          keyboard(sounds, playback_position),
        ],
      ),
    ],
  )

  // Mount to DOM
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => el |> @luna_dom.DomElement::from_dom |> @luna_dom.render(app)
    None => ()
  }
}
