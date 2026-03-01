///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  let state = @ui.AppState::new()
  let synthesizer = @audio.Synthesizer::new()
  let tick = make_tick(state, synthesizer)

  let _ = @signals.effect(fn() {
    if state.is_playing.get() {
      synthesizer.unmute()
    } else {
      synthesizer.mute()
    }
  })

  @ui.setup_loop(state.is_playing, tick)
  @ui.render(state)
}

///|
fn make_tick(
  state : @ui.AppState,
  synthesizer : @audio.Synthesizer,
) -> (Double) -> Bool {
  let lookahead = @music.Duration::from_milliseconds(100)

  return fn(elapsed_ms : Double) -> Bool {
    let total = (state.total_duration)()
    let beats = state.time_signature.get().beats_per_measure()
    let current_bpm = state.bpm.get()
    let final_position = @music.advance_playback_position(
      state.playback_position.get(),
      elapsed_ms,
      total,
      current_bpm,
      beats,
      state.loop_a_measure.get(),
      state.loop_b_measure.get(),
    )

    let audio_sounds = match state.jazz_style.get().melody_mode {
      @ui.On =>
        @music.AudioSound::from((state.sounds)(), final_position, lookahead)
      @ui.Silent | @ui.Off => []
    }
    let backing_audio_sounds = match state.jazz_style.get().comping_mode {
      @ui.Silent => []
      _ =>
        @music.AudioSound::from(
          (state.backing_sounds)(),
          final_position,
          lookahead,
        )
    }
    let bass_audio_sounds = @music.AudioSound::from(
      (state.bass_sounds)(),
      final_position,
      lookahead,
    )
    let drum_audio_sounds = @music.AudioSound::from(
      (state.drum_sounds)(),
      final_position,
      lookahead,
    )
    synthesizer.schedule_sounds(
      piano_sounds=audio_sounds,
      comping_sounds=backing_audio_sounds,
      bass_sounds=bass_audio_sounds,
      drum_sounds=drum_audio_sounds,
      volume=state.volume.get().to_double() / 100.0,
    )

    state.playback_position.set(final_position)
    false
  }
}
