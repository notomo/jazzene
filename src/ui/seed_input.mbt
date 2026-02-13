///|
/// Render seed input control for random number generation
fn seed_input(seed : @signals.Signal[Int]) -> @luna_dom.DomNode {
  spinbox(
    label="Seed",
    get_value=fn() { seed.get() },
    on_change=fn(new_value, _old_value) {
      seed.set(new_value)
      set_query_param(
        "seed",
        new_value.to_string(),
        default=default_seed.to_string(),
      )
    },
    min=0,
    max=9999,
    step=1,
  )
}
