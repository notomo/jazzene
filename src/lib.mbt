///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  // Create audio context
  let audio_ctx = @audio.AudioContext::new()

  // Individual signals (sources of truth)
  let mode : @signal.Signal[PlaybackMode] = @signal.signal(
    PlaybackMode::Stopped(0),
  )
  let notes : @signal.Signal[Array[@music.Note]] = @signal.signal([])
  let chord_input = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let tempo = @signal.signal(120)
  let volume = @signal.signal(0.3)
  let is_muted = @signal.signal(false)

  // Computed total duration (derived value using memo)
  let total_duration_ms = @signal.memo(fn() {
    if notes.get().length() > 0 {
      @audio.calculate_total_duration(notes.get(), tempo.get())
    } else {
      0
    }
  })

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
        if current_pos >= total_duration_ms() {
          mode.set(PlaybackMode::Stopped(total_duration_ms()))
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

  // Event handlers
  fn on_play_pause() -> Unit {
    if notes.get().length() == 0 {
      return
    }
    match mode.get() {
      Stopped(position_ms) => {
        // Start playing from current position
        let now_ms = @date.Date::now()
        let audio_start = audio_ctx.current_time()
        mode.set(PlaybackMode::Playing(now_ms, position_ms, audio_start))
      }
      Playing(_, started_from, _) => {
        // Stop and preserve position
        let now_ms = @date.Date::now()
        let current_pos = started_from + (now_ms - started_from)
        mode.set(PlaybackMode::Stopped(current_pos))
      }
    }
  }

  fn on_seek(position_percent : Double) -> Unit {
    if notes.get().length() == 0 {
      return
    }
    let new_position_ms = (position_percent /
    100.0 *
    total_duration_ms().to_double()).to_int()
    match mode.get() {
      Stopped(_) =>
        // Just update position
        mode.set(PlaybackMode::Stopped(new_position_ms))
      Playing(_, _, _) => {
        // Restart from new position
        let now_ms = @date.Date::now()
        let audio_start = audio_ctx.current_time()
        mode.set(PlaybackMode::Playing(now_ms, new_position_ms, audio_start))
      }
    }
  }

  let is_playing = @signal.memo(fn() {
    match mode.get() {
      Stopped(_) => false
      Playing(_, _, _) => true
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
                  @ui.render_play_pause_button(on_play_pause, is_playing),
                  @ui.render_volume_control(volume, is_muted),
                  @ui.render_bpm_input(tempo),
                ]),
                // seek_bar
                @dom.div(class="flex-1", [
                  @ui.render_seek_bar(
                    position_ms, total_duration_ms, has_notes, on_seek,
                  ),
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
