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
pub fn AudioContext::destination(self : Self) -> @js.Any {
  self.as_any()._get("destination")
}

// OscillatorNode wrapper

///|
#external
pub type OscillatorNode

///|
pub fn OscillatorNode::as_any(self : OscillatorNode) -> @js.Any = "%identity"

///|
/// Create oscillator node
pub fn AudioContext::create_oscillator(self : Self) -> OscillatorNode {
  self.as_any()._call("createOscillator", []).cast()
}

///|
/// Set oscillator type (sine, square, sawtriangle, triangle)
pub fn OscillatorNode::set_type(self : Self, osc_type : String) -> Unit {
  self.as_any()._set("type", @js.any(osc_type))
}

///|
/// Set oscillator frequency
pub fn OscillatorNode::set_frequency(self : Self, freq : Double) -> Unit {
  self.as_any()._get("frequency")._set("value", @js.any(freq))
}

///|
/// Connect oscillator to a target node
pub fn OscillatorNode::connect(self : Self, target : @js.Any) -> Unit {
  self.as_any()._call("connect", [@js.any(target)]) |> ignore
}

///|
/// Start oscillator at specified time
pub fn OscillatorNode::start(self : Self, time : Double) -> Unit {
  self.as_any()._call("start", [@js.any(time)]) |> ignore
}

///|
/// Stop oscillator at specified time
pub fn OscillatorNode::stop(self : Self, time : Double) -> Unit {
  self.as_any()._call("stop", [@js.any(time)]) |> ignore
}

// GainNode wrapper

///|
#external
pub type GainNode

///|
pub fn GainNode::as_any(self : GainNode) -> @js.Any = "%identity"

///|
/// Create gain node
pub fn AudioContext::create_gain(self : Self) -> GainNode {
  self.as_any()._call("createGain", []).cast()
}

///|
/// Connect gain node to a target node
pub fn GainNode::connect(self : Self, target : @js.Any) -> Unit {
  self.as_any()._call("connect", [@js.any(target)]) |> ignore
}

///|
/// Get gain AudioParam for envelope control
pub fn GainNode::gain(self : Self) -> AudioParam {
  self.as_any()._get("gain").cast()
}

// AudioParam wrapper

///|
#external
pub type AudioParam

///|
pub fn AudioParam::as_any(self : AudioParam) -> @js.Any = "%identity"

///|
/// Set parameter value at specific time
pub fn AudioParam::set_value_at_time(
  self : Self,
  value : Double,
  time : Double,
) -> Unit {
  self.as_any()._call("setValueAtTime", [@js.any(value), @js.any(time)])
  |> ignore
}

///|
/// Linear ramp to value at specific time
pub fn AudioParam::linear_ramp_to_value_at_time(
  self : Self,
  value : Double,
  time : Double,
) -> Unit {
  self
  .as_any()
  ._call("linearRampToValueAtTime", [@js.any(value), @js.any(time)])
  |> ignore
}

///|
/// Exponential ramp to value at specific time
pub fn AudioParam::exponential_ramp_to_value_at_time(
  self : Self,
  value : Double,
  time : Double,
) -> Unit {
  self
  .as_any()
  ._call("exponentialRampToValueAtTime", [@js.any(value), @js.any(time)])
  |> ignore
}
