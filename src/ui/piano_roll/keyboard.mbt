///|
const WHITE_KEY_COLOR = "#ffffff"

///|
const BLACK_KEY_COLOR = "#1f2937"

///|
const WHITE_KEY_BACKING_COLOR = "#9ca3af"

///|
const BLACK_KEY_BACKING_COLOR = "#6b7280"

///|
const KEY_BORDER_COLOR = "#d1d5db"

///|
const BLACK_KEY_HEIGHT_RATIO = 0.6

///|
/// Render piano keyboard component using Canvas API
pub fn keyboard(
  sounds : () -> Array[@music.ScheduledSound],
  comping_sounds : () -> Array[@music.ScheduledSound],
  recorded_sounds : () -> Array[@music.ScheduledSound],
  measures : () -> Array[@music.Measure],
  bpm : @signals.Signal[Int],
  playback_position : @signals.Signal[@music.Duration],
  show_technique_hints : () -> Bool,
  midi_active_notes : @signals.Signal[Array[@music.MidiNumber]],
  pitch_min : () -> Int,
  pitch_max : () -> Int,
) -> @luna_dom.DomNode {
  let { canvas, ctx } = create_canvas_context()
  let resize_trigger = create_resize_trigger(canvas)

  let chord_labels = @signals.memo(fn() {
    compute_chord_labels(measures(), bpm.get())
  })

  // Calculate currently playing notes with technique-based colors (MIDI index → color)
  let playing_notes = @signals.memo(fn() {
    let set : Array[String?] = Array::make(128, None)
    @music.calculate_playing_notes(sounds(), playback_position.get()).each(fn(
      s,
    ) {
      match s.midi() {
        Some(m) =>
          set[m.value] = Some(
            match s.tone_origin {
              Some(Imported) => @theme.PLAYING_COLOR_MIDI_IMPORTED
              Some(origin) =>
                if show_technique_hints() {
                  @theme.tone_origin_playing_color(origin)
                } else {
                  @theme.PLAYING_COLOR_CHORD_TONE
                }
              None => NOTE_PLAYING_COLOR
            },
          )
        None => ()
      }
    })
    // Recorded notes playing use MIDI_ACTIVE color
    @music.calculate_playing_notes(recorded_sounds(), playback_position.get())
    .filter_map(fn(s) { s.midi() })
    .each(fn(m) {
      if set[m.value] == None {
        set[m.value] = Some(@theme.PLAYING_COLOR_MIDI_ACTIVE)
      }
    })
    // MIDI input notes override all other colors (highest priority — live input)
    midi_active_notes
    .get()
    .each(fn(midi) { set[midi.value] = Some(@theme.PLAYING_COLOR_MIDI_ACTIVE) })
    set
  })

  // Calculate currently playing backing notes as a boolean lookup array (O(1) key lookup)
  let backing_playing_notes = @signals.memo(fn() {
    let set = Array::make(128, false)
    @music.calculate_playing_notes(comping_sounds(), playback_position.get())
    .filter_map(fn(s) { s.midi() })
    .each(fn(m) { set[m.value] = true })
    set
  })

  // Redraw when playing notes or canvas size change
  let _ = @signals.effect(fn() {
    let _ = resize_trigger.get()
    let (width, height) = update_canvas_dpi(canvas, ctx)
    let current_pos = playback_position.get().to_milliseconds()
    let current_chord = chord_labels()
      .iter()
      .filter(fn(l) { l.start_ms <= current_pos && current_pos < l.end_ms })
      .map(fn(l) { @music.format_chord(l.chord) })
      .next()
    draw_keyboard(
      ctx,
      width,
      height,
      playing_notes(),
      backing_playing_notes(),
      current_chord,
      pitch_min(),
      pitch_max(),
    )
  })
  @luna_dom.div(
    class="w-full h-[15%] min-h-10 shrink",
    attrs=[("aria-label", @luna_dom.Attr::AttrString("keyboard canvas"))],
    [canvas_to_dom_node(canvas)],
  )
}

