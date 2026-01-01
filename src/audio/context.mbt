///|
/// Web Audio API AudioContext
#external
pub type AudioContext

///|
pub fn AudioContext::as_any(self : AudioContext) -> @js.Any = "%identity"

///|
/// Create a new AudioContext
pub fn AudioContext::new() -> AudioContext {
  ffi_create_audio_context()
}

///|
extern "js" fn ffi_create_audio_context() -> AudioContext =
  #| () => {
  #|   const AudioContext = window.AudioContext || window.webkitAudioContext;
  #|   return new AudioContext();
  #| }

///|
/// Get current audio time
pub fn AudioContext::current_time(self : Self) -> Double {
  self.as_any()._get("currentTime").cast()
}

///|
/// Get destination (speakers)
fn AudioContext::destination(self : Self) -> @js.Any {
  self.as_any()._get("destination")
}

///|
/// Create oscillator node
fn AudioContext::create_oscillator(self : Self) -> @js.Any {
  self.as_any()._call("createOscillator", [])
}

///|
/// Create gain node
fn AudioContext::create_gain(self : Self) -> @js.Any {
  self.as_any()._call("createGain", [])
}

///|
/// Schedule a note to play at a specific time
pub fn AudioContext::schedule_note(
  self : Self,
  midi : Int,
  start_time : Double,
  duration_sec : Double,
  volume : Double,
) -> Unit {
  // Convert MIDI to frequency: f = 440 * 2^((n-69)/12)
  let frequency = 440.0 * pow(2.0, (midi.to_double() - 69.0) / 12.0)

  // Create nodes
  let osc = self.create_oscillator()
  let gain = self.create_gain()

  // Configure oscillator
  osc._set("type", @js.any("sine"))
  osc._get("frequency")._set("value", @js.any(frequency))

  // Connect nodes
  osc._call("connect", [@js.any(gain)]) |> ignore
  gain._call("connect", [@js.any(self.destination())]) |> ignore

  // Envelope
  let attack_time = 0.01
  let release_time = 0.1
  let gain_param = gain._get("gain")
  gain_param._call("setValueAtTime", [@js.any(0.0), @js.any(start_time)])
  |> ignore
  gain_param._call("linearRampToValueAtTime", [
    @js.any(volume),
    @js.any(start_time + attack_time),
  ])
  |> ignore
  gain_param._call("exponentialRampToValueAtTime", [
    @js.any(0.01),
    @js.any(start_time + duration_sec - release_time),
  ])
  |> ignore

  // Schedule start/stop
  osc._call("start", [@js.any(start_time)]) |> ignore
  osc._call("stop", [@js.any(start_time + duration_sec)]) |> ignore
}

///|
/// Helper: calculate power (2^x)
fn pow(base : Double, exp : Double) -> Double {
  let math = @js_global.global_this()._get("Math")
  math._call("pow", [@js.any(base), @js.any(exp)]).cast()
}
