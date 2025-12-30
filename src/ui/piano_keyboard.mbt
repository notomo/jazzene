///|
/// Render piano keyboard component
pub fn render_piano_keyboard(
  current_note : @signal.Signal[@core.Note?],
) -> @dom.DomNode {
  @dom.div(class="font-sans w-full", [
    @dom.div(
      class="relative h-40 bg-slate-950 overflow-hidden flex items-end w-full",
      render_piano_keys(current_note),
    ),
  ])
}

///|
/// Render individual piano keys (simplified: one octave)
fn render_piano_keys(
  current_note : @signal.Signal[@core.Note?],
) -> Array[@dom.DomNode] {
  let keys : Array[@dom.DomNode] = []

  // Extended range: C2 to C7 (MIDI 36-96) for full width
  for midi = 36; midi < 97; midi = midi + 1 {
    let is_black = is_black_key(midi % 12)
    let midi_captured = midi // Capture for closure
    let key = @dom.div(
      dyn_class=fn() {
        let base_class = if is_black {
          "h-24 flex-1 min-w-0 "
        } else {
          "h-32 flex-1 min-w-0 "
        }
        let is_active = match current_note.get() {
          Some(note) => note.midi_number == midi_captured
          None => false
        }
        let color_class = if is_active {
          if is_black {
            "bg-blue-500 border-r border-blue-400"
          } else {
            "bg-blue-400 border-r border-blue-300"
          }
        } else if is_black {
          "bg-gray-800 border-r border-gray-700"
        } else {
          "bg-white border-r border-gray-300"
        }
        base_class + color_class + " transition-colors"
      },
      [],
    )
    keys.push(key)
  }
  keys
}

///|
/// Check if a note is a black key (chromatic scale position)
fn is_black_key(note_in_octave : Int) -> Bool {
  match note_in_octave {
    1 | 3 | 6 | 8 | 10 => true // C#, D#, F#, G#, A#
    _ => false
  }
}
