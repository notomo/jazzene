///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  // Create audio context
  let audio_ctx = @audio.AudioContext::new()

  // Individual signals (sources of truth)
  let mode : @signal.Signal[@ui.PlaybackMode] = @signal.signal(
    @ui.PlaybackMode::stopped(0),
  )
  let notes : @signal.Signal[Array[@music.Note]] = @signal.signal([])
  let chord_input = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let tempo = @signal.signal(120)
  let volume = @signal.signal(0.3)
  let is_muted = @signal.signal(false)

  // Reactive note generation when chord input changes
  let _ = @signal.effect(fn() {
    let input = chord_input.get()
    if input.length() == 0 {
      notes.set([])
    } else {
      let chords = @music.parse_chord_progression(input)
      if chords.length() > 0 {
        let settings = @music.ImprovisationSettings::default()
        let generated_notes = @music.generate_improvisation(chords, settings)
        notes.set(generated_notes)
      } else {
        notes.set([])
      }
    }
  })

  // Tick-based main loop
  fn tick() -> Unit {
    match mode.get() {
      Stopped(_) => () // No-op when stopped
      Playing(started_at_ms, started_from_position, _audio_start) => {
        let now_ms = @date.Date::now()
        let elapsed_ms = now_ms - started_at_ms
        let current_pos = started_from_position + elapsed_ms

        // Schedule audio in lookahead window
        @audio.schedule_notes_in_window(
          audio_ctx,
          notes.get(),
          tempo.get(),
          current_pos,
          100,
        )

        // Check for end of playback
        let total_duration = if notes.get().length() > 0 {
          @audio.calculate_total_duration(notes.get(), tempo.get())
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
        class="h-screen bg-gradient-to-br from-slate-950 to-slate-900 text-white p-1 flex flex-col overflow-hidden",
        [
          @dom.div(
            class="lead-sheet bg-slate-800 p-8 rounded-xl shadow-2xl border-2 border-slate-700",
            [
              @dom.div(class="space-y-4", [
                // Chord input textarea
                @ui.render_chord_input(chord_input),
                // Playback controls
                @dom.div(class="flex gap-4 items-center", [
                  @ui.render_play_pause_button(notes, mode, audio_ctx),
                  @ui.render_volume_control(volume, is_muted),
                  @ui.render_bpm_input(tempo),
                ]),
                // seek_bar
                @dom.div(class="flex-1", [
                  @ui.render_seek_bar(notes, mode, tempo, audio_ctx),
                ]),
              ]),
            ],
          ),
          @dom.div(
            class="bg-slate-950 rounded-xl shadow-2xl border-2 border-slate-700 overflow-hidden flex-1 mt-2 flex flex-col",
            [@ui.render_falling_notes(), @ui.render_keyboard()],
          ),
        ],
      )
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}
