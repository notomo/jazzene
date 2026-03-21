///|
/// Render falling notes display component using Canvas API
pub fn note_display(
  sounds : () -> Array[@music.ScheduledSound],
  comping_sounds : () -> Array[@music.ScheduledSound],
  recorded_sounds : () -> Array[@music.ScheduledSound],
  measures : () -> Array[@music.Measure],
  playback_position : @signals.Signal[@music.Duration],
  bpm : @signals.Signal[Int],
  total_duration : () -> @music.Duration,
  time_signature : @signals.Signal[@music.TimeSignature],
  loop_a_measure : @signals.Signal[Int],
  loop_b_measure : @signals.Signal[Int],
  show_technique_hints : () -> Bool,
  on_chord_click~ : (Int, Int) -> Unit,
) -> @luna_dom.DomNode {
  let { canvas, ctx } = create_canvas_context()
  let resize_trigger = create_resize_trigger(canvas)

  // Pre-calculate note positions
  let note_positions = @signals.memo(fn() {
    sounds().filter_map(fn(sound) {
      match sound.sound_event {
        Note(midi=midi_val, ..) =>
          Some({
            midi: midi_val.value,
            start_ms: sound.start_time.to_milliseconds(),
            duration_ms: sound.duration.to_milliseconds(),
            tone_origin: sound.tone_origin,
          })
        Rest(..) => None
      }
    })
  })

  // Pre-calculate backing note positions
  let backing_positions = @signals.memo(fn() {
    comping_sounds().filter_map(fn(sound) {
      match sound.sound_event {
        Note(midi=midi_val, ..) =>
          Some({
            midi: midi_val.value,
            start_ms: sound.start_time.to_milliseconds(),
            duration_ms: sound.duration.to_milliseconds(),
            tone_origin: None,
          })
        Rest(..) => None
      }
    })
  })

  // Pre-calculate recorded note positions
  let recorded_positions = @signals.memo(fn() {
    recorded_sounds().filter_map(fn(sound) {
      match sound.sound_event {
        Note(midi=midi_val, ..) =>
          Some({
            midi: midi_val.value,
            start_ms: sound.start_time.to_milliseconds(),
            duration_ms: sound.duration.to_milliseconds(),
            tone_origin: sound.tone_origin,
          })
        Rest(..) => None
      }
    })
  })

  // Pre-calculate scale bands from chord progression
  let scale_bands = @signals.memo(fn() {
    compute_scale_bands(measures(), bpm.get())
  })

  // Pre-calculate chord labels for left-edge display
  let chord_labels = @signals.memo(fn() {
    compute_chord_labels(measures(), bpm.get())
  })

  // Set up seek interactions
  setup_wheel_seek(canvas, playback_position, total_duration)
  setup_drag_seek(canvas, playback_position, total_duration)

  // Redraw when position, notes, or canvas size change
  let _ = @signals.effect(fn() {
    let _ = resize_trigger.get()
    let (width, height) = update_canvas_dpi(canvas, ctx)
    draw_notes(
      ctx,
      width,
      height,
      note_positions(),
      backing_positions(),
      recorded_positions(),
      scale_bands(),
      chord_labels(),
      playback_position.get().to_milliseconds(),
      bpm.get(),
      time_signature.get().beats_per_measure(),
      loop_a_measure.get(),
      loop_b_measure.get(),
      show_technique_hints(),
    )
  })
  let container_ref : Ref[@js_dom.Element?] = { val: None }
  @luna_dom.div(
    class="w-full flex-1 min-h-0 bg-slate-900",
    attrs=[("aria-label", @luna_dom.Attr::AttrString("falling notes"))],
    ref_=fn(el) { container_ref.val = Some(el) },
    on=@luna_dom.events().click(fn(e) {
      match container_ref.val {
        None => ()
        Some(el) => {
          let rect = el.as_any()._call("getBoundingClientRect", [])
          let container_width : Double = rect._get("width").cast()
          let container_height : Double = rect._get("height").cast()
          let rect_top : Double = rect._get("top").cast()
          let rect_left : Double = rect._get("left").cast()
          let rel_x = e.clientX - rect_left
          let rel_y = e.clientY - rect_top
          let label_w = calc_label_width(container_width)
          if rel_x > label_w {
            return
          }
          let current_ms = playback_position.peek().to_milliseconds()
          let percent = rel_y / container_height
          let click_time = current_ms + (1.0 - percent) * NOTE_DISPLAY_WINDOW_MS
          let labels = chord_labels()
          for label in labels {
            if click_time >= label.start_ms && click_time < label.end_ms {
              on_chord_click(label.measure_idx, label.chord_idx)
              break
            }
          }
        }
      }
    }),
    [canvas_to_dom_node(canvas)],
  )
}
