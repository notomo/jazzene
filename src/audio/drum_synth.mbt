///|
/// Drum synthesizer using oscillator-based synthesis
pub struct DrumSynth {
  ctx : @web_audio.AudioContext
  master_gain : @web_audio.GainNode
  /// Volume scale relative to piano (0.0–1.0)
  volume_scale : Double
}

///|
/// Create a new DrumSynth sharing an existing AudioContext
pub fn DrumSynth::new(
  ctx : @web_audio.AudioContext,
  destination : @web_audio.AudioNode,
  volume_scale? : Double = 0.4,
) -> DrumSynth {
  let master_gain = ctx.create_gain()
  master_gain.connect(destination)
  DrumSynth::{ ctx, master_gain, volume_scale }
}

///|
/// Mute drum output
pub fn DrumSynth::mute(self : DrumSynth) -> Unit {
  let gain_param = self.master_gain.gain()
  gain_param.cancel_scheduled_values(0.0)
  gain_param.value = 0.0
}

///|
/// Unmute drum output
pub fn DrumSynth::unmute(self : DrumSynth) -> Unit {
  let gain_param = self.master_gain.gain()
  gain_param.cancel_scheduled_values(0.0)
  gain_param.value = 1.0
}

///|
/// Schedule a kick drum hit
/// Low-frequency sine with pitch sweep (60Hz→30Hz) and fast decay
fn DrumSynth::schedule_kick(
  self : DrumSynth,
  start_time : Double,
  velocity : Double,
) -> Unit {
  let duration = 0.15
  let osc = self.ctx.create_oscillator()
  osc.set_type("sine")
  let freq = osc.frequency()
  freq.set_value_at_time(60.0, start_time)
  freq.exponential_ramp_to_value_at_time(30.0, start_time + duration)
  let gain = self.ctx.create_gain()
  let gain_param = gain.gain()
  gain_param.set_value_at_time(velocity, start_time)
  gain_param.exponential_ramp_to_value_at_time(0.001, start_time + duration)
  osc.connect(gain.as_audio_node())
  gain.connect(self.master_gain.as_audio_node())
  osc.start(start_time)
  osc.stop(start_time + duration)
}

///|
/// Schedule a snare drum hit
/// Mid-frequency triangle with high-frequency square for noise-like texture
fn DrumSynth::schedule_snare(
  self : DrumSynth,
  start_time : Double,
  velocity : Double,
) -> Unit {
  let duration = 0.1
  // Body: triangle wave at 200Hz
  let body = self.ctx.create_oscillator()
  body.set_type("triangle")
  body.frequency().set_value_at_time(200.0, start_time)
  let body_gain = self.ctx.create_gain()
  let body_gain_param = body_gain.gain()
  body_gain_param.set_value_at_time(velocity * 0.6, start_time)
  body_gain_param.exponential_ramp_to_value_at_time(
    0.001,
    start_time + duration,
  )
  body.connect(body_gain.as_audio_node())
  body_gain.connect(self.master_gain.as_audio_node())
  body.start(start_time)
  body.stop(start_time + duration)
  // Noise-like: square wave at high frequency
  let noise = self.ctx.create_oscillator()
  noise.set_type("square")
  noise.frequency().set_value_at_time(800.0, start_time)
  let noise_gain = self.ctx.create_gain()
  let noise_gain_param = noise_gain.gain()
  noise_gain_param.set_value_at_time(velocity * 0.3, start_time)
  noise_gain_param.exponential_ramp_to_value_at_time(
    0.001,
    start_time + duration * 0.7,
  )
  noise.connect(noise_gain.as_audio_node())
  noise_gain.connect(self.master_gain.as_audio_node())
  noise.start(start_time)
  noise.stop(start_time + duration)
}

///|
/// Schedule a hi-hat hit
/// High-frequency square wave with very fast decay
fn DrumSynth::schedule_hihat(
  self : DrumSynth,
  start_time : Double,
  velocity : Double,
) -> Unit {
  let duration = 0.05
  let osc = self.ctx.create_oscillator()
  osc.set_type("square")
  osc.frequency().set_value_at_time(800.0, start_time)
  let gain = self.ctx.create_gain()
  let gain_param = gain.gain()
  gain_param.set_value_at_time(velocity * 0.3, start_time)
  gain_param.exponential_ramp_to_value_at_time(0.001, start_time + duration)
  osc.connect(gain.as_audio_node())
  gain.connect(self.master_gain.as_audio_node())
  osc.start(start_time)
  osc.stop(start_time + duration)
}

///|
/// Schedule drum sounds from AudioSound array
/// Identifies drum voice from MIDI number and dispatches to appropriate synthesis
pub fn DrumSynth::schedule_notes(
  self : DrumSynth,
  sounds : Array[@music.AudioSound],
  volume : Double,
) -> Unit {
  let current_time = @music.Duration::from_seconds(self.ctx.current_time())
  let scaled_volume = volume * self.volume_scale
  for sound in sounds {
    let start_time = sound.start_time(current_time).to_seconds()
    match @music.DrumVoice::from_midi(sound.midi) {
      Some(Kick) => self.schedule_kick(start_time, scaled_volume)
      Some(Snare) => self.schedule_snare(start_time, scaled_volume)
      Some(HiHat) => self.schedule_hihat(start_time, scaled_volume)
      None => ()
    }
  }
}
