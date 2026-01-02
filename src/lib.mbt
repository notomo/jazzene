///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  // Create audio context
  let audio_ctx = @web_audio.AudioContext::new()

  // Individual signals (sources of truth)
  let mode : @signal.Signal[@ui.PlaybackMode] = @signal.signal(
    @ui.PlaybackMode::stopped(0),
  )
  let note_values : @signal.Signal[Array[@music.NoteValue]] = @signal.signal([])
  let chord_input = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let tempo = @signal.signal(120)
  let volume = @signal.signal(0.3)
  let frame_count = @signal.signal(0) // Incremented every frame for UI updates

  // Reactive note generation when chord input changes
  let _ = @signal.effect(fn() {
    let input = chord_input.get()
    if input.length() == 0 {
      note_values.set([])
    } else {
      let chords = @music.parse_chord_progression(input)
      if chords.length() > 0 {
        let settings = @music.ImprovisationSettings::default()
        let generated = @music.generate_improvisation(chords, settings)
        note_values.set(generated)
      } else {
        note_values.set([])
      }
    }
  })

  // Tick-based main loop
  fn tick() -> Unit {
    // Update frame counter to trigger UI reactivity
    frame_count.update(fn(n) { n + 1 })
    match mode.get() {
      Stopped(..) => () // No-op when stopped
      Playing(started_at_ms~, started_from_position~, ..) => {
        let now_ms = @date.Date::now()
        let elapsed_ms = now_ms - started_at_ms
        let current_pos = started_from_position + elapsed_ms

        // Schedule audio in lookahead window
        @audio.schedule_notes_in_window(
          audio_ctx,
          note_values.get(),
          tempo.get(),
          current_pos,
          100,
          volume.get(),
        )

        // Check for end of playback
        let total_duration = if note_values.get().length() > 0 {
          @audio.calculate_total_duration(note_values.get(), tempo.get())
        } else {
          0
        }
        if current_pos >= total_duration {
          mode.set(@ui.PlaybackMode::stopped(total_duration))
        }
      }
    }
  }

  // Start requestAnimationFrame loop
  fn start_tick_loop() -> Unit {
    fn loop_fn(_time : Double) -> Unit {
      tick()
      @js_dom.window().requestAnimationFrame(loop_fn) |> ignore
    }

    @js_dom.window().requestAnimationFrame(loop_fn) |> ignore
  }

  start_tick_loop()

  // Render app
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let app = @dom.div(
        class="h-screen bg-gradient-to-br from-slate-950 to-slate-900 text-white grid grid-rows-[1fr_1fr]",
        [
          @dom.div(
            class="bg-slate-800 p-4 rounded-xl shadow-2xl border-2 border-slate-700",
            attrs=[("aria-label", @dom.Attr::AttrString("lead sheet"))],
            [
              @dom.div([
                @ui.render_chord_input(chord_input),
                @dom.div(class="flex gap-4 items-center", [
                  @ui.render_play_pause_button(
                    note_values, mode, audio_ctx, tempo,
                  ),
                  @ui.render_volume_control(volume),
                  @ui.render_bpm_input(tempo),
                  @dom.div(class="flex-1", [
                    @ui.render_seek_bar(
                      note_values, mode, tempo, audio_ctx, frame_count,
                    ),
                  ]),
                ]),
              ]),
            ],
          ),
          @dom.div(
            class="bg-slate-950 shadow-2xl border-slate-700 h-fit flex flex-col",
            attrs=[("aria-label", @dom.Attr::AttrString("visualization"))],
            [
              @ui.render_falling_notes_canvas(
                note_values, mode, tempo, frame_count, audio_ctx,
              ),
              @ui.render_keyboard_canvas(note_values, mode, tempo, frame_count),
            ],
          ),
        ],
      )
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}
