///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  let is_playing = @signal.signal(false)
  let playback_position = @signal.signal(
    @music.Duration::from_milliseconds(0.0),
  )
  let volume = @signal.signal(0.3)
  let bpm = @signal.signal(200)
  let raw_chord_progression = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let note_values = @signal.memo(fn() {
    raw_chord_progression.get()
    |> @music.parse_chord_progression
    |> @music.generate_improvisation(@music.ImprovisationSettings::default())
  })
  let sounds : @signal.Signal[Array[@music.NoteValueSound]] = @signal.signal([])
  let _ = @signal.effect(fn() {
    let current_bpm = bpm.get()
    let sound_list = @music.NoteValueSound::from_note_values(
      note_values(),
      current_bpm,
    )
    sounds.set(sound_list)
  })
  let total_duration = @signal.memo(fn() {
    @music.calculate_total_duration(sounds.get())
  })
  let audio_ctx = @web_audio.AudioContext::new()
  fn tick(elapsed_ms : Double) -> Bool {
    let pos = playback_position.get() +
      @music.Duration::from_milliseconds(elapsed_ms)
    let total_dur = total_duration()
    let current_pos = if pos < total_dur { pos } else { total_dur }
    @audio.schedule_notes_in_window(
      audio_ctx,
      sounds.get(),
      current_pos,
      volume.get(),
    )
    playback_position.set(current_pos)
    current_pos >= total_dur
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
                    is_playing, playback_position, total_duration,
                  ),
                  @ui.volume_input(volume),
                  @luna_dom.div(class="w-full", [
                    @ui.seek_bar(playback_position, total_duration),
                  ]),
                ]),
              ]),
            ],
          ),
          @luna_dom.div(
            class="bg-slate-950 shadow-2xl border-slate-700 h-full grid grid-rows-[80%_20%]",
            attrs=[("aria-label", @luna_dom.Attr::AttrString("visualization"))],
            [
              @ui.note_display(sounds, playback_position, bpm, total_duration),
              @ui.keyboard(sounds, playback_position),
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
