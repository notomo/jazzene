///|
/// Jazzene - Jazz Improvisation Web App
fn main {
  // Initialize random seed with current timestamp
  @core.init_random_seed(get_timestamp())

  // State signals
  let chord_input = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let generated_notes : @signal.Signal[Array[@core.Note]] = @signal.signal([])
  let animation_state = @signal.signal(
    @animation.create_initial_animation_state(),
  )
  let current_note_index : @signal.Signal[Int?] = @signal.signal(None)
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
      @audio.play_note_sequence(
        audio_engine,
        notes,
        120, // BPM
        fn(index : Int) {
          current_note_index.set(Some(index))
          if index < notes.length() {
            current_note.set(Some(notes[index]))
            animation_state.update(fn(s) {
              @animation.add_note(s, notes[index])
            })
          }

          // Stop playing when sequence ends
          if index == notes.length() - 1 {
            ffi_set_timeout(fn() { is_playing.set(false) }, 1000)
          }
        },
      )
    }
  }

  // Start animation loop
  @animation.start_animation_loop(
    fn() { animation_state.update(@animation.update_animation) },
    fn() { true }, // Always running
  )

  // Render app
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let app = @dom.div(
        class="min-h-screen bg-gradient-to-br from-slate-950 to-slate-900 text-white p-8",
        [
          @dom.div(class="max-w-6xl mx-auto", [
            @dom.h1(
              class="text-5xl font-bold mb-2 bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-600",
              [@dom.text("Jazzene")],
            ),
            @dom.p(class="text-slate-400 mb-8", [
              @dom.text("Jazz Improvisation Generator"),
            ]),
            @dom.div(class="space-y-6", [
              // Top: Lead sheet
              @ui.render_lead_sheet(
                chord_input, on_generate, on_play, is_playing,
              ),

              // Middle: Falling notes
              @ui.render_falling_notes(animation_state),

              // Bottom: Piano keyboard
              @ui.render_piano_keyboard(current_note),
            ]),
          ]),
        ],
      )
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}

///|
/// FFI: Get current timestamp
extern "js" fn get_timestamp() -> Int =
  #| () => {
  #|   return Math.floor(Date.now() / 1000);
  #| }

///|
/// FFI: setTimeout
extern "js" fn ffi_set_timeout(callback : () -> Unit, delay_ms : Int) -> Unit =
  #| (callback, delayMs) => {
  #|   setTimeout(callback, delayMs);
  #| }
