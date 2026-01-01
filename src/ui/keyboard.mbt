///|
/// Render piano keyboard component
pub fn render_keyboard(
  notes : @signal.Signal[Array[@music.Note]],
  mode : @signal.Signal[PlaybackMode],
  tempo : @signal.Signal[Int],
  frame_count : @signal.Signal[Int],
) -> @dom.DomNode {
  // Calculate currently playing notes
  let playing_notes = @signal.memo(fn() {
    let _ = frame_count.get()
    let pos = match mode.get() {
      Stopped(p) => p
      Playing(started_at, started_from, _) => {
        let now_ms = @date.Date::now()
        started_from + (now_ms - started_at)
      }
    }
    let note_list = notes.get()
    let tempo_val = tempo.get()
    let mut current_pos = 0
    let active_midi_notes : Array[Int] = []
    for note in note_list {
      let duration_ms = note.duration.to_ms(tempo_val)
      let start_ms = current_pos
      let end_ms = current_pos + duration_ms

      // Check if note is currently playing
      if pos >= start_ms && pos < end_ms {
        active_midi_notes.push(note.midi.value)
      }
      current_pos = current_pos + duration_ms
    }
    active_midi_notes
  })
  @dom.div(class="w-full", [
    @dom.div(
      class="relative h-40 bg-slate-950 overflow-hidden w-full flex",
      render_piano_keys(playing_notes),
    ),
  ])
}

///|
/// Render individual piano keys with realistic layout
fn render_piano_keys(playing_notes : () -> Array[Int]) -> Array[@dom.DomNode] {
  let white_keys : Array[@dom.DomNode] = []
  let black_keys : Array[@dom.DomNode] = []

  // Count total white keys for position calculation
  let mut total_white_keys = 0
  for midi = 36; midi < 97; midi = midi + 1 {
    if not(is_black_key(midi % 12)) {
      total_white_keys = total_white_keys + 1
    }
  }

  // Generate white and black keys separately
  for midi = 36; midi < 97; midi = midi + 1 {
    let is_black = is_black_key(midi % 12)
    if is_black {
      // Black key - positioned absolutely between white keys
      let white_key_index = count_white_keys_before(midi)
      let black_key = @dom.div(
        dyn_class=fn() {
          let active = playing_notes().contains(midi)
          "absolute top-0 h-24 w-8 rounded-b-md shadow-lg z-10 transition-colors " +
          (if active { "bg-blue-500" } else { "bg-gray-900" })
        },
        style="left: " +
          (white_key_index.to_double() * 100.0 / total_white_keys.to_double()).to_string() +
          "%; transform: translateX(-50%);",
        [],
      )
      black_keys.push(black_key)
    } else {
      // White key - flex layout, full height
      let white_key = @dom.div(
        dyn_class=fn() {
          let active = playing_notes().contains(midi)
          "h-full flex-1 border-r transition-colors border-gray-300 " +
          (if active { "bg-blue-400" } else { "bg-white" })
        },
        [],
      )
      white_keys.push(white_key)
    }
  }

  // Combine white keys and black keys (black keys on top)
  let result : Array[@dom.DomNode] = []
  for key in white_keys {
    result.push(key)
  }
  for key in black_keys {
    result.push(key)
  }
  result
}
