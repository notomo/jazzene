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
fn measure_to_duration(
  measure_number : Int,
  bpm : Int,
  beats_per_measure : Double,
) -> @music.Duration {
  let ms = (measure_number - 1).to_double() *
    @music.ms_per_measure(bpm, beats_per_measure~)
  @music.Duration::from_milliseconds(ms)
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
    let new_position = @cmp.minimum(
      state.playback_position.get() +
      @music.Duration::from_milliseconds(elapsed_ms),
      total,
    )

    // Check loop boundaries
    let final_position = {
      let beats = state.time_signature.get().beats_per_measure()
      let current_bpm = state.bpm.get()
      // B: end of the B measure (so B+1 start)
      let b_time = measure_to_duration(
        state.loop_b_measure.get() + 1,
        current_bpm,
        beats,
      )
      // A: start of the A measure
      let a_time = measure_to_duration(
        state.loop_a_measure.get(),
        current_bpm,
        beats,
      )
      if new_position < a_time {
        a_time
      } else if new_position >= b_time {
        a_time
      } else {
        new_position
      }
    }

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
