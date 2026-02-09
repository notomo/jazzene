///|
/// Render seed input control for random number generation
fn seed_input(seed : @signal.Signal[Int]) -> @luna_dom.DomNode {
  spinbox(label="Seed", seed, query_param="seed", min=0, max=9999, step=1)
}
