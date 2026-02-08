///|
/// [AudioContext](https://developer.mozilla.org/en-US/docs/Web/API/AudioContext)
#external
pub type AudioContext

///|
pub fn AudioContext::as_any(self : AudioContext) -> @js.Any = "%identity"

///|
/// [AudioContext()](https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/AudioContext)
///
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
/// [currentTime](https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/currentTime)
///
/// Get current audio time
pub fn AudioContext::current_time(self : Self) -> Double {
  self.as_any()._get("currentTime").cast()
}

///|
/// [destination](https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/destination)
///
/// Get destination (speakers)
pub fn AudioContext::destination(self : Self) -> AudioNode {
  self.as_any()._get("destination").cast()
}

///|
#external
pub type AudioNode

///|
pub fn AudioNode::as_any(self : AudioNode) -> @js.Any = "%identity"

// GainNode wrapper

///|
/// [GainNode](https://developer.mozilla.org/en-US/docs/Web/API/GainNode)
#external
pub type GainNode

///|
pub fn GainNode::as_audio_node(self : GainNode) -> AudioNode = "%identity"

///|
pub fn GainNode::as_any(self : GainNode) -> @js.Any = "%identity"

///|
/// [createGain()](https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createGain)
///
/// Create gain node
pub fn AudioContext::create_gain(self : Self) -> GainNode {
  self.as_any()._call("createGain", []).cast()
}

///|
/// [connect()](https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/connect)
///
/// Connect gain node to a target node
pub fn GainNode::connect(self : Self, target : AudioNode) -> Unit {
  self.as_any()._call("connect", [@js.any(target)]) |> ignore
}

///|
/// [gain](https://developer.mozilla.org/en-US/docs/Web/API/GainNode/gain)
///
/// Get gain AudioParam for envelope control
pub fn GainNode::gain(self : Self) -> AudioParam {
  self.as_any()._get("gain").cast()
}

// AudioParam wrapper

///|
/// [AudioParam](https://developer.mozilla.org/en-US/docs/Web/API/AudioParam)
pub(all) struct AudioParam {
  /// [value](https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/value)
  mut value : Double
}

///|
pub fn AudioParam::as_any(self : AudioParam) -> @js.Any = "%identity"

///|
/// [setValueAtTime()](https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/setValueAtTime)
///
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
/// [linearRampToValueAtTime()](https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/linearRampToValueAtTime)
///
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
/// [exponentialRampToValueAtTime()](https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/exponentialRampToValueAtTime)
///
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

///|
/// [cancelScheduledValues()](https://developer.mozilla.org/en-US/docs/Web/API/AudioParam/cancelScheduledValues)
///
/// Cancel scheduled parameter changes
pub fn AudioParam::cancel_scheduled_values(self : Self, time : Double) -> Unit {
  self.as_any()._call("cancelScheduledValues", [@js.any(time)]) |> ignore
}

// OscillatorNode wrapper

///|
/// [OscillatorNode](https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode)
#external
pub type OscillatorNode

///|
pub fn OscillatorNode::as_any(self : OscillatorNode) -> @js.Any = "%identity"

///|
/// [createOscillator()](https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createOscillator)
///
/// Create oscillator node
pub fn AudioContext::create_oscillator(self : Self) -> OscillatorNode {
  self.as_any()._call("createOscillator", []).cast()
}

///|
/// [type](https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/type)
///
/// Set the oscillator waveform type ("sine", "square", "triangle", "sawtooth")
pub fn OscillatorNode::set_type(self : Self, type_ : String) -> Unit {
  self.as_any()._set("type", @js.any(type_))
}

///|
/// [frequency](https://developer.mozilla.org/en-US/docs/Web/API/OscillatorNode/frequency)
///
/// Get frequency AudioParam
pub fn OscillatorNode::frequency(self : Self) -> AudioParam {
  self.as_any()._get("frequency").cast()
}

///|
/// [connect()](https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/connect)
///
/// Connect oscillator to a target node
pub fn OscillatorNode::connect(self : Self, target : AudioNode) -> Unit {
  self.as_any()._call("connect", [@js.any(target)]) |> ignore
}

///|
/// [start()](https://developer.mozilla.org/en-US/docs/Web/API/AudioScheduledSourceNode/start)
///
/// Start oscillator at specified time
pub fn OscillatorNode::start(self : Self, time : Double) -> Unit {
  self.as_any()._call("start", [@js.any(time)]) |> ignore
}

///|
/// [stop()](https://developer.mozilla.org/en-US/docs/Web/API/AudioScheduledSourceNode/stop)
///
/// Stop oscillator at specified time
pub fn OscillatorNode::stop(self : Self, time : Double) -> Unit {
  self.as_any()._call("stop", [@js.any(time)]) |> ignore
}

// AudioBuffer wrapper

///|
/// [AudioBuffer](https://developer.mozilla.org/en-US/docs/Web/API/AudioBuffer)
#external
pub type AudioBuffer

///|
pub fn AudioBuffer::as_any(self : AudioBuffer) -> @js.Any = "%identity"

// AudioBufferSourceNode wrapper

///|
/// [AudioBufferSourceNode](https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode)
#external
pub type AudioBufferSourceNode

///|
pub fn AudioBufferSourceNode::as_any(self : AudioBufferSourceNode) -> @js.Any = "%identity"

///|
/// [createBufferSource()](https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createBufferSource)
///
/// Create buffer source node
pub fn AudioContext::create_buffer_source(self : Self) -> AudioBufferSourceNode {
  self.as_any()._call("createBufferSource", []).cast()
}

///|
/// [buffer](https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/buffer)
///
/// Set the audio buffer to play
pub fn AudioBufferSourceNode::set_buffer(
  self : Self,
  buffer : AudioBuffer,
) -> Unit {
  self.as_any()._set("buffer", @js.any(buffer))
}

///|
/// [detune](https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/detune)
///
/// Get detune AudioParam for pitch shifting (in cents)
pub fn AudioBufferSourceNode::detune(self : Self) -> AudioParam {
  self.as_any()._get("detune").cast()
}

///|
/// [connect()](https://developer.mozilla.org/en-US/docs/Web/API/AudioNode/connect)
///
/// Connect buffer source to a target node
pub fn AudioBufferSourceNode::connect(self : Self, target : AudioNode) -> Unit {
  self.as_any()._call("connect", [@js.any(target)]) |> ignore
}

///|
/// [start()](https://developer.mozilla.org/en-US/docs/Web/API/AudioScheduledSourceNode/start)
///
/// Start buffer source at specified time
pub fn AudioBufferSourceNode::start(self : Self, time : Double) -> Unit {
  self.as_any()._call("start", [@js.any(time)]) |> ignore
}

///|
/// [stop()](https://developer.mozilla.org/en-US/docs/Web/API/AudioScheduledSourceNode/stop)
///
/// Stop buffer source at specified time
pub fn AudioBufferSourceNode::stop(self : Self, time : Double) -> Unit {
  self.as_any()._call("stop", [@js.any(time)]) |> ignore
}
