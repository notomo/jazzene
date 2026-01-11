///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  let bpm = @signal.signal(200)
  let raw_chord_progression = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let sounds = make_sounds(raw_chord_progression, bpm)
  let total_duration = @signal.memo(fn() {
    @music.calculate_total_duration(sounds.get())
  })
  let playback_position = @signal.signal(
    @music.Duration::from_milliseconds(0.0),
  )
  let volume = @signal.signal(0.3)
  let tick = make_tick(playback_position, volume, sounds, total_duration)
  let is_playing = @signal.signal(false)
  @ui.setup_loop(is_playing, tick)
  @ui.render(
    is_playing, playback_position, volume, bpm, raw_chord_progression, sounds, total_duration,
  )
}

///|
fn make_sounds(
  raw_chord_progression : @signal.Signal[String],
  bpm : @signal.Signal[Int],
) -> @signal.Signal[Array[@music.NoteValueSound]] {
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
  sounds
}

///|
fn make_tick(
  playback_position : @signal.Signal[@music.Duration],
  volume : @signal.Signal[Double],
  sounds : @signal.Signal[Array[@music.NoteValueSound]],
  total_duration : () -> @music.Duration,
) -> (Double) -> Bool {
  let audio_ctx = @audio.create_context()
  let lookahead = @music.Duration::from_milliseconds(100)
  return fn(elapsed_ms : Double) -> Bool {
    let total = total_duration()
    let new_position = @cmp.minimum(
      playback_position.get() + @music.Duration::from_milliseconds(elapsed_ms),
      total,
    )
    @music.slice_notes(sounds.get(), new_position, lookahead)
    |> @audio.schedule_notes(audio_ctx, new_position, volume.get())
    playback_position.set(new_position)
    let stop = new_position == total
    stop
  }
}
