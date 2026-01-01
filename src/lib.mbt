///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  // Create single unified state
  let app_state : @signal.Signal[AppState] = @signal.signal(AppState::{
    mode: PlaybackMode::Stopped(0),
    notes: [],
    total_duration_ms: 0,
    tempo_bpm: 120,
    volume: 0.3,
    is_muted: false,
    chord_input: "Cm7 F7 Bbmaj7 Ebmaj7",
  })

  // Create audio context
  let audio_ctx = @audio.AudioContext::new()

  // User input signals (sources of truth)
  let chord_input = @signal.signal(app_state.get().chord_input)
  let tempo = @signal.signal(app_state.get().tempo_bpm)
  let volume = @signal.signal(app_state.get().volume)
  let is_muted = @signal.signal(app_state.get().is_muted)

  // Reactive note generation when chord input changes
  let _ = @signal.effect(fn() {
    let input = chord_input.get()
    if input.length() == 0 {
      app_state.update(fn(s) {
        AppState::{ ..s, notes: [], chord_input: input }
      })
    } else {
      let chords = @music.parse_chord_progression(input)
      if chords.length() > 0 {
        let settings = @music.ImprovisationSettings::default()
        let notes = @music.generate_improvisation(chords, settings)
        let current_tempo = tempo.get()
        let total_ms = @audio.calculate_total_duration(notes, current_tempo)
        app_state.update(fn(s) {
          AppState::{
            ..s,
            notes,
            total_duration_ms: total_ms,
            chord_input: input,
          }
        })
      } else {
        app_state.update(fn(s) {
          AppState::{ ..s, notes: [], chord_input: input }
        })
      }
    }
  })

  // Sync user inputs to app_state
  let _ = @signal.effect(fn() {
    let t = tempo.get()
    app_state.update(fn(s) {
      let total_ms = if s.notes.length() > 0 {
        @audio.calculate_total_duration(s.notes, t)
      } else {
        0
      }
      AppState::{ ..s, tempo_bpm: t, total_duration_ms: total_ms }
    })
  })
  let _ = @signal.effect(fn() {
    let v = volume.get()
    app_state.update(fn(s) { AppState::{ ..s, volume: v } })
  })
  let _ = @signal.effect(fn() {
    let m = is_muted.get()
    app_state.update(fn(s) { AppState::{ ..s, is_muted: m } })
  })

  // Tick-based main loop
  fn tick() -> Unit {
    let state = app_state.get()
    match state.mode {
      Stopped(_) => () // No-op when stopped
      Playing(started_at_ms, started_from_position, _audio_start) => {
        let now_ms = @date.Date::now()
        let elapsed_ms = now_ms - started_at_ms
        let current_pos = started_from_position + elapsed_ms

        // Schedule audio in lookahead window
        @audio.schedule_notes_in_window(
          audio_ctx,
          state.notes,
          state.tempo_bpm,
          current_pos,
          100,
        )

        // Check for end of playback
        if current_pos >= state.total_duration_ms {
          app_state.update(fn(s) {
            AppState::{ ..s, mode: PlaybackMode::Stopped(s.total_duration_ms) }
          })
        }
      }
    }
  }

  // Start requestAnimationFrame loop
  fn start_tick_loop() -> Unit {
    fn loop_fn(_time : Double) -> Unit {
      tick()
      @js_dom.window().requestAnimationFrame(loop_fn) |> ignore
    }

    @js_dom.window().requestAnimationFrame(loop_fn) |> ignore
  }

  start_tick_loop()

  // Event handlers
  fn on_play_pause() -> Unit {
    let state = app_state.get()
    if state.notes.length() == 0 {
      return
    }
    match state.mode {
      Stopped(position_ms) => {
        // Start playing from current position
        let now_ms = @date.Date::now()
        let audio_start = audio_ctx.current_time()
        app_state.update(fn(s) {
          AppState::{
            ..s,
            mode: PlaybackMode::Playing(now_ms, position_ms, audio_start),
          }
        })
      }
      Playing(_, started_from, _) => {
        // Stop and preserve position
        let now_ms = @date.Date::now()
        let current_pos = started_from + (now_ms - started_from)
        app_state.update(fn(s) {
          AppState::{ ..s, mode: PlaybackMode::Stopped(current_pos) }
        })
      }
    }
  }

  fn on_seek(position_percent : Double) -> Unit {
    let state = app_state.get()
    if state.notes.length() == 0 {
      return
    }
    let new_position_ms = (position_percent /
    100.0 *
    state.total_duration_ms.to_double()).to_int()
    match state.mode {
      Stopped(_) =>
        // Just update position
        app_state.update(fn(s) {
          AppState::{ ..s, mode: PlaybackMode::Stopped(new_position_ms) }
        })
      Playing(_, _, _) => {
        // Restart from new position
        let now_ms = @date.Date::now()
        let audio_start = audio_ctx.current_time()
        app_state.update(fn(s) {
          AppState::{
            ..s,
            mode: PlaybackMode::Playing(now_ms, new_position_ms, audio_start),
          }
        })
      }
    }
  }

  // Derive signals for UI
  let is_playing = @signal.signal(false)
  let position_ms = @signal.signal(0)
  let total_duration_ms = @signal.signal(0)
  let has_notes = @signal.signal(false)

  // Update derived signals from app_state
  let _ = @signal.effect(fn() {
    let state = app_state.get()
    is_playing.set(
      match state.mode {
        Stopped(_) => false
        Playing(_, _, _) => true
      },
    )
    position_ms.set(
      match state.mode {
        Stopped(pos) => pos
        Playing(started_at, started_from, _) => {
          let now_ms = @date.Date::now()
          started_from + (now_ms - started_at)
        }
      },
    )
    total_duration_ms.set(state.total_duration_ms)
    has_notes.set(state.notes.length() > 0)
  })

  // Render app
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let app = @dom.div(
        class="h-screen bg-gradient-to-br from-slate-950 to-slate-900 text-white p-1 flex flex-col overflow-hidden",
        [
          @ui.render_lead_sheet(
            chord_input, on_play_pause, on_seek, is_playing, position_ms, total_duration_ms,
            has_notes, tempo, volume, is_muted,
          ),
          @dom.div(
            class="bg-slate-950 rounded-xl shadow-2xl border-2 border-slate-700 overflow-hidden flex-1 mt-2 flex flex-col",
            [@ui.render_falling_notes(), @ui.render_keyboard()],
          ),
        ],
      )
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}
