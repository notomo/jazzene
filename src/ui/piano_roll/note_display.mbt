///|
/// Render falling notes display component using Canvas API
pub fn note_display(
  sounds : @signal.Signal[Array[@music.NoteValueSound]],
  playback_position : @signal.Signal[@music.Duration],
  bpm : @signal.Signal[Int],
  total_duration : () -> @music.Duration,
  time_signature : @signal.Signal[@music.TimeSignature],
) -> @luna_dom.DomNode {
  let { canvas, ctx } = create_canvas_context()
  let resize_trigger = create_resize_trigger(canvas)

  // Pre-calculate note positions
  let note_positions = @signal.memo(fn() {
    sounds
    .get()
    .filter_map(fn(sound) {
      match sound.note_value {
        Note(midi=midi_val, ..) =>
          Some({
            midi: midi_val.value,
            start_ms: sound.start_time.to_milliseconds(),
            duration_ms: sound.duration.to_milliseconds(),
          })
        Rest(..) => None
      }
    })
  })

  // Set up seek interactions
  setup_wheel_seek(canvas, playback_position, total_duration)
  setup_drag_seek(canvas, playback_position, total_duration)

  // Redraw when position, notes, or canvas size change
  let _ = @signal.effect(fn() {
    let _ = resize_trigger.get()
    let (width, height) = update_canvas_dpi(canvas, ctx)
    draw_notes(
      ctx,
      width,
      height,
      note_positions(),
      playback_position.get().to_milliseconds(),
      bpm.get(),
      time_signature.get().beats_per_measure(),
    )
  })
  @luna_dom.div(
    class="w-full flex-1 min-h-0 bg-slate-900",
    attrs=[("aria-label", @luna_dom.Attr::AttrString("falling notes"))],
    [canvas_to_dom_node(canvas)],
  )
}
