///|
/// Drum synthesizer using noise buffer + oscillator hybrid synthesis
pub struct DrumSynth {
  ctx : @web_audio.AudioContext
  master_gain : @web_audio.GainNode
  /// Pre-generated white noise buffer (reused for every hit)
  noise_buffer : @web_audio.AudioBuffer
  /// Volume scale relative to piano (0.0–1.0)
  volume_scale : Double
}

///|
/// Create a new DrumSynth sharing an existing AudioContext
pub fn DrumSynth::new(
  ctx : @web_audio.AudioContext,
  destination : @web_audio.AudioNode,
  volume_scale? : Double = 0.2,
) -> DrumSynth {
  let master_gain = ctx.create_gain()
  master_gain.connect(destination)
  // Pre-generate 0.3s of white noise (long enough for any single hit)
  let noise_buffer = create_noise_buffer(ctx, 0.3)
  DrumSynth::{ ctx, master_gain, noise_buffer, volume_scale }
}

///|
/// Create a white noise AudioBuffer filled with random values (-1.0 to 1.0)
fn create_noise_buffer(
  ctx : @web_audio.AudioContext,
  duration_seconds : Double,
) -> @web_audio.AudioBuffer {
  ffi_create_noise_buffer(ctx, duration_seconds)
}

///|
extern "js" fn ffi_create_noise_buffer(
  ctx : @web_audio.AudioContext,
  duration_seconds : Double,
) -> @web_audio.AudioBuffer =
  #| (ctx, dur) => {
  #|   const sr = ctx.sampleRate;
  #|   const len = Math.ceil(sr * dur);
  #|   const buf = ctx.createBuffer(1, len, sr);
  #|   const data = buf.getChannelData(0);
  #|   for (let i = 0; i < len; i++) data[i] = Math.random() * 2 - 1;
  #|   return buf;
  #| }

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
/// Play a noise burst through a gain envelope
fn DrumSynth::play_noise(
  self : DrumSynth,
  start_time : Double,
  duration : Double,
  volume : Double,
) -> @web_audio.GainNode {
  let source = self.ctx.create_buffer_source()
  source.set_buffer(self.noise_buffer)
  let gain = self.ctx.create_gain()
  let gain_param = gain.gain()
  gain_param.set_value_at_time(volume, start_time)
  gain_param.exponential_ramp_to_value_at_time(0.001, start_time + duration)
  source.connect(gain.as_audio_node())
  gain.connect(self.master_gain.as_audio_node())
  source.start(start_time)
  source.stop(start_time + duration)
  gain
}

///|
/// Schedule a kick drum hit
/// Sine oscillator with pitch sweep (150Hz→40Hz) for a punchy low-end thump
fn DrumSynth::schedule_kick(
  self : DrumSynth,
  start_time : Double,
  velocity : Double,
) -> Unit {
  let duration = 0.25
  // Tone body: sine with pitch sweep for punch
  let osc = self.ctx.create_oscillator()
  osc.set_type("sine")
  let freq = osc.frequency()
  freq.set_value_at_time(150.0, start_time)
  freq.exponential_ramp_to_value_at_time(40.0, start_time + 0.06)
  let gain = self.ctx.create_gain()
  let gain_param = gain.gain()
  gain_param.set_value_at_time(velocity * 1.2, start_time)
  gain_param.exponential_ramp_to_value_at_time(0.001, start_time + duration)
  osc.connect(gain.as_audio_node())
  gain.connect(self.master_gain.as_audio_node())
  osc.start(start_time)
  osc.stop(start_time + duration)
  // Click transient: short noise burst for attack
  self.play_noise(start_time, 0.02, velocity * 0.3) |> ignore
}

///|
/// Schedule a snare drum hit
/// Noise burst for the snare rattle + triangle oscillator for the body tone
fn DrumSynth::schedule_snare(
  self : DrumSynth,
  start_time : Double,
  velocity : Double,
) -> Unit {
  let duration = 0.15
  // Noise component: the characteristic snare rattle
  self.play_noise(start_time, duration, velocity * 0.7) |> ignore
  // Body tone: triangle wave for warmth
  let body = self.ctx.create_oscillator()
  body.set_type("triangle")
  let freq = body.frequency()
  freq.set_value_at_time(180.0, start_time)
  freq.exponential_ramp_to_value_at_time(120.0, start_time + duration)
  let body_gain = self.ctx.create_gain()
  let body_gain_param = body_gain.gain()
  body_gain_param.set_value_at_time(velocity * 0.4, start_time)
  body_gain_param.exponential_ramp_to_value_at_time(
    0.001,
    start_time + duration * 0.6,
  )
  body.connect(body_gain.as_audio_node())
  body_gain.connect(self.master_gain.as_audio_node())
  body.start(start_time)
  body.stop(start_time + duration)
}

///|
/// Schedule a hi-hat hit
/// Filtered noise burst for metallic shimmer
fn DrumSynth::schedule_hihat(
  self : DrumSynth,
  start_time : Double,
  velocity : Double,
) -> Unit {
  let duration = 0.08
  // Noise burst: short and bright for metallic character
  self.play_noise(start_time, duration, velocity * 0.4) |> ignore
  // Add high-frequency shimmer with detuned square oscillators
  [1100.0, 1500.0].each(fn(hz) {
    let osc = self.ctx.create_oscillator()
    osc.set_type("square")
    osc.frequency().set_value_at_time(hz, start_time)
    let gain = self.ctx.create_gain()
    let gain_param = gain.gain()
    gain_param.set_value_at_time(velocity * 0.06, start_time)
    gain_param.exponential_ramp_to_value_at_time(0.001, start_time + duration)
    osc.connect(gain.as_audio_node())
    gain.connect(self.master_gain.as_audio_node())
    osc.start(start_time)
    osc.stop(start_time + duration)
  })
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
