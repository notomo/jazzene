///|
pub struct RecordedLine {
  id : Int
  sounds : Array[@music.ScheduledSound]
  mode : @signals.Signal[@music.MelodyMode]
}

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
  is_recording : @signals.Signal[Bool]
  recorded_lines : @signals.Signal[Array[RecordedLine]]
  on_note_on : (@music.MidiNumber) -> Unit
  on_note_off : (@music.MidiNumber) -> Unit
  measures : () -> Array[@music.Measure]
  sounds : () -> Array[@music.ScheduledSound]
  drum_sounds : () -> Array[@music.ScheduledSound]
  comping_sounds : () -> Array[@music.ScheduledSound]
  bass_sounds : () -> Array[@music.ScheduledSound]
  recorded_sounds : () -> Array[@music.ScheduledSound]
  recorded_sounds_visual : () -> Array[@music.ScheduledSound]
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

  // Recording state
  let is_recording : @signals.Signal[Bool] = @signals.signal(false)
  let recorded_lines : @signals.Signal[Array[RecordedLine]] = @signals.signal([])
  let next_line_id : Ref[Int] = { val: 0 }
  // Per-note start times indexed by MIDI note value (0-127); None = not active
  let recording_note_starts : Ref[Array[@music.Duration?]] = {
    val: Array::make(128, None),
  }
  let recording_buffer : Ref[Array[@music.ScheduledSound]] = { val: [] }
  let on_note_on : (@music.MidiNumber) -> Unit = fn(midi) {
    if not(is_recording.peek()) {
      return
    }
    recording_note_starts.val[midi.value] = Some(playback_position.peek())
  }
  let on_note_off : (@music.MidiNumber) -> Unit = fn(midi) {
    if not(is_recording.peek()) {
      return
    }
    match recording_note_starts.val[midi.value] {
      None => ()
      Some(start) => {
        recording_note_starts.val[midi.value] = None
        let dur = playback_position.peek() - start
        if dur.to_milliseconds() <= 0.0 {
          return
        }
        let beat_dur = @music.NoteDuration::from_beats(
          dur.to_milliseconds() / @music.ms_per_beat(bpm.peek()),
        )
        let sound = @music.ScheduledSound::{
          sound_event: @music.Note(midi~, duration=beat_dur),
          duration: dur,
          start_time: start,
          tone_origin: Some(@music.ToneOrigin::Recorded),
          beat_position: 0.0,
        }
        recording_buffer.val.push(sound)
      }
    }
  }
  // When recording stops, commit the buffer as a new RecordedLine
  let _ = @signals.effect(fn() {
    if not(is_recording.get()) {
      let sounds = recording_buffer.val
      if not(sounds.is_empty()) {
        let id = next_line_id.val
        next_line_id.val = id + 1
        recorded_lines.update(fn(lines) {
          let new_lines = lines.copy()
          new_lines.push(RecordedLine::{
            id,
            sounds,
            mode: @signals.signal(@music.On),
          })
          new_lines
        })
      }
      recording_buffer.val = []
      recording_note_starts.val = Array::make(128, None)
    }
  })
  let recorded_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    recorded_lines
    .get()
    .iter()
    .filter(fn(line) { line.mode.get() == @music.On })
    .flat_map(fn(line) { line.sounds.iter() })
    .collect()
  })
  let recorded_sounds_visual : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
      recorded_lines
      .get()
      .iter()
      .filter(fn(line) { line.mode.get() != @music.Off })
      .flat_map(fn(line) { line.sounds.iter() })
      .collect()
    },
  )

  // When chords are entered, switch any Imported accompaniment style to generated
  // and clear imported MIDI so melody also falls back to generated
  let _ = @signals.effect(fn() {
    if raw_chord_progression.get() != "" {
      let style = jazz_style.peek()
      jazz_style.set(@music.JazzStyle::{
        ..style,
        comping_style: match style.comping_style {
          @music.Imported => @music.GuideTones
          _ => style.comping_style
        },
        bass_style: match style.bass_style {
          @music.Imported => @music.WalkingBass
          _ => style.bass_style
        },
        drum_pattern: match style.drum_pattern {
          @music.Imported => @music.SwingRide
          _ => style.drum_pattern
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
    is_recording,
    recorded_lines,
    on_note_on,
    on_note_off,
    measures,
    sounds,
    drum_sounds,
    comping_sounds,
    bass_sounds,
    recorded_sounds,
    recorded_sounds_visual,
    total_duration,
    chord_parse_error,
  }
}
