///|
/// Extract target.value from a JS event object
fn get_event_target_value(e : @js.Any) -> String {
  e._get("target")._get("value").cast()
}
