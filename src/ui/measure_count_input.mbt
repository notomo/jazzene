///|
/// Render measure count input control.
/// When loop_b equals the current measure_count, changing measure_count
/// also updates loop_b to follow along.
fn measure_count_input(
  measure_count : @signals.Signal[Int],
  loop_b_measure : @signals.Signal[Int],
) -> @luna_dom.DomNode {
  spinbox(
    label="Measures",
    get_value=fn() { measure_count.get() },
    on_change=fn(new_value, old_value) {
      measure_count.set(new_value)
      if loop_b_measure.get() == old_value {
        loop_b_measure.set(new_value)
      }
    },
    min=2,
    max=32,
    step=1,
  )
}
