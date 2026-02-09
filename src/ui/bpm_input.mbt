///|
/// Render BPM input control
fn bpm_input(bpm : @signal.Signal[Int]) -> @luna_dom.DomNode {
  spinbox(label="BPM", bpm, query_param="bpm", min=30, max=300, step=10)
}
