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

  let full_measures = make_app_measures(
    measure_chords, seed, measure_count, bpm, key, time_signature, jazz_style,
  )
  let full_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    @music.convert_measures_to_sounds(
      full_measures(),
      bpm.get(),
      swing=jazz_style.get().swing,
    )
  })
  let measures : () -> Array[@music.Measure] = @signals.memo(fn() {
    match jazz_style.get().melody_mode {
      @music.On | @music.Silent =>
        match imported_midi.get() {
          Some(data) if not(data.melody_sounds.is_empty()) => {
            let adapted = adapt_melody(data, bpm.get(), key.get())
            @music.sounds_to_measures(
              adapted,
              bpm.get(),
              time_signature.get(),
              measure_count.get(),
              key.get(),
            )
          }
          _ => full_measures()
        }
      @music.Off =>
        full_measures().map(fn(m) {
          @music.Measure::{
            ..m,
            beats: m.beats.map(fn(b) { @music.Beat::{ ..b, notes: [] } }),
          }
        })
    }
  })
  let sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    match jazz_style.get().melody_mode {
      @music.Off => []
      @music.On | @music.Silent =>
        match imported_midi.get() {
          Some(data) if not(data.melody_sounds.is_empty()) =>
            adapt_melody(data, bpm.get(), key.get())
          _ => full_sounds()
        }
    }
  })
  let drum_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    let js = jazz_style.get()
    match js.drum_pattern {
      @music.Imported =>
        match imported_midi.get() {
          Some(data) =>
            @music.rescale_sounds(
              data.drum_sounds,
              data.bpm.unwrap_or(bpm.get()),
              bpm.get(),
            )
          None => []
        }
      _ =>
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
    }
  })
  let backing_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    let js = jazz_style.get()
    match js.comping_style {
      @music.Imported =>
        match imported_midi.get() {
          Some(data) =>
            adapt_pitched(data, bpm.get(), key.get(), data.comping_sounds)
          None => []
        }
      _ =>
        match js.comping_mode {
          @music.Off => []
          @music.Silent | @music.On =>
            @music.generate_comping_sounds(
              full_measures(),
              bpm.get(),
              full_sounds(),
              key.get(),
              seed=seed.get(),
              voicing_style=js.comping_style,
            )
        }
    }
  })
  let bass_sounds : () -> Array[@music.ScheduledSound] = @signals.memo(fn() {
    let js = jazz_style.get()
    match js.bass_style {
      @music.Imported =>
        match imported_midi.get() {
          Some(data) =>
            adapt_pitched(data, bpm.get(), key.get(), data.bass_sounds)
          None => []
        }
      _ =>
        if not(js.bass_enabled) {
          []
        } else {
          @music.generate_walking_bass_sounds(
            full_measures(),
            bpm.get(),
            js.bass_style,
          )
        }
    }
  })
  let total_duration = @signals.memo(fn() {
    @music.calculate_total_duration(
      bpm=bpm.get(),
      measure_count=measure_count.get(),
      beats_per_measure=time_signature.get().beats_per_measure(),
    )
  })

  // When chords are entered, switch any Imported accompaniment style to generated
  let _ = @signals.effect(fn() {
    if raw_chord_progression.get() != "" {
      jazz_style.update(fn(js) {
        @music.JazzStyle::{
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
        }
      })
    }
  })

  // Persist all state changes to URL query parameters
  let _ = @signals.effect(fn() { save_bpm(bpm.get()) })
  let _ = @signals.effect(fn() { save_seed(seed.get()) })
  let _ = @signals.effect(fn() { save_measure_count(measure_count.get()) })
  let _ = @signals.effect(fn() { save_loop_a(loop_a_measure.get()) })
  let _ = @signals.effect(fn() {
    save_loop_b(loop_b_measure.get(), measure_count.get())
  })
  let _ = @signals.effect(fn() { save_volume(volume.get()) })
  let _ = @signals.effect(fn() { save_key(key.get()) })
  let _ = @signals.effect(fn() { save_time_signature(time_signature.get()) })
  let _ = @signals.effect(fn() { save_chords(raw_chord_progression.get()) })
  let _ = @signals.effect(fn() { save_view_state(view_state.get()) })
  let _ = @signals.effect(fn() { save_jazz_style(jazz_style.get()) })
  let _ = @signals.effect(fn() {
    save_show_technique_hints(show_technique_hints.get())
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
  jazz_style : @signals.Signal[@music.JazzStyle],
) -> () -> Array[@music.Measure] {
  @signals.memo(fn() {
    let ts = time_signature.get()
    let beats_per_measure = ts.beats_per_measure()
    let settings = @generator.ImprovisationConfig::default(seed.get())
      |> @generator.ImprovisationConfig::with_techniques(
        jazz_style.get().techniques,
      )
      |> @generator.ImprovisationConfig::with_pitch_range(
        jazz_style.get().pitch_min,
        jazz_style.get().pitch_max,
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

///|
/// Compute semitone shift from imported key to current key, normalized to [-6, 6]
fn key_shift(
  data : @midi.ImportedMidi,
  current_key : @music.KeySignature,
) -> Int {
  match data.key {
    None => 0
    Some(orig_key) => {
      let raw = current_key.root.midi() - orig_key.root.midi()
      if raw > 6 {
        raw - 12
      } else if raw < -6 {
        raw + 12
      } else {
        raw
      }
    }
  }
}

///|
/// Adapt melody/comping/bass sounds: rescale timing by BPM and transpose by key
fn adapt_pitched(
  data : @midi.ImportedMidi,
  current_bpm : Int,
  current_key : @music.KeySignature,
  sounds : Array[@music.ScheduledSound],
) -> Array[@music.ScheduledSound] {
  sounds
  |> @music.rescale_sounds(data.bpm.unwrap_or(current_bpm), current_bpm)
  |> @music.transpose_sounds(key_shift(data, current_key))
}

///|
/// Adapt melody sounds specifically
fn adapt_melody(
  data : @midi.ImportedMidi,
  current_bpm : Int,
  current_key : @music.KeySignature,
) -> Array[@music.ScheduledSound] {
  adapt_pitched(data, current_bpm, current_key, data.melody_sounds)
}
