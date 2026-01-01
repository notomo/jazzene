///|
fn run_async(f : async () -> Unit noraise) -> Unit = "%async.run"

///|
/// Start the animation loop using requestAnimationFrame
pub fn start_animation_loop(
  state_update_fn : () -> Unit,
  running_signal_get : () -> Bool,
) -> Unit {
  fn animation_loop() -> Unit raise {
    if running_signal_get() {
      state_update_fn()
    }
    if false {
      // suppress unused_error_type
      raise fail("unreachable")
    }
    run_async(fn() { @js_browser_dom.requestAnimationFrame(animation_loop) })
  }

  run_async(fn() { @js_browser_dom.requestAnimationFrame(animation_loop) })
}
