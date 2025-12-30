///|
/// Render falling notes display component
pub fn render_falling_notes(
  animation_state : @signal.Signal[@animation.AnimationState],
) -> @dom.DomNode {
  @dom.div(class="falling-notes-container flex-1 flex flex-col", [
    @dom.div(class="relative flex-1 bg-slate-900 overflow-hidden", [
      // Dynamic rendering of falling notes using index_each
      @dom.index_each(fn() { animation_state.get().notes }, fn(
        note_getter,
        _index,
      ) {
        @dom.div(
          dyn_class=fn() {
            let falling_note = note_getter()
            // Match keyboard width: black keys are w-8, white keys use flex width
            let width_class = if falling_note.is_black {
              "w-8"
            } else {
              // Calculate width based on total white keys (36 white keys)
              // Each white key is approximately 1/36 of the width
              "w-[2.77%]" // ~100/36
            }
            let color_class = if falling_note.y >= 95.0 {
              // Highlight when near trigger point
              if falling_note.is_black {
                "bg-purple-400"
              } else {
                "bg-blue-300"
              }
            } else if falling_note.is_black {
              "bg-purple-500"
            } else {
              "bg-blue-400"
            }
            "absolute h-16 rounded-md shadow-lg transition-colors " +
            width_class +
            " " +
            color_class
          },
          dyn_style=fn() {
            let falling_note = note_getter()
            "left: " +
            falling_note.x.to_string() +
            "%; " +
            "top: " +
            falling_note.y.to_string() +
            "%; " +
            "transform: translateX(-50%);"
          },
          [],
        )
      }),
    ]),
  ])
}
