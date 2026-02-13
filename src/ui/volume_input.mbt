///|
/// Render volume control as a spinbox (0–100%)
fn volume_input(volume : @signals.Signal[Int]) -> @luna_dom.DomNode {
  spinbox(
    label="Volume",
    get_value=fn() { volume.get() },
    on_change=fn(new_value, _old_value) {
      volume.set(new_value)
      set_query_param(
        "volume",
        new_value.to_string(),
        default=default_volume.to_string(),
      )
    },
    min=0,
    max=100,
    step=5,
  )
}
