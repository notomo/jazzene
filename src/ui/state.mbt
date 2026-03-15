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
  jazz_style : @signals.Signal[@music.JazzStyle]
  show_technique_hints : @signals.Signal[Bool]
  view_state : @signals.Signal[ViewState]
  is_playing : @signals.Signal[Bool]
  midi_active_notes : @signals.Signal[Array[@music.MidiNumber]]
  imported_midi : @signals.Signal[@midi.ImportedMidi?]
  measures : () -> Array[@music.Measure]
  sounds : () -> Array[@music.ScheduledSound]
  drum_sounds : () -> Array[@music.ScheduledSound]
  comping_sounds : () -> Array[@music.ScheduledSound]
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
  let jazz_style = @signals.signal(get_initial_jazz_style())
  let show_technique_hints = @signals.signal(get_initial_show_technique_hints())
  let view_state = @signals.signal(get_initial_view_state())
  let is_playing = @signals.signal(false)
  let midi_active_notes : @signals.Signal[Array[@music.MidiNumber]] = @signals.signal([],
  )
  let imported_midi : @signals.Signal[@midi.ImportedMidi?] = @signals.signal(
    None,
  )

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

  let full_measures : () -> Array[@music.Measure] = @signals.memo(fn() {
    @generator.generate_full_measures(
      measure_chords(),
      seed.get(),
      measure_count.get(),
      bpm.get(),
      key.get(),
      time_signature.get(),
      jazz_style.get(),
    )
  })
  let full_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    @music.convert_measures_to_sounds(
      full_measures(),
      bpm.get(),
      swing=jazz_style.get().swing,
    )
  })
  let measures : () -> Array[@music.Measure] = @signals.memo(fn() {
    @midi.select_measures(
      jazz_style.get().melody_mode,
      imported_midi.get(),
      full_measures(),
      bpm.get(),
      time_signature.get(),
      measure_count.get(),
      key.get(),
    )
  })
  let sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    @midi.select_melody_sounds(
      jazz_style.get().melody_mode,
      imported_midi.get(),
      full_sounds(),
      bpm.get(),
      key.get(),
    )
  })
  let drum_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    @midi.select_drum_sounds(
      jazz_style.get(),
      imported_midi.get(),
      bpm.get(),
      measure_count.get(),
      time_signature.get(),
    )
  })
  let comping_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    @midi.select_comping_sounds(
      jazz_style.get(),
      imported_midi.get(),
      full_measures(),
      bpm.get(),
      full_sounds(),
      key.get(),
      seed.get(),
    )
  })
  let bass_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    @midi.select_bass_sounds(
      jazz_style.get(),
      imported_midi.get(),
      full_measures(),
      bpm.get(),
      key.get(),
    )
  })
  let total_duration = @signals.memo(fn() {
    @music.calculate_total_duration(
      bpm=bpm.get(),
      measure_count=measure_count.get(),
      beats_per_measure=time_signature.get().beats_per_measure(),
    )
  })

  // When chords are entered, switch any Imported accompaniment style to generated
  // and clear imported MIDI so melody also falls back to generated
  let _ = @signals.effect(fn() {
    if raw_chord_progression.get() != "" {
      let js = jazz_style.peek()
      jazz_style.set(@music.JazzStyle::{
        ..js,
        comping_style: match js.comping_style {
          @music.Imported => @music.GuideTones
          _ => js.comping_style
        },
        bass_style: match js.bass_style {
          @music.Imported => @music.WalkingBass
          _ => js.bass_style
        },
        drum_pattern: match js.drum_pattern {
          @music.Imported => @music.SwingRide
          _ => js.drum_pattern
        },
      })
      imported_midi.set(None)
    }
  })

  // Persist all state changes to URL query parameters (debounced to avoid
  // exceeding browser replaceState rate limits during rapid input like scroll)
  let url_save_timer : Ref[Int] = Ref::new(-1)
  let _ = @signals.effect(fn() {
    let bpm_val = bpm.get()
    let seed_val = seed.get()
    let measure_count_val = measure_count.get()
    let loop_a_val = loop_a_measure.get()
    let loop_b_val = loop_b_measure.get()
    let volume_val = volume.get()
    let key_val = key.get()
    let ts_val = time_signature.get()
    let chords_val = raw_chord_progression.get()
    let view_val = view_state.get()
    let jazz_val = jazz_style.get()
    let hints_val = show_technique_hints.get()
    clear_timeout(url_save_timer.val)
    url_save_timer.val = set_timeout(
      fn() {
        save_bpm(bpm_val)
        save_seed(seed_val)
        save_measure_count(measure_count_val)
        save_loop_a(loop_a_val)
        save_loop_b(loop_b_val, measure_count_val)
        save_volume(volume_val)
        save_key(key_val)
        save_time_signature(ts_val)
        save_chords(chords_val)
        save_view_state(view_val)
        save_jazz_style(jazz_val)
        save_show_technique_hints(hints_val)
      },
      400,
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
    show_technique_hints,
    view_state,
    is_playing,
    midi_active_notes,
    imported_midi,
    measures,
    sounds,
    drum_sounds,
    comping_sounds,
    bass_sounds,
    total_duration,
    chord_parse_error,
  }
}
