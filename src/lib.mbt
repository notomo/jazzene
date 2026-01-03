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
  let tempo = @signal.signal(200)
  let volume = @signal.signal(0.3)

  // Track playback session (only used when Playing)
  let playback_started_at_raf_time = @signal.signal(0.0)
  let playback_started_from_position = @signal.signal(0)
  let pending_start_position : Ref[Int?] = { val: None }

  // Helper function to start playback
  fn start_playing(position_ms : Int) -> Unit {
    // Set flag to start on next RAF tick (to capture RAF time)
    pending_start_position.val = Some(position_ms)
    mode.set(@ui.PlaybackMode::playing(position_ms))
  }

  // Helper function to stop playback
  fn stop_playing() -> Unit {
    // Get current position from mode
    match mode.get() {
      @ui.PlaybackMode::Playing(position_ms~) =>
        mode.set(@ui.PlaybackMode::stopped(position_ms))
      _ => ()
    }
  }

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
  fn tick(raf_time : Double) -> Unit {
    // Handle pending playback start
    match pending_start_position.val {
      Some(pos) => {
        playback_started_at_raf_time.set(raf_time)
        playback_started_from_position.set(pos)
        pending_start_position.val = None
      }
      None => ()
    }
    match mode.get() {
      Stopped(..) => () // No-op when stopped
      Playing(..) => {
        // Calculate current position from RAF time
        let elapsed_ms = (raf_time - playback_started_at_raf_time.get()).to_int()
        let current_pos = playback_started_from_position.get() + elapsed_ms

        // Update mode with current position
        mode.set(@ui.PlaybackMode::playing(current_pos))

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
    fn loop_fn(time : Double) -> Unit {
      tick(time)
      @js_dom.window().requestAnimationFrame(loop_fn) |> ignore
    }

    @js_dom.window().requestAnimationFrame(loop_fn) |> ignore
  }

  start_tick_loop()

  // Render app
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let app = @luna_dom.div(
        class="h-svh bg-gradient-to-br from-slate-950 to-slate-900 text-white grid grid-rows-[min-content_1fr]",
        [
          @luna_dom.div(
            class="h-wit p-2 bg-slate-800 rounded-xl shadow-2xl border-2 border-slate-700",
            attrs=[("aria-label", @luna_dom.Attr::AttrString("lead sheet"))],
            [
              @luna_dom.div([
                @luna_dom.div(class="flex gap-4 items-center p-1", [
                  @ui.render_chord_input(chord_input),
                  @ui.render_bpm_input(tempo),
                ]),
                @luna_dom.div(class="flex gap-4 items-baseline p-1", [
                  @ui.render_play_pause_button(
                    note_values, mode, tempo, start_playing, stop_playing,
                  ),
                  @ui.render_volume_control(volume),
                  @luna_dom.div(class="w-full", [
                    @ui.render_seek_bar(note_values, mode, tempo, start_playing),
                  ]),
                ]),
              ]),
            ],
          ),
          @luna_dom.div(
            class="bg-slate-950 shadow-2xl border-slate-700 h-full grid grid-rows-[80%_20%]",
            attrs=[("aria-label", @luna_dom.Attr::AttrString("visualization"))],
            [
              @ui.render_falling_notes_canvas(
                note_values, mode, tempo, start_playing,
              ),
              @ui.render_keyboard_canvas(note_values, mode, tempo),
            ],
          ),
        ],
      )
      @luna_dom.render(el |> @luna_dom.DomElement::from_dom, app)
    }
    None => ()
  }
}
