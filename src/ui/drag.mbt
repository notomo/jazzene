///|
/// Register document-level drag listeners for horizontal (X-axis) drag.
/// Call this from a mousedown/touchstart handler to track the drag until release.
extern "js" fn add_document_drag_listeners(
  on_move : (Double) -> Unit,
  on_up : () -> Unit,
) -> Unit =
  #|(onMove, onUp) => {
  #|  const moveHandler = (e) => onMove(e.clientX);
  #|  const upHandler = () => {
  #|    onUp();
  #|    document.removeEventListener('mousemove', moveHandler);
  #|    document.removeEventListener('mouseup', upHandler);
  #|  };
  #|  document.addEventListener('mousemove', moveHandler);
  #|  document.addEventListener('mouseup', upHandler);
  #|  const touchMoveHandler = (e) => {
  #|    if (e.touches.length > 0) {
  #|      e.preventDefault();
  #|      onMove(e.touches[0].clientX);
  #|    }
  #|  };
  #|  const touchEndHandler = () => {
  #|    onUp();
  #|    document.removeEventListener('touchmove', touchMoveHandler);
  #|    document.removeEventListener('touchend', touchEndHandler);
  #|    document.removeEventListener('touchcancel', touchEndHandler);
  #|  };
  #|  document.addEventListener('touchmove', touchMoveHandler, { passive: false });
  #|  document.addEventListener('touchend', touchEndHandler);
  #|  document.addEventListener('touchcancel', touchEndHandler);
  #|}
