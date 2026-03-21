///|
/// Setup global error overlay for browsers without DevTools.
/// Catches window "error" and "unhandledrejection" events and renders
/// a fixed overlay so errors are visible on screen.
pub fn setup_error_overlay() -> Unit {
  let container : Ref[@js.Any?] = { val: None }
  let show_error = fn(msg : String) {
    match container.val {
      None => {
        let overlay = @js_dom.document().create_element("div")
        let style = @js_dom.css_style_from_val(overlay.as_any()._get("style"))
        style.set_property("position", "fixed")
        style.set_property("top", "0")
        style.set_property("left", "0")
        style.set_property("width", "100%")
        style.set_property("height", "100%")
        style.set_property("background", "rgba(0,0,0,0.92)")
        style.set_property("color", "#ff5555")
        style.set_property("font-family", "monospace")
        style.set_property("font-size", "14px")
        style.set_property("padding", "16px")
        style.set_property("box-sizing", "border-box")
        style.set_property("white-space", "pre-wrap")
        style.set_property("word-break", "break-all")
        style.set_property("z-index", "9999")
        style.set_property("overflow", "auto")
        overlay.as_any()._set("textContent", @js.any("ERROR:\n" + msg))
        @js_dom.document()
        .as_any()
        ._get("body")
        ._call("appendChild", [overlay.as_any()])
        |> ignore
        container.val = Some(overlay.as_any())
      }
      Some(c) => {
        let current : String = c._get("textContent").cast()
        c._set("textContent", @js.any(current + "\n\n" + msg))
      }
    }
  }
  let win = @js_dom.window()
  win
  .as_event_target()
  .addEventListener("error", fn(ev) {
    let error = ev._get("error")
    let detail = if not(@js.is_nullish(error)) {
      let msg : String = error._get("message").cast()
      let stack = error._get("stack")
      if @js.is_nullish(stack) {
        msg
      } else {
        msg + "\n" + (stack.cast() : String)
      }
    } else {
      let msg : String = ev._get("message").cast()
      let filename : String = ev._get("filename").cast()
      let lineno : Int = ev._get("lineno").cast()
      if filename == "" {
        msg
      } else {
        msg + "\n  at " + filename + ":" + lineno.to_string()
      }
    }
    show_error(detail)
  })
  win
  .as_event_target()
  .addEventListener("unhandledrejection", fn(ev) {
    let reason = ev._get("reason")
    let detail = if @js.is_nullish(reason) {
      "Unhandled Promise Rejection"
    } else {
      let m = reason._get("message")
      let msg_part = if @js.is_nullish(m) {
        (reason.cast() : String)
      } else {
        (m.cast() : String)
      }
      let prefix = "Unhandled Promise Rejection: " + msg_part
      let stack = reason._get("stack")
      if @js.is_nullish(stack) {
        prefix
      } else {
        prefix + "\n" + (stack.cast() : String)
      }
    }
    show_error(detail)
  })
}

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
    is_recording,
    recorded_lines,
    on_note_on,
    on_note_off,
    measures,
    sounds,
    comping_sounds,
    bass_sounds,
    drum_sounds,
    recorded_sounds_visual,
    total_duration,
    chord_parse_error,
    ..,
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
      recorded_sounds_visual(),
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
                recorded_sounds_visual,
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
                recorded_sounds_visual,
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
                jazz_style,
                show_technique_hints,
                midi_active_notes,
                get_midi_bytes,
                on_import,
                imported_midi,
                is_recording,
                recorded_lines,
                on_note_on,
                on_note_off,
                state.practice_score,
                state.practice_best_score,
                state.practice_max_score,
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
fn request_wake_lock() -> Unit {
  match
    (
      @js.identity_option(@js_dom.window().navigator()._get("wakeLock")) :
      @js.Any?) {
    None => ()
    Some(wl) => {
      let request : () -> Unit = fn() {
        wl
        ._call("request", [@js.any("screen")])
        ._call("catch", [@js.from_fn1(fn(_ : @js.Any) { () })])
        |> ignore
      }
      request()
      @js_dom.document()
      .as_event_target()
      .addEventListener("visibilitychange", fn(_) {
        let state : String = @js_dom.document()
          .as_any()
          ._get("visibilityState")
          .cast()
        if state == "visible" {
          request()
        }
      })
    }
  }
}

///|
fn lock_landscape() -> Unit {
  match
    (
      @js.identity_option(@js_dom.window().screen()._get("orientation")) :
      @js.Any?) {
    None => ()
    Some(orientation) => {
      if @js.is_nullish(orientation._get("lock")) {
        return
      }
      let w = @js_dom.window().inner_width()
      let h = @js_dom.window().inner_height()
      if @cmp.minimum(w, h) > 767 {
        return
      }
      let lock : () -> Unit = fn() {
        orientation
        ._call("lock", [@js.any("landscape")])
        ._call("catch", [@js.from_fn1(fn(_ : @js.Any) { () })])
        |> ignore
      }
      let go_fullscreen_and_lock : () -> Unit = fn() {
        if not(
            @js.is_nullish(
              @js_dom.document().as_any()._get("fullscreenElement"),
            ),
          ) {
          lock()
          return
        }
        let el = @js_dom.document().as_any()._get("documentElement")
        let req_method = if not(@js.is_nullish(el._get("requestFullscreen"))) {
          Some("requestFullscreen")
        } else if not(@js.is_nullish(el._get("webkitRequestFullscreen"))) {
          Some("webkitRequestFullscreen")
        } else {
          None
        }
        match req_method {
          None => ()
          Some(m) =>
            el
            ._call(m, [])
            ._call("then", [@js.from_fn1(fn(_ : @js.Any) { lock() })])
            ._call("catch", [@js.from_fn1(fn(_ : @js.Any) { () })])
            |> ignore
        }
      }
      lock()
      @js_dom.document()
      .as_event_target()
      .addEventListener("click", fn(_) { go_fullscreen_and_lock() })
      @js_dom.document()
      .as_event_target()
      .addEventListener(
        "touchend",
        fn(_) { go_fullscreen_and_lock() },
        once=true,
      )
      @js_dom.document()
      .as_event_target()
      .addEventListener("fullscreenchange", fn(_) {
        if not(
            @js.is_nullish(
              @js_dom.document().as_any()._get("fullscreenElement"),
            ),
          ) {
          lock()
        }
      })
    }
  }
}
