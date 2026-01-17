///|
/// Create a new AudioContext
pub fn create_context() -> @web_audio.AudioContext {
  @web_audio.AudioContext::new()
}

///|
/// Schedule a single note to play at a specific time
fn schedule_note(
  ctx : @web_audio.AudioContext,
  midi : @music.MidiNumber,
  start_time : @music.Duration,
  duration : @music.Duration,
  volume : Double,
) -> Unit {
  let frequency = midi.to_frequency()

  // Create nodes
  let osc = ctx.create_oscillator()
  let gain = ctx.create_gain()

  // Configure oscillator
  osc.set_type("sine")
  osc.set_frequency(frequency)

  // Connect nodes
  osc.connect(gain.as_audio_node())
  gain.connect(ctx.destination())

  // Envelope
  let attack_time = 0.01
  let release_time = 0.1
  let start_time_sec = start_time.to_seconds()
  let duration_sec = duration.to_seconds()
  let gain_param = gain.gain()
  gain_param.set_value_at_time(0.0, start_time_sec)
  gain_param.linear_ramp_to_value_at_time(volume, start_time_sec + attack_time)
  gain_param.exponential_ramp_to_value_at_time(
    0.01,
    start_time_sec + duration_sec - release_time,
  )

  // Schedule start/stop
  osc.start(start_time_sec)
  osc.stop(start_time_sec + duration_sec)
}

///|
/// Schedule audio sounds for playback
pub fn schedule_notes(
  sounds : Array[@music.AudioSound],
  ctx : @web_audio.AudioContext,
  volume : Double,
) -> Unit {
  let current_time = @music.Duration::from_seconds(ctx.current_time())
  for sound in sounds {
    let start_time = sound.start_time(current_time)
    schedule_note(ctx, sound.midi, start_time, sound.duration, volume)
  }
}
