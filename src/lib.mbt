///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  let is_playing = @signal.signal(false)
  let playback_position_ms = @signal.signal(0)
  let volume = @signal.signal(0.3)
  let bpm = @signal.signal(200)
  let raw_chord_progression = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let note_values : @signal.Signal[Array[@music.NoteValue]] = @signal.signal([])
  let _ = @signal.effect(fn() {
    let x = raw_chord_progression.get()
      |> @music.parse_chord_progression
      |> @music.generate_improvisation(@music.ImprovisationSettings::default())
    note_values.set(x)
  })
  let total_duration = @signal.memo(fn() {
    @music.calculate_total_duration(note_values.get(), bpm.get())
  })

  // Track playback session (only used when playing)
  let playback_started_at_raf_time : Ref[Double] = { val: 0.0 }
  let playback_started_from_position : Ref[Int] = { val: 0 }
  let pending_start_position : Ref[Int?] = { val: None }
  fn start_playing(position_ms : Int) -> Unit {
    pending_start_position.val = Some(position_ms)
    playback_position_ms.set(position_ms)
    is_playing.set(true)
  }

  let audio_ctx = @web_audio.AudioContext::new()
  fn tick(raf_time : Double) -> Unit {
    match pending_start_position.val {
      Some(pos) => {
        playback_started_at_raf_time.val = raf_time
        playback_started_from_position.val = pos
        pending_start_position.val = None
      }
      None => ()
    }
    if not(is_playing.get()) {
      return
    }
    let elapsed_ms = (raf_time - playback_started_at_raf_time.val).to_int()
    let current_pos = playback_started_from_position.val + elapsed_ms

    // Schedule audio in lookahead window
    @audio.schedule_notes_in_window(
      audio_ctx,
      note_values.get(),
      bpm.get(),
      current_pos,
      100,
      volume.get(),
    )
    playback_position_ms.set(@cmp.minimum(current_pos, total_duration()))
    if current_pos >= total_duration() {
      is_playing.set(false)
    }
  }

  setup_loop(is_playing, tick)

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
                  @ui.chord_progression_input(raw_chord_progression),
                  @ui.bpm_input(bpm),
                ]),
                @luna_dom.div(class="flex gap-4 items-baseline p-1", [
                  @ui.play_pause_button(
                    is_playing, playback_position_ms, total_duration, start_playing,
                  ),
                  @ui.volume_input(volume),
                  @luna_dom.div(class="w-full", [
                    @ui.seek_bar(
                      is_playing, playback_position_ms, total_duration, start_playing,
                    ),
                  ]),
                ]),
              ]),
            ],
          ),
          @luna_dom.div(
            class="bg-slate-950 shadow-2xl border-slate-700 h-full grid grid-rows-[80%_20%]",
            attrs=[("aria-label", @luna_dom.Attr::AttrString("visualization"))],
            [
              @ui.note_display(
                note_values, is_playing, playback_position_ms, bpm, total_duration,
                start_playing,
              ),
              @ui.keyboard(note_values, playback_position_ms, bpm),
            ],
          ),
        ],
      )
      el |> @luna_dom.DomElement::from_dom |> @luna_dom.render(app)
    }
    None => ()
  }
}

///|
fn setup_loop(
  is_playing : @signal.Signal[Bool],
  tick : (Double) -> Unit,
) -> Unit {
  let request_id : Ref[Int?] = { val: None }
  let _ = @signal.effect(fn() {
    if is_playing.get() {
      fn loop_fn(time : Double) -> Unit {
        tick(time)
        request_id.val = Some(@js_dom.window().requestAnimationFrame(loop_fn))
      }

      request_id.val = Some(@js_dom.window().requestAnimationFrame(loop_fn))
      return
    }
    match request_id.val {
      Some(id) => {
        @js_dom.window().cancelAnimationFrame(id)
        request_id.val = None
      }
      None => ()
    }
  })

}
