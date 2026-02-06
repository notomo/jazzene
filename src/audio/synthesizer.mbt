///|
/// Synthesizer with master gain for volume control and muting
pub struct Synthesizer {
  ctx : @web_audio.AudioContext
  master_gain : @web_audio.GainNode
}

///|
/// Create a new Synthesizer with AudioContext and master gain
pub fn Synthesizer::new() -> Synthesizer {
  let ctx = @web_audio.AudioContext::new()
  let master_gain = ctx.create_gain()
  master_gain.connect(ctx.destination())
  { ctx, master_gain }
}

///|
/// Mute all audio immediately by setting master gain to 0
pub fn Synthesizer::mute(self : Synthesizer) -> Unit {
  let gain_param = self.master_gain.gain()
  gain_param.cancel_scheduled_values(0.0)
  gain_param.value = 0.0
}

///|
/// Unmute audio by restoring master gain to 1
pub fn Synthesizer::unmute(self : Synthesizer) -> Unit {
  let gain_param = self.master_gain.gain()
  gain_param.cancel_scheduled_values(0.0)
  gain_param.value = 1.0
}

///|
/// Schedule a single note to play at a specific time
fn schedule_note(
  synth : Synthesizer,
  midi : @music.MidiNumber,
  start_time : @music.Duration,
  duration : @music.Duration,
  volume : Double,
) -> Unit {
  let start_time_sec = start_time.to_seconds()
  let duration_sec = duration.to_seconds()
  let gain = {
    let gain = synth.ctx.create_gain()
    let attack_time = 0.01
    let release_time = 0.1
    let gain_param = gain.gain()
    gain_param.set_value_at_time(0.0, start_time_sec)
    gain_param.linear_ramp_to_value_at_time(
      volume,
      start_time_sec + attack_time,
    )
    gain_param.exponential_ramp_to_value_at_time(
      0.01,
      start_time_sec + duration_sec - release_time,
    )
    // Connect to master gain instead of destination
    gain.connect(synth.master_gain.as_audio_node())
    gain
  }
  let osc = synth.ctx.create_oscillator()
  osc.set_type("sine")
  osc.set_frequency(midi.to_frequency())
  osc.connect(gain.as_audio_node())
  osc.start(start_time_sec)
  osc.stop(start_time_sec + duration_sec)
}

///|
/// Schedule audio sounds for playback
pub fn Synthesizer::schedule_notes(
  self : Synthesizer,
  sounds : Array[@music.AudioSound],
  volume : Double,
) -> Unit {
  let current_time = @music.Duration::from_seconds(self.ctx.current_time())
  for sound in sounds {
    let start_time = sound.start_time(current_time)
    schedule_note(self, sound.midi, start_time, sound.duration, volume)
  }
}
