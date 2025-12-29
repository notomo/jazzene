///|
/// Start the animation loop using requestAnimationFrame
pub async fn start_animation_loop(
  state_update_fn : () -> Unit,
  running_signal_get : () -> Bool,
) -> Unit noraise {
  fn animation_loop() -> Unit raise { // -unused_error_type is for this raise
    if running_signal_get() {
      state_update_fn()
    }
  }

  @js_browser_dom.requestAnimationFrame(animation_loop)
}
