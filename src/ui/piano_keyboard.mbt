///|
/// Render piano keyboard component
pub fn render_piano_keyboard(
  current_note : @signal.Signal[@core.Note?],
) -> @dom.DomNode {
  @dom.div(
    class="font-sans bg-slate-900 p-6 rounded-xl shadow-2xl border border-slate-700",
    [
      @dom.h3(class="text-xl font-bold mb-4 text-blue-400", [
        @dom.text("Piano Keyboard"),
      ]),
      @dom.div(
        class="relative h-40 bg-slate-950 rounded-lg overflow-hidden flex items-end justify-center gap-px",
        render_piano_keys(current_note),
      ),
    ],
  )
}

///|
/// Render individual piano keys (simplified: one octave)
fn render_piano_keys(
  current_note : @signal.Signal[@core.Note?],
) -> Array[@dom.DomNode] {
  let keys : Array[@dom.DomNode] = []

  // Simplified: show keys for middle C octave (C4-B4, MIDI 60-71)
  for midi = 60; midi < 72; midi = midi + 1 {
    let is_black = is_black_key(midi % 12)
    let midi_captured = midi // Capture for closure
    let key = @dom.div(
      dyn_class=fn() {
        let base_class = if is_black {
          "h-24 w-8 rounded-b-md "
        } else {
          "h-32 w-12 rounded-b-md "
        }
        let is_active = match current_note.get() {
          Some(note) => note.midi_number == midi_captured
          None => false
        }
        let color_class = if is_active {
          if is_black {
            "bg-blue-500 border-blue-400"
          } else {
            "bg-blue-400 border-blue-300"
          }
        } else if is_black {
          "bg-gray-800 border-gray-700"
        } else {
          "bg-white border-gray-300"
        }
        base_class + color_class + " border transition-colors"
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
