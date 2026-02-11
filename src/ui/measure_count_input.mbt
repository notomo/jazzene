///|
/// Render measure count input control.
/// When loop_b equals the current measure_count, changing measure_count
/// also updates loop_b to follow along.
fn measure_count_input(
  measure_count : @signal.Signal[Int],
  loop_b_measure : @signal.Signal[Int],
) -> @luna_dom.DomNode {
  let get_prev_count = @signals.previous_with_initial(
    measure_count,
    measure_count.get(),
  )
  let _ = @signal.effect(fn() {
    let new_count = measure_count.get()
    let old_count = get_prev_count()
    if loop_b_measure.get() == old_count && new_count != old_count {
      loop_b_measure.set(new_count)
      set_query_param(
        "loop_b",
        new_count.to_string(),
        default=new_count.to_string(),
      )
    }
  })
  spinbox(
    label="Measures",
    measure_count,
    query_param="measures",
    default=default_measures,
    min=2,
    max=32,
    step=1,
  )
}
