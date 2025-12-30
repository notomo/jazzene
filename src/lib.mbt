///|
/// Jazzene - Jazz Improvisation Web App
fn main {
  // State signals
  let chord_input = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let generated_notes : @signal.Signal[Array[@core.Note]] = @signal.signal([])
  let animation_state = @signal.signal(
    @animation.create_initial_animation_state(),
  )
  let is_playing = @signal.signal(false)

  // Audio engine
  let audio_engine = @audio.AudioEngine::create()

  // Current playing note (as signal, not memo)
  let current_note : @signal.Signal[@core.Note?] = @signal.signal(None)

  // Event handlers
  fn on_generate() -> Unit {
    let chords = @core.parse_chord_progression(chord_input.get())
    let settings = @core.ImprovisationSettings::default()
    let notes = @core.generate_improvisation(chords, settings)
    generated_notes.set(notes)
    animation_state.set(@animation.create_initial_animation_state()) // Reset animation
  }

  fn on_play() -> Unit {
    let notes = generated_notes.get()
    if notes.length() > 0 {
      is_playing.set(true)

      // Schedule notes to be added to animation with timing (sound will be triggered when they reach bottom)
      let bpm = 120
      let ms_per_quarter = 60000 / bpm
      for i = 0; i < notes.length(); i = i + 1 {
        let note = notes[i]
        let delay_ms = i * ms_per_quarter
        let index = i

        // Schedule note to be added to animation
        let _ = @js_global.set_timeout(
          fn() {
            animation_state.update(fn(s) { @animation.add_note(s, note) })

            // Stop playing when last note is added + time to fall
            if index == notes.length() - 1 {
              let _ = @js_global.set_timeout(
                fn() { is_playing.set(false) },
                3000,
              )

            }
          },
          delay_ms,
        )

      }
    }
  }

  // Animation loop with sound trigger callback
  @animation.start_animation_loop(
    fn() {
      animation_state.update(fn(s) {
        @animation.update_animation(s, fn(note) {
          // Play sound when note reaches bottom
          audio_engine.play_note(note, 500) // 500ms duration
          current_note.set(Some(note))
          // Clear current note after a short duration
          let _ = @js_global.set_timeout(fn() { current_note.set(None) }, 200)

        })
      })
    },
    fn() { true }, // Always running
  )

  // Render app
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let app = @dom.div(
        class="h-screen bg-gradient-to-br from-slate-950 to-slate-900 text-white p-1 flex flex-col overflow-hidden",
        [
          // Top: Lead sheet
          @ui.render_lead_sheet(chord_input, on_generate, on_play, is_playing),

          // Bottom: Falling notes + Piano keyboard (connected) - grow to fill remaining space
          @dom.div(
            class="bg-slate-950 rounded-xl shadow-2xl border-2 border-slate-700 overflow-hidden flex-1 mt-2 flex flex-col",
            [
              @ui.render_falling_notes(animation_state),
              @ui.render_piano_keyboard(current_note),
            ],
          ),
        ],
      )
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}
