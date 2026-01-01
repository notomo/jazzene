///|
/// Render falling notes display component
pub fn render_falling_notes(
  notes : @signal.Signal[Array[@music.Note]],
  mode : @signal.Signal[PlaybackMode],
  tempo : @signal.Signal[Int],
  frame_count : @signal.Signal[Int],
) -> @dom.DomNode {
  // Calculate current playback position
  let position_ms = @signal.memo(fn() {
    let _ = frame_count.get()
    match mode.get() {
      Stopped(pos) => pos
      Playing(started_at, started_from, _) => {
        let now_ms = @date.Date::now()
        started_from + (now_ms - started_at)
      }
    }
  })

  // Pre-calculate note positions (immutable list with start times)
  let note_positions = @signal.memo(fn() {
    let note_list = notes.get()
    let tempo_val = tempo.get()
    let mut current_pos = 0
    let positions : Array[(Int, Int, Int)] = [] // (midi, start_ms, duration_ms)
    for note in note_list {
      let duration_ms = note.duration.to_ms(tempo_val)
      positions.push((note.midi.value, current_pos, duration_ms))
      current_pos = current_pos + duration_ms
    }
    positions
  })

  // Generate fixed number of note slots (max 200 notes)
  let max_notes = 200
  let note_slots : Array[@dom.DomNode] = []
  for i = 0; i < max_notes; i = i + 1 {
    let slot_index = i
    let note_slot = @dom.div(
      class="absolute rounded",
      dyn_style=fn() {
        let positions = note_positions()
        if slot_index >= positions.length() {
          "display: none;"
        } else {
          let (midi, start_ms, duration_ms) = positions[slot_index]
          let end_ms = start_ms + duration_ms
          let pos = position_ms()
          let window_ms = 3000
          let start_offset = start_ms - pos
          let end_offset = end_ms - pos

          // Check if note is visible
          if end_offset < 0 || start_offset > window_ms {
            "display: none;"
          } else {
            // Calculate position and color
            let bottom_percent = 100.0 -
              start_offset.to_double() / window_ms.to_double() * 100.0
            let top_percent = 100.0 -
              end_offset.to_double() / window_ms.to_double() * 100.0
            let height_percent = bottom_percent - top_percent
            let left_percent = calculate_note_position(midi)
            let is_playing = pos >= start_ms && pos < end_ms
            let color = if is_playing { "#3b82f6" } else { "#60a5fa" }

            // Calculate width based on key type
            let width = if is_black_key(midi % 12) { "25px" } else { "32px" }
            "left: " +
            left_percent.to_string() +
            "%; top: " +
            top_percent.to_string() +
            "%; height: " +
            height_percent.to_string() +
            "%; width: " +
            width +
            "; background-color: " +
            color +
            "; display: block; transform: translateX(-50%); transition: background-color 0.2s;"
          }
        }
      },
      [],
    )
    note_slots.push(note_slot)
  }
  @dom.div(class="flex-1 flex flex-col", [
    @dom.div(
      class="relative flex-1 bg-slate-900 overflow-hidden",
      attrs=[("aria-label", @dom.Attr::AttrString("falling notes"))],
      note_slots,
    ),
  ])
}

///|
/// Calculate horizontal position percentage for a MIDI note
/// Returns the center position to match keyboard layout
fn calculate_note_position(midi : Int) -> Double {
  // Map MIDI 36-96 range to 0-100%
  // Calculate position based on white key index
  let total_white_keys = 35.0 // Total white keys in MIDI 36-96 range

  // Get the white key index for this note
  let white_key_index = count_white_keys_before(midi)
  if is_black_key(midi % 12) {
    // Black key - positioned at boundary between white keys (matches keyboard.mbt)
    white_key_index.to_double() / total_white_keys * 100.0
  } else {
    // White key - positioned at center of the key
    (white_key_index.to_double() + 0.5) / total_white_keys * 100.0
  }
}

///|
/// Count white keys before a given MIDI note
pub fn count_white_keys_before(midi : Int) -> Int {
  let mut count = 0
  for i = 36; i < midi; i = i + 1 {
    if not(is_black_key(i % 12)) {
      count = count + 1
    }
  }
  count
}

///|
/// Check if a note is a black key (chromatic scale position)
pub fn is_black_key(note_in_octave : Int) -> Bool {
  match note_in_octave {
    1 | 3 | 6 | 8 | 10 => true // C#, D#, F#, G#, A#
    _ => false
  }
}
