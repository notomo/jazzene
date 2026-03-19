///|
/// Register document-level drag listeners for horizontal (X-axis) drag.
/// Call this from a mousedown/touchstart handler to track the drag until release.
fn add_document_drag_listeners(
  on_move : (Double) -> Unit,
  on_up : () -> Unit,
) -> Unit {
  let doc = @js_dom.document().as_event_target()
  let move_ref : Ref[(@js.Any) -> Unit] = { val: fn(_) { () } }
  let up_ref : Ref[(@js.Any) -> Unit] = { val: fn(_) { () } }
  move_ref.val = fn(e) { on_move(e._get("clientX").cast()) }
  up_ref.val = fn(_e) {
    on_up()
    doc.removeEventListener("mousemove", move_ref.val)
    doc.removeEventListener("mouseup", up_ref.val)
  }
  doc.addEventListener("mousemove", move_ref.val)
  doc.addEventListener("mouseup", up_ref.val)
  let touch_move_ref : Ref[(@js.Any) -> Unit] = { val: fn(_) { () } }
  let touch_end_ref : Ref[(@js.Any) -> Unit] = { val: fn(_) { () } }
  touch_move_ref.val = fn(e) {
    let touches = e._get("touches")
    if (touches._get("length").cast() : Int) > 0 {
      e._call("preventDefault", []) |> ignore
      on_move(touches._get_by_index(0)._get("clientX").cast())
    }
  }
  touch_end_ref.val = fn(_e) {
    on_up()
    doc.removeEventListener("touchmove", touch_move_ref.val)
    doc.removeEventListener("touchend", touch_end_ref.val)
    doc.removeEventListener("touchcancel", touch_end_ref.val)
  }
  doc.addEventListener("touchmove", touch_move_ref.val)
  doc.addEventListener("touchend", touch_end_ref.val)
  doc.addEventListener("touchcancel", touch_end_ref.val)
}
