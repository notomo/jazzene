///|
/// Render volume control as a spinbox (0–100%)
fn volume_input(volume : @signal.Signal[Int]) -> @luna_dom.DomNode {
  spinbox(volume, label="Volume", query_param="volume", min=0, max=100, step=5)
}
