///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  let bpm = @signal.signal(200)
  let raw_chord_progression = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let note_values = @signal.memo(fn() {
    raw_chord_progression.get()
    |> @music.parse_chord_progression
    |> @music.generate_improvisation(@music.ImprovisationSettings::default())
  })
  let sounds : @signal.Signal[Array[@music.NoteValueSound]] = @signal.signal([])
  let _ = @signal.effect(fn() {
    let sound_list = @music.NoteValueSound::from_note_values(
      note_values(),
      bpm.get(),
    )
    sounds.set(sound_list)
  })
  let total_duration = @signal.memo(fn() {
    @music.calculate_total_duration(sounds.get())
  })
  let playback_position = @signal.signal(
    @music.Duration::from_milliseconds(0.0),
  )
  let volume = @signal.signal(0.3)
  let audio_ctx = @audio.create_context()
  fn tick(elapsed_ms : Double) -> Bool {
    let pos = playback_position.get() +
      @music.Duration::from_milliseconds(elapsed_ms)
    let total = total_duration()
    let current_pos = if pos < total { pos } else { total }
    let lookahead = @music.Duration::from_milliseconds(100)
    @music.slice_notes(sounds.get(), current_pos, lookahead)
    |> @audio.schedule_notes(audio_ctx, current_pos, volume.get())
    playback_position.set(current_pos)
    current_pos >= total
  }

  let is_playing = @signal.signal(false)
  @ui.setup_loop(is_playing, tick)
  @ui.render(
    is_playing, playback_position, volume, bpm, raw_chord_progression, sounds, total_duration,
  )
}
