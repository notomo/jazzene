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
    },
  )
  let is_playing = @signal.signal(false)

  // Audio engine
  let audio_engine = @audio.AudioEngine::create()

  // Audio and tempo controls
  let volume = @signal.signal(0.3)
  let is_muted = @signal.signal(false)
  let tempo = @signal.signal(120)

  // Current playing note (as signal, not memo)
  let current_note : @signal.Signal[@core.Note?] = @signal.signal(None)

  // Reactive note generation - auto-generate when chord_input changes
  let _ = @signal.effect(fn() {
    let input = chord_input.get()
    // Clear notes if input is empty
    if input.length() == 0 {
      generated_notes.set([])
    } else {
      let chords = @core.parse_chord_progression(input)
      if chords.length() > 0 {
        let settings = @core.ImprovisationSettings::default()
        let notes = @core.generate_improvisation(chords, settings)
        generated_notes.set(notes)
      } else {
        // Clear notes if no valid chords parsed
        generated_notes.set([])
      }
    }
  })

  // Update duration when notes or tempo changes
  let _ = @signal.effect(fn() {
    let notes = generated_notes.get()
    let bpm = tempo.get()
    if notes.length() > 0 {
      let ms_per_quarter = 60000 / bpm
      let total_duration = notes.length() * ms_per_quarter
      playback_state.update(fn(s) {
        @playback_state.PlaybackState::{
          ..s,
          total_duration_ms: total_duration,
        }
      })
    } else {
      playback_state.update(fn(s) {
        @playback_state.PlaybackState::{ ..s, total_duration_ms: 0 }
      })
    }
  })

  // Calculate which notes should be visible at a given playback position
  fn calculate_visible_notes_at_position(
    notes : Array[@core.Note],
    position_ms : Int,
    tempo_bpm : Int,
  ) -> @animation.AnimationState {
    let ms_per_quarter = 60000 / tempo_bpm

    // Show notes in a "preview window" - 3 seconds ahead
    let preview_window_ms = 3000
    let window_start_ms = position_ms
    let window_end_ms = position_ms + preview_window_ms
    let start_index = window_start_ms / ms_per_quarter
    let end_index = (window_end_ms / ms_per_quarter + 1).min(notes.length())
    let mut state = @animation.create_initial_animation_state()
    for i = start_index; i < end_index; i = i + 1 {
      if i >= 0 && i < notes.length() {
        let note = notes[i]
        let note_time_ms = i * ms_per_quarter
        let time_from_position = note_time_ms - position_ms

        // Calculate y position based on time remaining
        // Notes appear at top (y=0) at preview_window_ms ahead
        // Notes reach bottom (y=95) at current position
        let y_percent = if time_from_position > 0 {
          // Future note - calculate position from top
          let progress = 1.0 -
            time_from_position.to_double() / preview_window_ms.to_double()
          progress * 95.0
        } else {
          // Note is at or past current position
          95.0
        }

        // Only add notes that are visible (y < 105)
        if y_percent < 105.0 {
          state = @animation.add_note_at_position(state, note, y_percent)
        }
      }
    }
    state
  }

  // Update animation preview when seekbar changes (when stopped)
  let _ = @signal.effect(fn() {
    if not(is_playing.get()) {
      let state = playback_state.get()
      let notes = generated_notes.get()
      let bpm = tempo.get()
      if notes.length() > 0 {
        let preview_state = calculate_visible_notes_at_position(
          notes,
          state.playback_position_ms,
          bpm,
        )
        animation_state.set(preview_state)
      }
    }
  })

  // Position update timer (stored outside on_play_pause to track across calls)
  let position_update_timer : @signal.Signal[@js_global.Timer?] = @signal.signal(
    None,
  )

  // Event handlers
  fn on_play_pause() -> Unit {
    let notes = generated_notes.get()
    if notes.length() == 0 {
      return
    }
    let state = playback_state.get()
    if is_playing.get() {
      // STOP: Cancel all scheduled timeouts, keep current position
      for timer in state.scheduled_timeouts {
        @js_global.clear_timeout(timer)
      }
      // Cancel position update interval
      match position_update_timer.get() {
        Some(timer) => @js_global.clear_interval(timer)
        None => ()
      }
      position_update_timer.set(None)
      playback_state.update(fn(s) {
        @playback_state.PlaybackState::{ ..s, scheduled_timeouts: [] }
      })
      is_playing.set(false)
      // Preview effect will update animation to show notes at current position
    } else {
      // PLAY: Start from current position
      let start_index = state.current_note_index
      let start_time_ms = state.playback_position_ms
      let bpm = tempo.get()
      let ms_per_quarter = 60000 / bpm

      // Clear animation state for fresh start
      animation_state.set(@animation.create_initial_animation_state())
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

            // Update current note index
            playback_state.update(fn(s) {
              @playback_state.PlaybackState::{
                ..s,
                current_note_index: index + 1,
              }
            })

            // Stop when reaching end (stay at end position)
            if index == notes.length() - 1 {
              let _ = @js_global.set_timeout(
                fn() {
                  is_playing.set(false)
                  // Keep current position at end
                },
                3000,
              )

            }
          },
          delay_from_now,
        )
        new_timeouts.push(timer)
      }

      // Start position update interval (every 50ms)
      let interval_timer = @js_global.set_interval(
        fn() {
          // Increment position by 50ms each interval
          playback_state.update(fn(s) {
            @playback_state.PlaybackState::{
              ..s,
              playback_position_ms: s.playback_position_ms + 50,
            }
          })
        },
        50,
      )
      position_update_timer.set(Some(interval_timer))

      // Update state with new timeouts
      playback_state.update(fn(s) {
        @playback_state.PlaybackState::{
          ..s,
          scheduled_timeouts: new_timeouts,
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

    // If playing, stop first
    if was_playing {
      for timer in state.scheduled_timeouts {
        @js_global.clear_timeout(timer)
      }
    }

    // Calculate new position
    let bpm = tempo.get()
    let ms_per_quarter = 60000 / bpm
    let total_duration = notes.length() * ms_per_quarter
    let new_position_ms = (position_percent / 100.0 * total_duration.to_double()).to_int()
    let new_note_index = new_position_ms / ms_per_quarter

    // Update playback position
    playback_state.set(@playback_state.PlaybackState::{
      current_note_index: new_note_index,
      playback_position_ms: new_position_ms,
      total_duration_ms: total_duration,
      scheduled_timeouts: [],
    })

    // If was playing, restart from new position
    if was_playing {
      is_playing.set(false) // Reset state
      on_play_pause() // Restart playback
    } else {
      // If stopped, preview effect will update animation
      is_playing.set(false)
    }
  }

  // Animation loop with sound trigger callback
  @animation.start_animation_loop(
    fn() {
      animation_state.update(fn(s) {
        @animation.update_animation(s, fn(note) {
          // Play sound when note reaches bottom
          let vol = if is_muted.get() { 0.0 } else { volume.get() }
          audio_engine.play_note(note, 500, vol) // 500ms duration
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
            chord_input, on_play_pause, on_seek, playback_state, generated_notes,
            is_playing, volume, is_muted, tempo,
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
