///|
/// Jazzene - Jazz Improvisation Web App (Tick-based Architecture)
fn main {
  let bpm = @signal.signal(200)
  let raw_chord_progression = @signal.signal("Cm7 F7 Bbmaj7 Ebmaj7")
  let seed = @signal.signal(0)
  let chord_parse_error : @signal.Signal[String?] = @signal.signal(None)
  let sounds = make_sounds(raw_chord_progression, seed, bpm, chord_parse_error)
  let total_duration = @signal.memo(fn() {
    @music.calculate_total_duration(sounds.get())
  })
  let playback_position = @signal.signal(
    @music.Duration::from_milliseconds(0.0),
  )
  let volume = @signal.signal(0.3)
  let loop_state = @ui.create_loop_state(total_duration)
  let tick = make_tick(
    playback_position, volume, sounds, total_duration, loop_state,
  )
  let is_playing = @signal.signal(false)
  let _ = @signal.effect(fn() {
    let total = total_duration()
    if not(loop_state.b_manually_set.get()) {
      loop_state.b_time.set(total)
    }
  })
  @ui.setup_loop(is_playing, tick)
  @ui.render(
    is_playing, playback_position, volume, bpm, raw_chord_progression, seed, sounds,
    total_duration, loop_state, chord_parse_error,
  )
}

///|
fn make_sounds(
  raw_chord_progression : @signal.Signal[String],
  seed : @signal.Signal[Int],
  bpm : @signal.Signal[Int],
  chord_parse_error : @signal.Signal[String?],
) -> @signal.Signal[Array[@music.NoteValueSound]] {
  let note_values = @signal.memo(fn() {
    let settings = @music.ImprovisationSettings::{
      notes_per_measure: 4,
      seed: seed.get(),
    }
    match @music.parse_chord_progression(raw_chord_progression.get()) {
      Ok(chords) => {
        chord_parse_error.set(None)
        @music.generate_improvisation(chords, settings)
      }
      Err(error_msg) => {
        chord_parse_error.set(Some(error_msg))
        []
      }
    }
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
      let a_enabled = loop_state.a_enabled.get()
      let b_enabled = loop_state.b_enabled.get()
      let loop_end = if b_enabled { loop_state.b_time.get() } else { total }
      let loop_start = if a_enabled {
        loop_state.a_time.get()
      } else {
        @music.Duration::from_milliseconds(0.0)
      }
      // If exceeded loop end, jump to loop start
      if new_position >= loop_end && (a_enabled || b_enabled) {
        loop_start
      } else {
        new_position
      }
    }
    @music.slice_notes(sounds.get(), final_position, lookahead)
    |> @audio.schedule_notes(audio_ctx, final_position, volume.get())
    playback_position.set(final_position)
    let stop = if loop_state.a_enabled.get() || loop_state.b_enabled.get() {
      false
    } else {
      final_position == total
    }
    stop
  }
}
