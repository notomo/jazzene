///|
/// Start the animation loop using requestAnimationFrame
pub fn start_animation_loop(
  state_update_fn : () -> Unit,
  running_signal_get : () -> Bool,
) -> Unit {
  fn animation_loop() -> Unit {
    if running_signal_get() {
      state_update_fn()
    }
    ffi_request_animation_frame(animation_loop)
  }

  animation_loop()
}

///|
/// FFI: requestAnimationFrame
extern "js" fn ffi_request_animation_frame(callback : () -> Unit) -> Unit =
  #| (callback) => {
  #|   if (globalThis.requestAnimationFrame) {
  #|     requestAnimationFrame(callback);
  #|   } else {
  #|     setTimeout(callback, 16); // ~60fps fallback
  #|   }
  #| }
