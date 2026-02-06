///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  let bpm = @signal.signal(@ui.get_initial_int("bpm", 200))
  let raw_chord_progression = @signal.signal("IIm7 | V7 | Imaj7 | IVmaj7")
  let seed = @signal.signal(@ui.get_initial_int("seed", 0))
  let measure_count = @signal.signal(@ui.get_initial_int("measures", 8))
  let key = @signal.signal(@ui.get_initial_key())
  let time_signature = @signal.signal(@music.TimeSignature::default())
  let chord_parse_error : @signal.Signal[String?] = @signal.signal(None)
  let measure_chords = @signal.memo(fn() {
    match @music.parse_measure_progression(raw_chord_progression.get()) {
      Ok(degree_measures) => {
        chord_parse_error.set(None)
        let key_root = key.get().root
        degree_measures.map(fn(dm) { dm.resolve(key_root) })
      }
      Err(error_msg) => {
        chord_parse_error.set(Some(error_msg))
        []
      }
    }
  })
  let measures_signal = make_measures(
    measure_chords, seed, measure_count, bpm, key, time_signature,
  )
  let measures = fn() { measures_signal.get() }
  let swing = @signal.signal(@music.SwingConfig::triplet())
  let sounds : @signal.Signal[Array[@music.NoteValueSound]] = @signal.signal([])
  let _ = @signal.effect(fn() {
    @music.convert_measures_to_sounds(
      measures_signal.get(),
      bpm.get(),
      swing=swing.get(),
    )
    |> sound_list => { sounds.set(sound_list) }
  })
  let total_duration = @signal.memo(fn() {
    @music.calculate_total_duration(
      bpm=bpm.get(),
      measure_count=measure_count.get(),
      beats_per_measure=time_signature.get().beats_per_measure(),
    )
  })
  let playback_position = @signal.signal(
    @music.Duration::from_milliseconds(0.0),
  )
  let volume = @signal.signal(0.3)
  let loop_enabled = @signal.signal(false)
  let loop_a_time = @signal.signal(@music.Duration::from_milliseconds(0.0))
  let loop_b_time : @signal.Signal[@music.Duration?] = @signal.signal(None)
  let tick = make_tick(
    playback_position, volume, sounds, total_duration, loop_enabled, loop_a_time,
    loop_b_time,
  )
  let is_playing = @signal.signal(false)
  @ui.setup_loop(is_playing, tick)
  @ui.render(
    is_playing, playback_position, volume, bpm, raw_chord_progression, seed, measure_count,
    sounds, total_duration, loop_enabled, loop_a_time, loop_b_time, chord_parse_error,
    measures, key, time_signature,
  )
}

///|
fn make_measures(
  measure_chords : () -> Array[Array[@music.Chord]],
  seed : @signal.Signal[Int],
  measure_count : @signal.Signal[Int],
  bpm : @signal.Signal[Int],
  key : @signal.Signal[@music.KeySignature],
  time_signature : @signal.Signal[@music.TimeSignature],
) -> @signal.Signal[Array[@music.Measure]] {
  let measures : @signal.Signal[Array[@music.Measure]] = @signal.signal([])
  let _ = @signal.effect(fn() {
    let beats_per_measure = time_signature.get().beats_per_measure()
    let settings = @generator.Settings::default(seed.get())
    settings
    |> @generator.create_measure_generator
    |> @generator.improvisation(
      measure_chords(),
      bpm.get(),
      measure_count.get() - 1,
      key.get(),
      settings,
      beats_per_measure~,
      start_offset=1,
    )
    |> music_measures => {
      let leading_rest = @generator.leading_rest_measure()
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
  loop_enabled : @signal.Signal[Bool],
  loop_a_time : @signal.Signal[@music.Duration],
  loop_b_time : @signal.Signal[@music.Duration?],
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
      let enabled = loop_enabled.get()
      let b_time = loop_b_time.get().unwrap_or(total)
      if enabled && new_position >= b_time {
        loop_a_time.get()
      } else {
        new_position
      }
    }
    @music.AudioSound::from(sounds.get(), final_position, lookahead)
    |> @audio.schedule_notes(audio_ctx, volume.get())
    playback_position.set(final_position)
    let stop = if loop_enabled.get() { false } else { final_position == total }
    stop
  }
}
