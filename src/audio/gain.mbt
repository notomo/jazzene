///|
/// Set gain value immediately, cancelling any scheduled automation
fn set_gain_immediate(gain_node : @web_audio.GainNode, value : Double) -> Unit {
  let gain_param = gain_node.gain()
  gain_param.cancel_scheduled_values(0.0)
  gain_param.value = value
}
