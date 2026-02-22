///|
pub struct AppState {
  bpm : @signals.Signal[Int]
  raw_chord_progression : @signals.Signal[String]
  seed : @signals.Signal[Int]
  measure_count : @signals.Signal[Int]
  key : @signals.Signal[@music.KeySignature]
  time_signature : @signals.Signal[@music.TimeSignature]
  playback_position : @signals.Signal[@music.Duration]
  volume : @signals.Signal[Int]
  loop_a_measure : @signals.Signal[Int]
  loop_b_measure : @signals.Signal[Int]
  jazz_style : @signals.Signal[JazzStyle]
  view_mode : @signals.Signal[ViewMode]
  is_playing : @signals.Signal[Bool]
  measures : () -> Array[@music.Measure]
  sounds : () -> Array[@music.ScheduledSound]
  drum_sounds : () -> Array[@music.ScheduledSound]
  backing_sounds : () -> Array[@music.ScheduledSound]
  bass_sounds : () -> Array[@music.ScheduledSound]
  total_duration : () -> @music.Duration
  chord_parse_error : () -> String?
}

///|
pub fn AppState::new() -> AppState {
  let bpm = @signals.signal(get_initial_bpm())
  let raw_chord_progression = @signals.signal(get_initial_chords())
  let seed = @signals.signal(get_initial_seed())
  let measure_count = @signals.signal(get_initial_measures())
  let key = @signals.signal(get_initial_key())
  let time_signature = @signals.signal(get_initial_time_signature())
  let playback_position = @signals.signal(
    @music.Duration::from_milliseconds(0.0),
  )
  let volume = @signals.signal(get_initial_volume())
  let loop_a_measure = @signals.signal(get_initial_loop_a_measure())
  let loop_b_measure = @signals.signal(
    get_initial_loop_b_measure(measure_count.get()),
  )
  let jazz_style = @signals.signal(JazzStyle::default())
  let view_mode = @signals.signal(get_initial_view_mode())
  let is_playing = @signals.signal(false)

  let parsed_progression = @signals.memo(fn() {
    @music.parse_measure_progression(raw_chord_progression.get())
  })
  let measure_chords = @signals.memo(fn() {
    match parsed_progression() {
      Ok(degree_measures) => {
        let key_root = key.get().root
        degree_measures.map(fn(dm) { dm.resolve(key_root) })
      }
      Err(_) => []
    }
  })
  let chord_parse_error : () -> String? = @signals.memo(fn() {
    match parsed_progression() {
      Ok(_) => None
      Err(msg) => Some(msg)
    }
  })

  let measures = make_app_measures(
    measure_chords, seed, measure_count, bpm, key, time_signature, jazz_style,
  )
  let sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    @music.convert_measures_to_sounds(
      measures(),
      bpm.get(),
      swing=jazz_style.get().swing,
    )
  })
  let drum_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    let js = jazz_style.get()
    if not(js.drums_enabled) {
      []
    } else {
      @music.generate_drum_sounds(
        bpm.get(),
        measure_count.get(),
        time_signature=time_signature.get(),
        swing=js.swing,
        pattern_style=js.drum_pattern,
      )
    }
  })
  let backing_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    let js = jazz_style.get()
    if not(js.comping_enabled) {
      []
    } else {
      @music.generate_comping_sounds(
        measures(),
        bpm.get(),
        sounds(),
        seed=seed.get(),
        voicing_style=js.comping_style,
      )
    }
  })
  let bass_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    let js = jazz_style.get()
    if not(js.bass_enabled) {
      []
    } else {
      @music.generate_walking_bass_sounds(measures(), bpm.get(), js.bass_style)
    }
  })
  let total_duration = @signals.memo(fn() {
    @music.calculate_total_duration(
      bpm=bpm.get(),
      measure_count=measure_count.get(),
      beats_per_measure=time_signature.get().beats_per_measure(),
    )
  })

  {
    bpm,
    raw_chord_progression,
    seed,
    measure_count,
    key,
    time_signature,
    playback_position,
    volume,
    loop_a_measure,
    loop_b_measure,
    jazz_style,
    view_mode,
    is_playing,
    measures,
    sounds,
    drum_sounds,
    backing_sounds,
    bass_sounds,
    total_duration,
    chord_parse_error,
  }
}

///|
fn make_app_measures(
  measure_chords : () -> Array[Array[@music.Chord]],
  seed : @signals.Signal[Int],
  measure_count : @signals.Signal[Int],
  bpm : @signals.Signal[Int],
  key : @signals.Signal[@music.KeySignature],
  time_signature : @signals.Signal[@music.TimeSignature],
  jazz_style : @signals.Signal[JazzStyle],
) -> () -> Array[@music.Measure] {
  @signals.memo(fn() {
    let ts = time_signature.get()
    let beats_per_measure = ts.beats_per_measure()
    let settings = @generator.ImprovisationConfig::default(seed.get())
      |> @generator.ImprovisationConfig::with_techniques(
        jazz_style.get().techniques,
      )
    let music_measures = settings
      |> @generator.create_measure_generator
      |> @generator.improvisation(
        measure_chords(),
        bpm.get(),
        measure_count.get() - 2,
        key.get(),
        settings,
        time_signature=ts,
        beats_per_measure~,
        start_offset=1,
      )
    let leading_rest = @generator.leading_rest_measure(beats_per_measure~)
    let trailing_rest_start = (measure_count.get() - 1).to_double() *
      @music.ms_per_measure(bpm.get(), beats_per_measure~)
    let trailing_rest = @generator.trailing_rest_measure(
      start_time=@music.Duration::from_milliseconds(trailing_rest_start),
      beats_per_measure~,
    )
    leading_rest + music_measures + trailing_rest
  })
}
