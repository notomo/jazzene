///|
/// Render falling notes display component
pub fn render_falling_notes(
  animation_state : @signal.Signal[@animation.AnimationState],
) -> @dom.DomNode {
  @dom.div(
    class="falling-notes-container bg-slate-950 rounded-xl shadow-2xl border border-slate-700 p-4",
    [
      @dom.h3(class="text-xl font-bold mb-4 text-blue-400", [@dom.text("Notes")]),
      @dom.div(class="relative h-96 bg-slate-900 rounded-lg overflow-hidden", [
        // Dynamic rendering of falling notes
        @dom.fragment(render_falling_notes_dynamic(animation_state)),
      ]),
    ],
  )
}

///|
/// Render falling notes dynamically
fn render_falling_notes_dynamic(
  animation_state : @signal.Signal[@animation.AnimationState],
) -> Array[@dom.DomNode] {
  let state = animation_state.get()
  let note_elements : Array[@dom.DomNode] = []
  for falling_note in state.notes {
    let x = falling_note.x
    let y = falling_note.y
    let note_el = @dom.div(
      class="absolute w-3 h-12 bg-blue-400 rounded-full shadow-lg shadow-blue-400/50 animate-pulse",
      dyn_style=fn() {
        "left: " +
        x.to_string() +
        "%; " +
        "top: " +
        y.to_string() +
        "%; " +
        "transform: translateX(-50%);"
      },
      [],
    )
    note_elements.push(note_el)
  }
  note_elements
}
