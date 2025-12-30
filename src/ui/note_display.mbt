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
          class="absolute w-3 h-12 bg-blue-400 rounded-full shadow-lg shadow-blue-400/50 animate-pulse",
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
