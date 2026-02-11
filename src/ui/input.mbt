///|
/// Extract target.value from a JS event object
extern "js" fn get_event_target_value(e : @js.Any) -> String =
  #|(e) => e.target.value

///|
/// Get value from input event target
fn get_input_value(e : @js_dom.InputEvent) -> String {
  let target = e.target()
  let event_target = target.as_event_target()
  event_target.as_any()._get("value").to_string()
}
