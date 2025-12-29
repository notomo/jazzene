///|
/// Web Audio API context (opaque JavaScript object)
pub type AudioContext

///|
/// Web Audio API context wrapper
pub struct AudioEngine {
  context : AudioContext
}

///|
/// Create a new Audio Engine with Web Audio API context
pub fn AudioEngine::create() -> AudioEngine {
  AudioEngine::{ context: ffi_create_audio_context() }
}

///|
/// Play a single note with the given MIDI number and duration
pub fn AudioEngine::play_note(
  self : AudioEngine,
  note : @core.Note,
  duration_ms : Int,
) -> Unit {
  ffi_play_note(self.context, note.midi_number, duration_ms)
}

///|
/// FFI: Create Web Audio API context
extern "js" fn ffi_create_audio_context() -> AudioContext =
  #| () => {
  #|   const AudioContext = window.AudioContext || window.webkitAudioContext;
  #|   return new AudioContext();
  #| }

///|
/// FFI: Play a note using Web Audio API oscillator
extern "js" fn ffi_play_note(
  context : AudioContext,
  midi_number : Int,
  duration_ms : Int,
) -> Unit =
  #| (ctx, midiNumber, durationMs) => {
  #|   // Convert MIDI to frequency: f = 440 * 2^((n-69)/12)
  #|   const frequency = 440 * Math.pow(2, (midiNumber - 69) / 12);
  #|
  #|   // Create oscillator and gain nodes
  #|   const osc = ctx.createOscillator();
  #|   const gain = ctx.createGain();
  #|
  #|   // Configure oscillator
  #|   osc.type = 'sine';
  #|   osc.frequency.value = frequency;
  #|   osc.connect(gain);
  #|   gain.connect(ctx.destination);
  #|
  #|   // Envelope: attack + release
  #|   const now = ctx.currentTime;
  #|   const durationSec = durationMs / 1000;
  #|   const attackTime = 0.01;
  #|   const releaseTime = 0.1;
  #|
  #|   gain.gain.setValueAtTime(0, now);
  #|   gain.gain.linearRampToValueAtTime(0.3, now + attackTime);
  #|   gain.gain.exponentialRampToValueAtTime(0.01, now + durationSec - releaseTime);
  #|
  #|   // Start and stop oscillator
  #|   osc.start(now);
  #|   osc.stop(now + durationSec);
  #| }
