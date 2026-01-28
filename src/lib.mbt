///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  let bpm = @signal.signal(200)
  let raw_chord_progression = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let seed = @signal.signal(0)
  let measure_count = @signal.signal(8)
  let chord_parse_error : @signal.Signal[String?] = @signal.signal(None)
  let chords = @signal.memo(fn() {
    match @music.parse_chord_progression(raw_chord_progression.get()) {
      Ok(c) => {
        chord_parse_error.set(None)
        c
      }
      Err(error_msg) => {
        chord_parse_error.set(Some(error_msg))
        []
      }
    }
  })
  let measures_signal = make_measures(chords, seed, measure_count, bpm)
  let measures = fn() { measures_signal.get() }
  let sounds : @signal.Signal[Array[@music.NoteValueSound]] = @signal.signal([])
  let _ = @signal.effect(fn() {
    @music.convert_measures_to_sounds(measures_signal.get(), bpm.get())
    |> sound_list => { sounds.set(sound_list) }
  })
  let total_duration = @signal.memo(fn() {
    @music.calculate_total_duration(
      bpm=bpm.get(),
      measure_count=measure_count.get(),
    )
  })
  let playback_position = @signal.signal(
    @music.Duration::from_milliseconds(0.0),
  )
  let volume = @signal.signal(0.3)
  let loop_state = @ui.create_loop_state()
  let tick = make_tick(
    playback_position, volume, sounds, total_duration, loop_state,
  )
  let is_playing = @signal.signal(false)
  @ui.setup_loop(is_playing, tick)
  @ui.render(
    is_playing, playback_position, volume, bpm, raw_chord_progression, seed, measure_count,
    sounds, total_duration, loop_state, chord_parse_error, measures,
  )
}

///|
fn make_measures(
  chords : () -> Array[@music.Chord],
  seed : @signal.Signal[Int],
  measure_count : @signal.Signal[Int],
  bpm : @signal.Signal[Int],
) -> @signal.Signal[Array[@music.Measure]] {
  let measures : @signal.Signal[Array[@music.Measure]] = @signal.signal([])
  let _ = @signal.effect(fn() {
    @generator.Settings::default(seed.get())
    |> @generator.create_measure_generator
    |> @generator.improvisation(
      chords(),
      bpm.get(),
      measure_count.get() - 1,
      start_offset=1,
    )
    |> music_measures => {
      let leading_rest = @generator.leading_rest_measure(bpm.get())
      measures.set(leading_rest + music_measures)
    }
  })
  measures
}

///|
fn make_tick(
  playback_position : @signal.Signal[@music.Duration],
  volume : @signal.Signal[Double],
  sounds : @signal.Signal[Array[@music.NoteValueSound]],
  total_duration : () -> @music.Duration,
  loop_state : @ui.LoopState,
) -> (Double) -> Bool {
  let audio_ctx = @audio.create_context()
  let lookahead = @music.Duration::from_milliseconds(100)
  return fn(elapsed_ms : Double) -> Bool {
    let total = total_duration()
    let new_position = @cmp.minimum(
      playback_position.get() + @music.Duration::from_milliseconds(elapsed_ms),
      total,
    )
    // Check loop boundaries
    let final_position = {
      let enabled = loop_state.enabled.get()
      let b_time = loop_state.b_time.get().unwrap_or(total)
      if enabled && new_position >= b_time {
        loop_state.a_time.get()
      } else {
        new_position
      }
    }
    @music.AudioSound::from(sounds.get(), final_position, lookahead)
    |> @audio.schedule_notes(audio_ctx, volume.get())
    playback_position.set(final_position)
    let stop = if loop_state.enabled.get() {
      false
    } else {
      final_position == total
    }
    stop
  }
}
