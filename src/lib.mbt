///|
/// Jazzene - Jazz Improvisation Web App
fn main {
  // State signals
  let chord_input = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let generated_notes : @signal.Signal[Array[@core.Note]] = @signal.signal([])
  let animation_state = @signal.signal(
    @animation.create_initial_animation_state(),
  )
  let playback_state : @signal.Signal[@playback_state.PlaybackState] = @signal.signal(@playback_state.PlaybackState::{
      current_note_index: 0,
      playback_position_ms: 0,
      total_duration_ms: 0,
      scheduled_timeouts: [],
      is_paused: false,
    },
  )
  let is_playing = @signal.signal(false)

  // Audio engine
  let audio_engine = @audio.AudioEngine::create()

  // Current playing note (as signal, not memo)
  let current_note : @signal.Signal[@core.Note?] = @signal.signal(None)

  // Event handlers
  fn on_generate() -> Unit {
    // Cancel any ongoing playback
    let state = playback_state.get()
    for timer in state.scheduled_timeouts {
      @js_global.clear_timeout(timer)
    }

    // Generate notes
    let chords = @core.parse_chord_progression(chord_input.get())
    let settings = @core.ImprovisationSettings::default()
    let notes = @core.generate_improvisation(chords, settings)
    generated_notes.set(notes)
    animation_state.set(@animation.create_initial_animation_state()) // Reset animation
    // Reset playback state
    playback_state.set(@playback_state.PlaybackState::{
      current_note_index: 0,
      playback_position_ms: 0,
      total_duration_ms: 0,
      scheduled_timeouts: [],
      is_paused: false,
    })
    is_playing.set(false)
  }

  fn on_play_pause() -> Unit {
    let notes = generated_notes.get()
    if notes.length() == 0 {
      return
    }
    let state = playback_state.get()
    if is_playing.get() {
      // PAUSE: Cancel all scheduled timeouts
      for timer in state.scheduled_timeouts {
        @js_global.clear_timeout(timer)
      }
      playback_state.update(fn(s) {
        @playback_state.PlaybackState::{
          ..s,
          is_paused: true,
          scheduled_timeouts: [],
        }
      })
      is_playing.set(false)
    } else {
      // PLAY or RESUME: Schedule remaining notes from current position
      let start_index = state.current_note_index
      let start_time_ms = state.playback_position_ms
      let bpm = 120
      let ms_per_quarter = 60000 / bpm
      let new_timeouts : Array[@js_global.Timer] = []
      for i = start_index; i < notes.length(); i = i + 1 {
        let note = notes[i]
        let absolute_time = i * ms_per_quarter
        let delay_from_now = absolute_time - start_time_ms
        let index = i

        // Schedule note animation
        let timer = @js_global.set_timeout(
          fn() {
            animation_state.update(fn(s) { @animation.add_note(s, note) })

            // Update playback position
            playback_state.update(fn(s) {
              @playback_state.PlaybackState::{
                ..s,
                current_note_index: index + 1,
                playback_position_ms: absolute_time,
              }
            })

            // Stop when reaching end
            if index == notes.length() - 1 {
              let _ = @js_global.set_timeout(
                fn() {
                  playback_state.set(@playback_state.PlaybackState::{
                    current_note_index: 0,
                    playback_position_ms: 0,
                    total_duration_ms: 0,
                    scheduled_timeouts: [],
                    is_paused: false,
                  })
                  is_playing.set(false)
                },
                3000,
              )

            }
          },
          delay_from_now,
        )
        new_timeouts.push(timer)
      }

      // Update state with new timeouts and unpause
      playback_state.update(fn(s) {
        @playback_state.PlaybackState::{
          ..s,
          scheduled_timeouts: new_timeouts,
          is_paused: false,
          total_duration_ms: notes.length() * ms_per_quarter,
        }
      })
      is_playing.set(true)
    }
  }

  fn on_seek(position_percent : Double) -> Unit {
    let notes = generated_notes.get()
    if notes.length() == 0 {
      return
    }
    let state = playback_state.get()
    let was_playing = is_playing.get()

    // Step 1: Pause if playing
    if was_playing {
      for timer in state.scheduled_timeouts {
        @js_global.clear_timeout(timer)
      }
    }

    // Step 2: Calculate new position
    let bpm = 120
    let ms_per_quarter = 60000 / bpm
    let total_duration = notes.length() * ms_per_quarter
    let new_position_ms = (position_percent / 100.0 * total_duration.to_double()).to_int()
    let new_note_index = new_position_ms / ms_per_quarter

    // Step 3: Reset animation state
    animation_state.set(@animation.create_initial_animation_state())

    // Step 4: Update playback state
    playback_state.set(@playback_state.PlaybackState::{
      current_note_index: new_note_index,
      playback_position_ms: new_position_ms,
      total_duration_ms: total_duration,
      scheduled_timeouts: [],
      is_paused: true,
    })

    // Step 5: Resume if was playing
    if was_playing {
      on_play_pause()
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
          @ui.render_lead_sheet(
            chord_input, on_generate, on_play_pause, on_seek, playback_state, generated_notes,
            is_playing,
          ),

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
