///|
/// Render piano keyboard component
pub fn render_keyboard() -> @dom.DomNode {
  @dom.div(class="font-sans w-full", [
    @dom.div(
      class="relative h-40 bg-slate-950 overflow-hidden w-full flex",
      render_piano_keys(),
    ),
  ])
}

///|
/// Render individual piano keys with realistic layout
fn render_piano_keys() -> Array[@dom.DomNode] {
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
        class="absolute top-0 h-24 w-8 rounded-b-md shadow-lg z-10 transition-colors bg-gray-900",
        style="left: " +
          (white_key_index.to_double() * 100.0 / total_white_keys.to_double()).to_string() +
          "%; transform: translateX(-50%);",
        [],
      )
      black_keys.push(black_key)
    } else {
      // White key - flex layout, full height
      let white_key = @dom.div(
        class="h-full flex-1 border-r transition-colors bg-white border-gray-300",
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

///|
/// Count white keys before a given MIDI note
fn count_white_keys_before(midi : Int) -> Int {
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
fn is_black_key(note_in_octave : Int) -> Bool {
  match note_in_octave {
    1 | 3 | 6 | 8 | 10 => true // C#, D#, F#, G#, A#
    _ => false
  }
}
