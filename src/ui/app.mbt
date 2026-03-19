///|
/// Setup animation loop
pub fn setup_loop(
  is_playing : @signals.Signal[Bool],
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

  let _ = @signals.effect(fn() {
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
pub fn render(state : AppState) -> Unit {
  let {
    bpm,
    raw_chord_progression,
    seed,
    measure_count,
    key,
    time_signature,
    playback_position,
    volume,
    loop_a_measure,
    loop_b_measure,
    jazz_style,
    show_technique_hints,
    view_state,
    is_playing,
    midi_active_notes,
    imported_midi,
    measures,
    sounds,
    comping_sounds,
    bass_sounds,
    drum_sounds,
    total_duration,
    chord_parse_error,
  } = state
  let get_midi_bytes = fn() {
    let text = "chords: " +
      raw_chord_progression.get() +
      " seed: " +
      seed.get().to_string()
    @midi.encode_to_midi(
      sounds(),
      comping_sounds(),
      bass_sounds(),
      drum_sounds(),
      bpm.get(),
      time_signature=time_signature.get(),
      key_signature=key.get(),
      text~,
    )
  }
  let on_import = fn(bytes : Array[Int]) {
    match @midi.decode_midi(bytes) {
      None => ()
      Some(data) => {
        match data.bpm {
          Some(b) => bpm.set(b)
          None => ()
        }
        match data.key {
          Some(k) => key.set(k)
          None => ()
        }
        match data.time_signature {
          Some(ts) => time_signature.set(ts)
          None => ()
        }
        match data.measure_count {
          Some(mc) => {
            measure_count.set(mc)
            loop_b_measure.set(mc)
          }
          None => ()
        }
        playback_position.set(@music.Duration::from_milliseconds(0))
        raw_chord_progression.set("")
        jazz_style.update(fn(style) {
          @music.JazzStyle::{
            ..style,
            melody_mode: @music.On,
            comping_style: @music.Imported,
            bass_style: @music.Imported,
            drum_pattern: @music.Imported,
          }
        })
        imported_midi.set(Some(data))
      }
    }
  }
  let app = @luna_dom.div(
    class="flex flex-col h-dvh overflow-hidden w-dvw bg-gradient-to-br from-slate-950 to-slate-900 text-white touch-manipulation",
    [
      @luna_dom.div(
        class="px-3 py-1.5 bg-slate-800 border-b-2 border-slate-700",
        attrs=[("aria-label", @luna_dom.Attr::AttrString("lead sheet"))],
        [
          @luna_dom.div(class="flex gap-2 lg:gap-4 items-center", [
            song_preset_select(
              raw_chord_progression, key, bpm, measure_count, loop_b_measure, time_signature,
            ),
            @luna_dom.div(
              class="flex gap-2 lg:gap-4 items-center min-w-0 flex-1",
              [
                time_signature_select(time_signature),
                key_select(key),
                chord_progression_input(
                  raw_chord_progression, chord_parse_error,
                ),
              ],
            ),
            @luna_dom.div(class="flex gap-2 lg:gap-4 items-center shrink-0", [
              seed_input(seed),
              measure_count_input(measure_count, loop_b_measure),
              bpm_input(bpm),
            ]),
          ]),
        ],
      ),
      @luna_dom.div(
        dyn_class=fn() {
          match view_state.get() {
            { show_sheet: false, show_piano_roll: true, show_settings: false } =>
              "flex justify-center h-full min-h-0"
            _ => "flex h-full min-h-0"
          }
        },
        attrs=[("aria-label", @luna_dom.Attr::AttrString("visualization"))],
        [
          @luna_dom.div(
            dyn_class=fn() {
              match view_state.get() {
                { show_sheet: false, .. } => "hidden"
                { show_piano_roll: true, .. } => "flex-1 min-h-0 overflow-auto"
                _ => "w-full min-h-0 overflow-auto"
              }
            },
            attrs=[("id", @luna_dom.Attr::AttrString("lead-sheet-container"))],
            [
              @luna_dom.div(
                dyn_class=fn() {
                  match view_state.get() {
                    { show_sheet: true, show_piano_roll: false, .. } =>
                      "w-4/5 mx-auto"
                    _ => ""
                  }
                },
                [
                  @sheet.lead_sheet(
                    measures,
                    playback_position,
                    bpm,
                    key,
                    time_signature,
                    loop_a_measure,
                    loop_b_measure,
                    fn() { show_technique_hints.get() },
                  ),
                ],
              ),
            ],
          ),
          @luna_dom.div(
            dyn_class=fn() {
              match view_state.get().show_piano_roll {
                true => "flex flex-col flex-1 min-h-0"
                false => "hidden"
              }
            },
            attrs=[("aria-label", @luna_dom.Attr::AttrString("visualization"))],
            [
              @piano_roll.note_display(
                sounds,
                comping_sounds,
                measures,
                playback_position,
                bpm,
                total_duration,
                time_signature,
                loop_a_measure,
                loop_b_measure,
                fn() { show_technique_hints.get() },
              ),
              @piano_roll.keyboard(
                sounds,
                comping_sounds,
                measures,
                bpm,
                playback_position,
                fn() { show_technique_hints.get() },
                midi_active_notes,
                fn() { jazz_style.get().pitch_min },
                fn() { jazz_style.get().pitch_max },
              ),
            ],
          ),
          @luna_dom.div(
            dyn_class=fn() {
              if view_state.get().show_settings {
                "contents"
              } else {
                "hidden"
              }
            },
            [
              settings_panel(
                jazz_style, show_technique_hints, midi_active_notes, get_midi_bytes,
                on_import, imported_midi,
              ),
            ],
          ),
        ],
      ),
      @luna_dom.div(
        class="grid grid-cols-[1fr_auto_1fr] items-stretch px-3 py-1.5 bg-slate-800 border-t-2 border-slate-700",
        [
          @luna_dom.div(class="justify-self-start flex items-center", [
            volume_input(volume),
          ]),
          play_pause_button(is_playing),
          @luna_dom.div(
            class="flex items-center justify-between pl-2 lg:pl-4 gap-2",
            [
              ab_loop(loop_a_measure, loop_b_measure, fn() {
                measure_count.get()
              }),
              view_mode_select(view_state),
            ],
          ),
        ],
      ),
    ],
  )

  disable_pinch_zoom()
  request_wake_lock()
  lock_landscape()

  @js_dom.document().getElementById("app")
  |> Option::map(fn(e) {
    @luna_dom.DomElement::from_dom(e) |> @luna_dom.render(app)
  })
  |> ignore
}

///|
fn disable_pinch_zoom() -> Unit {
  @js_dom.document()
  .as_event_target()
  .addEventListener("touchmove", fn(e) {
    let length : Int = e._get("touches")._get("length").cast()
    if length > 1 {
      e._call("preventDefault", []) |> ignore
    }
  })
}

///|
extern "js" fn request_wake_lock() -> Unit =
  #|() => {
  #|  if (!('wakeLock' in navigator)) return;
  #|  const request = () => navigator.wakeLock.request('screen').catch(() => {});
  #|  request();
  #|  document.addEventListener('visibilitychange', () => {
  #|    if (document.visibilityState === 'visible') request();
  #|  });
  #|}

///|
extern "js" fn lock_landscape() -> Unit =
  #|() => {
  #|  const so = screen.orientation;
  #|  if (!so || !so.lock) return;
  #|  const isNarrow = () => Math.min(window.innerWidth, window.innerHeight) <= 767;
  #|  if (!isNarrow()) return;
  #|  const lock = () => so.lock('landscape').catch(() => {});
  #|  const goFullscreenAndLock = () => {
  #|    if (document.fullscreenElement) { lock(); return; }
  #|    const el = document.documentElement;
  #|    const req = el.requestFullscreen || el.webkitRequestFullscreen;
  #|    if (!req) return;
  #|    req.call(el).then(() => lock()).catch(() => {});
  #|  };
  #|  lock();
  #|  document.addEventListener('click', goFullscreenAndLock);
  #|  document.addEventListener('touchend', goFullscreenAndLock, { once: true });
  #|  document.addEventListener('fullscreenchange', () => {
  #|    if (document.fullscreenElement) lock();
  #|  });
  #|}
