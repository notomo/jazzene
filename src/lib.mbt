///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  let state = @ui.AppState::new()

  let synth = @audio.Synthesizer::new()
  synth.load_samples()
  let drum_synth = @audio.DrumSynth::new(
    synth.audio_context(),
    synth.destination(),
  )

  let tick = make_tick(state, synth, drum_synth)

  let _ = @signals.effect(fn() {
    if state.is_playing.get() {
      synth.unmute()
      drum_synth.unmute()
    } else {
      synth.mute()
      drum_synth.mute()
    }
  })

  @ui.setup_loop(state.is_playing, tick)
  @ui.render(state)
}

///|
fn make_tick(
  state : @ui.AppState,
  synth : @audio.Synthesizer,
  drum_synth : @audio.DrumSynth,
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

    let audio_sounds = @music.AudioSound::from(
      (state.sounds)(),
      final_position,
      lookahead,
    )
    synth.schedule_notes(audio_sounds, state.volume.get().to_double() / 100.0)

    let drum_audio_sounds = @music.AudioSound::from(
      (state.drum_sounds)(),
      final_position,
      lookahead,
    )
    drum_synth.schedule_notes(
      drum_audio_sounds,
      state.volume.get().to_double() / 100.0,
    )

    let backing_audio_sounds = @music.AudioSound::from(
      (state.backing_sounds)(),
      final_position,
      lookahead,
    )
    synth.schedule_notes(
      backing_audio_sounds,
      state.volume.get().to_double() / 100.0,
    )

    let bass_audio_sounds = @music.AudioSound::from(
      (state.bass_sounds)(),
      final_position,
      lookahead,
    )
    synth.schedule_bass_notes(
      bass_audio_sounds,
      state.volume.get().to_double() / 100.0 * 0.7,
    )

    state.playback_position.set(final_position)
    false
  }
}
