///|
/// Render BPM input control
fn bpm_input(bpm : @signal.Signal[Int]) -> @luna_dom.DomNode {
  spinbox(
    label="BPM",
    get_value=fn() { bpm.get() },
    on_change=fn(new_value, _old_value) {
      bpm.set(new_value)
      set_query_param(
        "bpm",
        new_value.to_string(),
        default=default_bpm.to_string(),
      )
    },
    min=30,
    max=300,
    step=10,
  )
}
