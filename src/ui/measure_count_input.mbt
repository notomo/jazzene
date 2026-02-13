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
      set_query_param(
        "measures",
        new_value.to_string(),
        default=default_measures.to_string(),
      )
      if loop_b_measure.get() == old_value {
        loop_b_measure.set(new_value)
        set_query_param(
          "loop_b",
          new_value.to_string(),
          default=new_value.to_string(),
        )
      }
    },
    min=2,
    max=32,
    step=1,
  )
}
