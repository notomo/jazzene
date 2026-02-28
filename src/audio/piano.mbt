///|
/// Piano synthesizer using sampled audio
struct Piano {
  ctx : @web_audio.AudioContext
  gain : @web_audio.GainNode
  mut sample_bank : SampleBank?
}

///|
/// Create a new Piano connected to master_gain
fn Piano::new(
  ctx : @web_audio.AudioContext,
  master_gain : @web_audio.GainNode,
) -> Piano {
  let gain = ctx.create_gain()
  gain.connect(master_gain.as_audio_node())
  { ctx, gain, sample_bank: None }
}

///|
/// Load Salamander Grand Piano samples asynchronously
fn Piano::load_samples(self : Piano) -> Unit {
  load_sample_bank(self.ctx, fn(bank) { self.sample_bank = Some(bank) })
}

///|
/// Schedule a single note using sampled piano sound
fn Piano::schedule_note(
  self : Piano,
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

  // Release tail after note end: 40% of duration, clamped [80ms, 300ms].
  // Decay happens *after* the note duration, so short notes don't cut off abruptly.
  let r = duration_sec * 0.4
  let release_time = if r < 0.08 { 0.08 } else if r > 0.3 { 0.3 } else { r }
  let note_end_sec = start_time_sec + duration_sec
  let stop_time_sec = note_end_sec + release_time

  let gain = {
    let gain = self.ctx.create_gain()
    let gain_param = gain.gain()
    gain_param.set_value_at_time(volume, start_time_sec)
    // Hold at full volume for the entire note duration
    gain_param.set_value_at_time(volume, note_end_sec)
    // Exponential decay to near-silence after note ends
    gain_param.exponential_ramp_to_value_at_time(0.001, stop_time_sec)
    gain.connect(self.gain.as_audio_node())
    gain
  }

  let source = self.ctx.create_buffer_source()
  source.set_buffer(buffer)
  if info.detune_cents != 0.0 {
    source.detune().value = info.detune_cents
  }
  source.connect(gain.as_audio_node())
  source.start(start_time_sec)
  source.stop(stop_time_sec)
}

///|
/// Schedule piano sounds for playback
fn Piano::schedule_notes(
  self : Piano,
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
    self.schedule_note(bank, sound.midi, start_time, sound.duration, volume)
  }
}
