///|
/// Schedule a single note to play at a specific time
pub fn schedule_note(
  ctx : @web_audio.AudioContext,
  midi : Int,
  start_time : Double,
  duration_sec : Double,
  volume : Double,
) -> Unit {
  // Convert MIDI to frequency: f = 440 * 2^((n-69)/12)
  let frequency = 440.0 * @math.pow(2.0, (midi.to_double() - 69.0) / 12.0)

  // Create nodes
  let osc = ctx.create_oscillator()
  let gain = ctx.create_gain()

  // Configure oscillator
  osc.set_type("sine")
  osc.set_frequency(frequency)

  // Connect nodes
  osc.connect(gain.as_any())
  gain.connect(ctx.destination())

  // Envelope
  let attack_time = 0.01
  let release_time = 0.1
  let gain_param = gain.gain()
  gain_param.set_value_at_time(0.0, start_time)
  gain_param.linear_ramp_to_value_at_time(volume, start_time + attack_time)
  gain_param.exponential_ramp_to_value_at_time(
    0.01,
    start_time + duration_sec - release_time,
  )

  // Schedule start/stop
  osc.start(start_time)
  osc.stop(start_time + duration_sec)
}

///|
/// Schedule notes in a lookahead window for smooth playback
/// This avoids setTimeout drift by using WebAudio's precise scheduling
pub fn schedule_notes_in_window(
  ctx : @web_audio.AudioContext,
  note_values : Array[@music.NoteValue],
  tempo_bpm : Int,
  current_pos_ms : Int,
  lookahead_ms : Int,
  volume : Double,
) -> Unit {
  let window_end_ms = current_pos_ms + lookahead_ms

  // Calculate position in the note sequence
  let mut position_ms = 0
  for note_value in note_values {
    let duration_ms = note_value.duration().to_ms(tempo_bpm)
    let end_ms = position_ms + duration_ms

    // Schedule audio only for actual notes (skip rests)
    match note_value {
      Note(midi=midi_val, ..) =>
        if position_ms >= current_pos_ms && position_ms < window_end_ms {
          // Convert to audio context time
          let audio_start_time = ctx.current_time() +
            (position_ms - current_pos_ms).to_double() / 1000.0
          let duration_sec = duration_ms.to_double() / 1000.0

          // Schedule the note
          schedule_note(
            ctx,
            midi_val.value,
            audio_start_time,
            duration_sec,
            volume,
          )
        }
      Rest(..) => () // Rests advance time but produce no sound
    }
    position_ms = end_ms

    // Stop if we've passed the window
    if position_ms >= window_end_ms {
      break
    }
  }
}
