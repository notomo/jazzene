///|
/// Render BPM input control
fn bpm_input(bpm : @signals.Signal[Int]) -> @luna_dom.DomNode {
  spinbox(
    label="BPM",
    get_value=fn() { bpm.get() },
    on_change=fn(new_value, _old_value) { bpm.set(new_value) },
    min=30,
    max=300,
    step=10,
  )
}