///|
/// Draw keyboard on canvas
fn draw_keyboard(
  ctx : @canvas.CanvasRenderingContext2D,
  width : Double,
  height : Double,
  playing_notes : Array[String?],
  backing_playing_notes : Array[Bool],
  current_chord : String?,
  pitch_min : Int,
  pitch_max : Int,
) -> Unit {
  ctx.clearRect(0.0, 0.0, width, height)
  ctx.fillStyle = NOTE_DISPLAY_BG_COLOR
  ctx.fillRect(0.0, 0.0, width, height)

  let label_width = calc_label_width(width)
  ctx.fillStyle = NOTE_DISPLAY_BG_COLOR
  ctx.fillRect(0.0, 0.0, label_width, height)
  ctx.strokeStyle = MEASURE_LINE_COLOR
  ctx.lineWidth = 1.0
  ctx.strokeRect(0.5, 0.5, label_width - 1.0, height - 1.0)
  match current_chord {
    Some(chord_text) if height >= 10.0 => {
      ctx.save()
      let font_size = label_width * 0.5
      ctx.font = "bold \{font_size.to_int()}px sans-serif"
      ctx.fillStyle = "#ffffff"
      ctx.textAlign = "center"
      ctx.textBaseline = "middle"
      ctx.fillText(
        chord_text,
        label_width / 2.0,
        height / 2.0,
        max_width=label_width - 12.0,
      )
      ctx.restore()
    }
    _ => ()
  }
  let rect = { left: label_width, top: 0.0, width: width - label_width, height }
  let key_areas = calc_key_areas(rect, KEYBOARD_MIN_KEY, KEYBOARD_MAX_KEY)

  // Draw white keys first (background layer)
  key_areas
  .iter()
  .filter(fn(a) { not(a.is_black) })
  .each(fn(area) {
    ctx.fillStyle = match
      (playing_notes[area.midi], backing_playing_notes[area.midi]) {
      (Some(color), _) => color
      (None, true) => WHITE_KEY_BACKING_COLOR
      (None, false) => WHITE_KEY_COLOR
    }
    ctx.fillRect(
      area.rect.left,
      area.rect.top,
      area.rect.width,
      area.rect.height,
    )
    ctx.strokeStyle = KEY_BORDER_COLOR
    ctx.strokeRect(
      area.rect.left,
      area.rect.top,
      area.rect.width,
      area.rect.height,
    )
  })

  // Draw black keys on top (foreground layer)
  key_areas
  .iter()
  .filter(fn(a) { a.is_black })
  .each(fn(area) {
    ctx.fillStyle = match
      (playing_notes[area.midi], backing_playing_notes[area.midi]) {
      (Some(color), _) => color
      (None, true) => BLACK_KEY_BACKING_COLOR
      (None, false) => BLACK_KEY_COLOR
    }
    ctx.fillRect(
      area.rect.left,
      area.rect.top,
      area.rect.width,
      height * BLACK_KEY_HEIGHT_RATIO,
    )
  })

  // Draw pitch range overlay: dim keys outside [pitch_min, pitch_max]
  let min_area = key_areas.iter().filter(fn(a) { a.midi == pitch_min }).next()
  let max_area = key_areas.iter().filter(fn(a) { a.midi == pitch_max }).next()
  match (min_area, max_area) {
    (Some(lo), Some(hi)) => {
      ctx.save()
      ctx.fillStyle = "rgba(0,0,0,0.4)"
      // Left out-of-range region
      let lo_x = lo.rect.left
      if lo_x > rect.left {
        ctx.fillRect(rect.left, 0.0, lo_x - rect.left, height)
      }
      // Right out-of-range region
      let hi_x = hi.rect.left + hi.rect.width
      if hi_x < rect.left + rect.width {
        ctx.fillRect(hi_x, 0.0, rect.left + rect.width - hi_x, height)
      }
      ctx.restore()
    }
    _ => ()
  }
}
