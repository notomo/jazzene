///|
/// Render falling notes display component using Canvas API
pub fn note_display(
  sounds : () -> Array[@music.ScheduledSound],
  backing_sounds : () -> Array[@music.ScheduledSound],
  measures : () -> Array[@music.Measure],
  playback_position : @signals.Signal[@music.Duration],
  bpm : @signals.Signal[Int],
  total_duration : () -> @music.Duration,
  time_signature : @signals.Signal[@music.TimeSignature],
  loop_a_measure : @signals.Signal[Int],
  loop_b_measure : @signals.Signal[Int],
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
    backing_sounds().filter_map(fn(sound) {
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

  // Pre-calculate scale bands from chord progression
  let scale_bands = @signals.memo(fn() {
    compute_scale_bands(measures(), bpm.get())
  })

  // Pre-calculate guide tone marks from chord progression
  let guide_marks = @signals.memo(fn() {
    compute_guide_tone_marks(measures(), bpm.get())
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
      scale_bands(),
      guide_marks(),
      playback_position.get().to_milliseconds(),
      bpm.get(),
      time_signature.get().beats_per_measure(),
      loop_a_measure.get(),
      loop_b_measure.get(),
    )
  })
  @luna_dom.div(
    class="w-full flex-1 min-h-0 bg-slate-900",
    attrs=[("aria-label", @luna_dom.Attr::AttrString("falling notes"))],
    [canvas_to_dom_node(canvas)],
  )
}
