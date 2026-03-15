///|
/// Render volume control as a spinbox (0–100%)
fn volume_input(volume : @signals.Signal[Int]) -> @luna_dom.DomNode {
  spinbox(
    label="Volume",
    get_value=fn() { volume.get() },
    on_change=fn(new_value, _old_value) { volume.set(new_value) },
    min=0,
    max=100,
    step=5,
  )
}
