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
  loop_a_measure : @signal.Signal[Int],
  loop_b_measure : @signal.Signal[Int?],
  chord_parse_error : @signal.Signal[String?],
  measures : () -> Array[@music.Measure],
  key : @signal.Signal[@music.KeySignature],
  time_signature : @signal.Signal[@music.TimeSignature],
  display_mode : @signal.Signal[DisplayMode],
) -> Unit {
  let app = @luna_dom.div(
    class="flex flex-col h-dvh overflow-hidden w-dvw bg-gradient-to-br from-slate-950 to-slate-900 text-white touch-manipulation",
    [
      @luna_dom.div(
        class="p-2 bg-slate-800 border-2 border-slate-700",
        attrs=[("aria-label", @luna_dom.Attr::AttrString("lead sheet"))],
        [
          @luna_dom.div(class="flex gap-4 items-center p-1", [
            time_signature_select(time_signature),
            key_select(key),
            chord_progression_input(raw_chord_progression, chord_parse_error),
            seed_input(seed),
            measure_count_input(measure_count),
            bpm_input(bpm),
          ]),
        ],
      ),
      @luna_dom.div(
        dyn_class=fn() {
          let mode = display_mode.get()
          match (mode.show_sheet(), mode.show_piano_roll()) {
            (true, false) => "flex h-full min-h-0"
            (false, true) => "flex justify-center h-full min-h-0"
            _ => "flex h-full min-h-0"
          }
        },
        attrs=[("aria-label", @luna_dom.Attr::AttrString("visualization"))],
        [
          @luna_dom.div(
            dyn_class=fn() {
              match display_mode.get() {
                Sheet => "w-full min-h-0 overflow-auto"
                Sheet_PianoRoll => "flex-1 min-h-0 overflow-auto"
                PianoRoll => "hidden"
              }
            },
            attrs=[("id", @luna_dom.Attr::AttrString("lead-sheet-container"))],
            [
              @luna_dom.div(
                dyn_class=fn() {
                  match display_mode.get() {
                    Sheet => "w-4/5 mx-auto"
                    _ => ""
                  }
                },
                [
                  @sheet.lead_sheet(
                    measures, playback_position, bpm, key, time_signature,
                  ),
                ],
              ),
            ],
          ),
          @luna_dom.div(
            dyn_class=fn() {
              match display_mode.get() {
                PianoRoll => "flex flex-col flex-1 min-h-0"
                Sheet_PianoRoll => "flex flex-col flex-1 min-h-0"
                Sheet => "hidden"
              }
            },
            attrs=[("aria-label", @luna_dom.Attr::AttrString("visualization"))],
            [
              @piano_roll.note_display(
                sounds, playback_position, bpm, total_duration, time_signature,
              ),
              @piano_roll.keyboard(sounds, playback_position),
            ],
          ),
        ],
      ),
      @luna_dom.div(
        class="grid grid-cols-[1fr_auto_1fr] items-center gap-4 px-3 py-1.5 bg-slate-800 border-t-2 border-slate-700",
        [
          @luna_dom.div(class="flex items-center gap-2 justify-self-end", [
            volume_input(volume),
          ]),
          play_pause_button(is_playing, playback_position, total_duration),
          @luna_dom.div(class="flex items-center gap-3 w-full", [
            ab_loop(loop_a_measure, loop_b_measure, fn() { measure_count.get() }),
            @luna_dom.div(class="ml-auto", [display_mode_select(display_mode)]),
          ]),
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
