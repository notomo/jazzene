///|
priv struct CanvasContext {
  canvas : @js_dom.HTMLCanvasElement
  ctx : @canvas.CanvasRenderingContext2D
}

///|
/// Create a canvas element with full-size styling and its 2D rendering context
fn create_canvas_context() -> CanvasContext {
  let canvas_elem = @js_dom.document().createElement("canvas")
  let canvas = cast_to_canvas(canvas_elem)
  set_canvas_style_width(canvas, "100%")
  set_canvas_style_height(canvas, "100%")
  let ctx = get_context_2d(canvas)
  { canvas, ctx }
}

///|
/// Update canvas buffer size for high-DPI displays and return logical dimensions.
/// Skips resizing if the canvas buffer dimensions are already correct.
fn update_canvas_dpi(
  canvas : @js_dom.HTMLCanvasElement,
  ctx : @canvas.CanvasRenderingContext2D,
) -> (Double, Double) {
  let dpr = get_device_pixel_ratio()
  let client_width = canvas.clientWidth()
  let client_height = canvas.clientHeight()
  if client_width > 0 && client_height > 0 {
    let new_width = (client_width.to_double() * dpr).to_int()
    let new_height = (client_height.to_double() * dpr).to_int()
    if canvas.width != new_width || canvas.height != new_height {
      canvas.width = new_width
      canvas.height = new_height
      ctx.setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
      ctx.scale(dpr, dpr)
    }
  }
  (client_width.to_double(), client_height.to_double())
}

///|
/// Convert a canvas element to a DomNode for use in Luna components
fn canvas_to_dom_node(canvas : @js_dom.HTMLCanvasElement) -> @luna_dom.DomNode {
  @luna_dom.ToDomNode::to_dom_node(canvas.as_node())
}

///|
extern "js" fn get_device_pixel_ratio() -> Double =
  #|() => window.devicePixelRatio || 1

///|
extern "js" fn get_context_2d(
  canvas : @js_dom.HTMLCanvasElement,
) -> @canvas.CanvasRenderingContext2D =
  #|(canvas) => canvas.getContext("2d")

///|
extern "js" fn set_canvas_style_width(
  canvas : @js_dom.HTMLCanvasElement,
  width : String,
) -> Unit =
  #|(canvas, width) => { canvas.style.width = width; }

///|
extern "js" fn set_canvas_style_height(
  canvas : @js_dom.HTMLCanvasElement,
  height : String,
) -> Unit =
  #|(canvas, height) => { canvas.style.height = height; }

///|
/// Create a signal that increments whenever the canvas element resizes.
/// Reading this signal in an effect ensures the effect re-runs on resize.
fn create_resize_trigger(
  canvas : @js_dom.HTMLCanvasElement,
) -> @signals.Signal[Int] {
  let trigger = @signals.signal(0)
  observe_resize(canvas, fn() { trigger.update(fn(n) { n + 1 }) })
  trigger
}

///|
extern "js" fn observe_resize(
  canvas : @js_dom.HTMLCanvasElement,
  callback : () -> Unit,
) -> Unit =
  #|function(canvas, callback) {
  #|  new ResizeObserver(function() { callback(); }).observe(canvas);
  #|}

///|
fn cast_to_canvas(elem : @js_dom.Element) -> @js_dom.HTMLCanvasElement = "%identity"
