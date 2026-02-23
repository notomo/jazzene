///|
/// Synthesizer with master gain for volume control and muting
pub struct Synthesizer {
  ctx : @web_audio.AudioContext
  master_gain : @web_audio.GainNode
  piano : Piano
  bass : Bass
  drum : Drum
}

///|
/// Create a new Synthesizer with AudioContext, master gain, and all audio components
pub fn Synthesizer::new() -> Synthesizer {
  let ctx = @web_audio.AudioContext::new()
  let master_gain = ctx.create_gain()
  master_gain.connect(ctx.destination())
  let piano = Piano::new(ctx, master_gain)
  let bass = Bass::new(ctx, master_gain)
  let drum = Drum::new(ctx, master_gain)
  piano.load_samples()
  { ctx, master_gain, piano, bass, drum }
}

///|
/// Mute all audio immediately by setting master gain to 0
pub fn Synthesizer::mute(self : Synthesizer) -> Unit {
  set_gain_immediate(self.master_gain, 0.0)
}

///|
/// Unmute audio by restoring master gain to 1
pub fn Synthesizer::unmute(self : Synthesizer) -> Unit {
  set_gain_immediate(self.master_gain, 1.0)
}

///|
/// Schedule audio sounds for playback across piano, bass, and drum components
pub fn Synthesizer::schedule_sounds(
  self : Synthesizer,
  piano_sounds? : Array[@music.AudioSound] = [],
  bass_sounds? : Array[@music.AudioSound] = [],
  drum_sounds? : Array[@music.AudioSound] = [],
  volume~ : Double,
) -> Unit {
  self.piano.schedule_notes(piano_sounds, volume)
  self.bass.schedule_notes(bass_sounds, volume)
  self.drum.schedule_notes(drum_sounds, volume)
}
