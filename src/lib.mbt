///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  @ui.setup_error_overlay()
  let state = @ui.AppState::new()
  let synthesizer = @audio.Synthesizer::new()
  let tick = @music.make_tick(
    audio_output=synthesizer,
    total_duration=state.total_duration,
    bpm=fn() { state.bpm.get() },
    beats_per_measure=fn() { state.time_signature.get().beats_per_measure() },
    time_signature=fn() { state.time_signature.get() },
    playback_position=fn() { state.playback_position.get() },
    set_playback_position=fn(pos) { state.playback_position.set(pos) },
    loop_a_measure=fn() { state.loop_a_measure.get() },
    loop_b_measure=fn() { state.loop_b_measure.get() },
    jazz_style=fn() { state.jazz_style.get() },
    sounds=state.sounds,
    comping_sounds=state.comping_sounds,
    bass_sounds=state.bass_sounds,
    drum_sounds=state.drum_sounds,
    recorded_sounds=state.recorded_sounds,
  )

  let _ = @signals.effect(fn() {
    let volume = state.volume.get().to_double() / 100.0
    if state.is_playing.get() {
      synthesizer.set_master_volume(volume)
    } else {
      synthesizer.mute()
    }
  })

  @ui.setup_loop(state.is_playing, tick)
  @ui.render(state)
}
