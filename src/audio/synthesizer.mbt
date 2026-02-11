///|
/// Synthesizer with master gain for volume control and muting
pub struct Synthesizer {
  ctx : @web_audio.AudioContext
  master_gain : @web_audio.GainNode
  mut sample_bank : SampleBank?
}

///|
/// Create a new Synthesizer with AudioContext and master gain
pub fn Synthesizer::new() -> Synthesizer {
  let ctx = @web_audio.AudioContext::new()
  let master_gain = ctx.create_gain()
  master_gain.connect(ctx.destination())
  { ctx, master_gain, sample_bank: None }
}

///|
/// Get the AudioContext for sharing with other audio components
pub fn Synthesizer::audio_context(
  self : Synthesizer,
) -> @web_audio.AudioContext {
  self.ctx
}

///|
/// Get the destination node (speakers) for connecting other audio components
pub fn Synthesizer::destination(self : Synthesizer) -> @web_audio.AudioNode {
  self.ctx.destination()
}

///|
/// Load Salamander Grand Piano samples asynchronously
pub fn Synthesizer::load_samples(self : Synthesizer) -> Unit {
  load_sample_bank(self.ctx, fn(bank) { self.sample_bank = Some(bank) })
}

///|
/// Check if samples have finished loading
pub fn Synthesizer::is_loaded(self : Synthesizer) -> Bool {
  not(self.sample_bank is None)
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
/// Schedule a single note using sampled piano sound
fn schedule_note(
  synth : Synthesizer,
  bank : SampleBank,
  midi : @music.MidiNumber,
  start_time : @music.Duration,
  duration : @music.Duration,
  volume : Double,
) -> Unit {
  let start_time_sec = start_time.to_seconds()
  let duration_sec = duration.to_seconds()
  let info = midi_to_sample_info(midi.value)

  let buffer = match bank.lookup(info.note_name) {
    Some(buf) => buf
    None => return
  }

  let gain = {
    let gain = synth.ctx.create_gain()
    let release_time = 0.05
    let gain_param = gain.gain()
    // Let the natural piano sample play at full volume
    gain_param.set_value_at_time(volume, start_time_sec)
    // Quick fade-out at the end to avoid clicks
    gain_param.set_value_at_time(
      volume,
      start_time_sec + duration_sec - release_time,
    )
    gain_param.linear_ramp_to_value_at_time(0.0, start_time_sec + duration_sec)
    gain.connect(synth.master_gain.as_audio_node())
    gain
  }

  let source = synth.ctx.create_buffer_source()
  source.set_buffer(buffer)
  if info.detune_cents != 0.0 {
    source.detune().value = info.detune_cents
  }
  source.connect(gain.as_audio_node())
  source.start(start_time_sec)
  source.stop(start_time_sec + duration_sec)
}

///|
/// Schedule audio sounds for playback
pub fn Synthesizer::schedule_notes(
  self : Synthesizer,
  sounds : Array[@music.AudioSound],
  volume : Double,
) -> Unit {
  let bank = match self.sample_bank {
    Some(bank) => bank
    None => return
  }

  let current_time = @music.Duration::from_seconds(self.ctx.current_time())

  for sound in sounds {
    let start_time = sound.start_time(current_time)
    schedule_note(self, bank, sound.midi, start_time, sound.duration, volume)
  }
}
