///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  let bpm = @signals.signal(@ui.get_initial_bpm())
  let raw_chord_progression = @signals.signal(@ui.get_initial_chords())
  let seed = @signals.signal(@ui.get_initial_seed())
  let measure_count = @signals.signal(@ui.get_initial_measures())
  let key = @signals.signal(@ui.get_initial_key())
  let time_signature = @signals.signal(@ui.get_initial_time_signature())

  // Parse once; both measure_chords and chord_parse_error derive from it.
  // This avoids signal mutation inside a memo, ensuring chord_parse_error
  // is always in sync with the parsed result without timing issues.
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

  let measures = make_measures(
    measure_chords, seed, measure_count, bpm, key, time_signature,
  )

  let swing = @signals.signal(@music.SwingConfig::triplet())
  let sounds : () -> Array[@music.NoteValueSound] = @signals.memo(fn() {
    @music.convert_measures_to_sounds(measures(), bpm.get(), swing=swing.get())
  })

  let drum_sounds : () -> Array[@music.NoteValueSound] = @signals.memo(fn() {
    @music.generate_drum_sounds(
      bpm.get(),
      measure_count.get(),
      time_signature=time_signature.get(),
      swing=swing.get(),
    )
  })

  let backing_sounds : () -> Array[@music.NoteValueSound] = @signals.memo(fn() {
    @music.convert_measures_to_backing_sounds(
      measures(),
      bpm.get(),
      sounds(),
      seed=seed.get(),
    )
  })

  let total_duration = @signals.memo(fn() {
    @music.calculate_total_duration(
      bpm=bpm.get(),
      measure_count=measure_count.get(),
      beats_per_measure=time_signature.get().beats_per_measure(),
    )
  })

  let playback_position = @signals.signal(
    @music.Duration::from_milliseconds(0.0),
  )
  let volume = @signals.signal(@ui.get_initial_volume())

  let loop_a_measure = @signals.signal(@ui.get_initial_loop_a_measure())
  let loop_b_measure = @signals.signal(
    @ui.get_initial_loop_b_measure(measure_count.get()),
  )

  let synth = @audio.Synthesizer::new()
  synth.load_samples()
  let drum_synth = @audio.DrumSynth::new(
    synth.audio_context(),
    synth.destination(),
  )

  let tick = make_tick(
    playback_position, volume, sounds, drum_sounds, backing_sounds, total_duration,
    loop_a_measure, loop_b_measure, bpm, time_signature, synth, drum_synth,
  )

  let view_mode = @signals.signal(@ui.get_initial_view_mode())
  let is_playing = @signals.signal(false)
  let _ = @signals.effect(fn() {
    if is_playing.get() {
      synth.unmute()
      drum_synth.unmute()
    } else {
      synth.mute()
      drum_synth.mute()
    }
  })

  @ui.setup_loop(is_playing, tick)
  @ui.render(
    is_playing, playback_position, volume, bpm, raw_chord_progression, seed, measure_count,
    sounds, backing_sounds, total_duration, loop_a_measure, loop_b_measure, chord_parse_error,
    measures, key, time_signature, view_mode,
  )
}

///|
fn make_measures(
  measure_chords : () -> Array[Array[@music.Chord]],
  seed : @signals.Signal[Int],
  measure_count : @signals.Signal[Int],
  bpm : @signals.Signal[Int],
  key : @signals.Signal[@music.KeySignature],
  time_signature : @signals.Signal[@music.TimeSignature],
) -> () -> Array[@music.Measure] {
  @signals.memo(fn() {
    let ts = time_signature.get()
    let beats_per_measure = ts.beats_per_measure()
    let settings = @generator.Settings::default(seed.get())
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
  playback_position : @signals.Signal[@music.Duration],
  volume : @signals.Signal[Int],
  sounds : () -> Array[@music.NoteValueSound],
  drum_sounds : () -> Array[@music.NoteValueSound],
  backing_sounds : () -> Array[@music.NoteValueSound],
  total_duration : () -> @music.Duration,
  loop_a_measure : @signals.Signal[Int],
  loop_b_measure : @signals.Signal[Int],
  bpm : @signals.Signal[Int],
  time_signature : @signals.Signal[@music.TimeSignature],
  synth : @audio.Synthesizer,
  drum_synth : @audio.DrumSynth,
) -> (Double) -> Bool {
  let lookahead = @music.Duration::from_milliseconds(100)

  return fn(elapsed_ms : Double) -> Bool {
    let total = total_duration()
    let new_position = @cmp.minimum(
      playback_position.get() + @music.Duration::from_milliseconds(elapsed_ms),
      total,
    )

    // Check loop boundaries
    let final_position = {
      let beats = time_signature.get().beats_per_measure()
      let current_bpm = bpm.get()
      // B: end of the B measure (so B+1 start)
      let b_time = measure_to_duration(
        loop_b_measure.get() + 1,
        current_bpm,
        beats,
      )
      // A: start of the A measure
      let a_time = measure_to_duration(loop_a_measure.get(), current_bpm, beats)
      if new_position < a_time {
        a_time
      } else if new_position >= b_time {
        a_time
      } else {
        new_position
      }
    }

    let audio_sounds = @music.AudioSound::from(
      sounds(),
      final_position,
      lookahead,
    )
    synth.schedule_notes(audio_sounds, volume.get().to_double() / 100.0)

    let drum_audio_sounds = @music.AudioSound::from(
      drum_sounds(),
      final_position,
      lookahead,
    )
    drum_synth.schedule_notes(
      drum_audio_sounds,
      volume.get().to_double() / 100.0,
    )

    let backing_audio_sounds = @music.AudioSound::from(
      backing_sounds(),
      final_position,
      lookahead,
    )
    synth.schedule_notes(backing_audio_sounds, volume.get().to_double() / 100.0)

    playback_position.set(final_position)
    false
  }
}
