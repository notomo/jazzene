///|
/// Bass synthesizer using oscillator synthesis (string-like sound)
struct Bass {
  ctx : @web_audio.AudioContext
  gain : @web_audio.GainNode
}

///|
/// Create a new Bass connected to master_gain
fn Bass::new(
  ctx : @web_audio.AudioContext,
  master_gain : @web_audio.GainNode,
) -> Bass {
  let gain = ctx.create_gain()
  gain.connect(master_gain.as_audio_node())
  { ctx, gain }
}

///|
/// Convert MIDI number to frequency in Hz
extern "js" fn midi_to_frequency(midi : Int) -> Double =
  #| (midi) => 440.0 * Math.pow(2, (midi - 69) / 12)

///|
/// Schedule a single bass note using oscillator synthesis (string-like sound)
fn Bass::schedule_note(
  self : Bass,
  midi : @music.MidiNumber,
  start_time : @music.Duration,
  duration : @music.Duration,
  volume : Double,
) -> Unit {
  let start_time_sec = start_time.to_seconds()
  let duration_sec = duration.to_seconds()
  let freq = midi_to_frequency(midi.value)

  // Gain envelope: quick pluck attack, exponential decay (pizzicato upright bass feel)
  let gain = self.ctx.create_gain()
  let gain_param = gain.gain()
  let attack_end = start_time_sec + 0.01
  gain_param.set_value_at_time(0.001, start_time_sec)
  gain_param.linear_ramp_to_value_at_time(volume, attack_end)
  let decay_end = attack_end + 0.15
  gain_param.exponential_ramp_to_value_at_time(volume * 0.35, decay_end)
  gain_param.exponential_ramp_to_value_at_time(
    0.001,
    start_time_sec + duration_sec,
  )
  gain.connect(self.gain.as_audio_node())

  // Low-pass filter for warm, woody string tone
  let filter = self.ctx.create_biquad_filter()
  filter.set_type("lowpass")
  filter.frequency().value = 700.0
  filter.q().value = 1.2
  filter.connect(gain.as_audio_node())

  // Sawtooth oscillator (rich harmonics like a bowed/plucked string)
  let osc = self.ctx.create_oscillator()
  osc.set_type("sawtooth")
  osc.frequency().value = freq
  osc.connect(filter.as_audio_node())
  osc.start(start_time_sec)
  osc.stop(start_time_sec + duration_sec)
}

///|
/// Schedule bass sounds for playback using string synthesis
/// Bass volume is scaled by 0.7 relative to the provided volume
fn Bass::schedule_notes(
  self : Bass,
  sounds : Array[@music.AudioSound],
  volume : Double,
) -> Unit {
  let current_time = @music.Duration::from_seconds(self.ctx.current_time())
  let scaled_volume = volume * 0.7
  for sound in sounds {
    let start_time = sound.start_time(current_time)
    self.schedule_note(sound.midi, start_time, sound.duration, scaled_volume)
  }
}
