///|
/// Get value from input event target
pub fn get_input_value(e : @js_dom.InputEvent) -> String {
  let target = e.target()
  let event_target = target.as_event_target()
  event_target.as_any()._get("value").to_string()
}

///|
/// Get checked state from checkbox event target
pub fn get_checkbox_checked(e : @js_dom.InputEvent) -> Bool {
  let target = e.target()
  let event_target = target.as_event_target()
  event_target.as_any()._get("checked").to_string() == "true"
}
