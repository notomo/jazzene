///|
/// Schedule a single note to play at a specific time
fn schedule_note(
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
  bpm : Int,
  current_pos_ms : Int,
  lookahead_ms : Int,
  volume : Double,
) -> Unit {
  let sounds = @music.extract_sounds_in_window(
    note_values,
    bpm,
    current_pos_ms,
    lookahead_ms,
    ctx.current_time(),
  )
  for sound in sounds {
    schedule_note(
      ctx,
      sound.midi,
      sound.audio_start_time,
      sound.duration_sec,
      volume,
    )
  }
}
