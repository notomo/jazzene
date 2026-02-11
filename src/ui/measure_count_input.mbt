///|
/// Render measure count input control
fn measure_count_input(
  measure_count : @signal.Signal[Int],
) -> @luna_dom.DomNode {
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
