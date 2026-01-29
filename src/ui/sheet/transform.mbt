///|
/// SVG transform primitives for declarative composition
priv enum SvgTransform {
  Translate(Double, Double)
  Scale(Double)
  ScaleXY(Double, Double)
  Rotate(Double, Double, Double)
}

///|
fn SvgTransform::to_string(self : SvgTransform) -> String {
  match self {
    Translate(x, y) => "translate(\{x} \{y})"
    Scale(s) => "scale(\{s})"
    ScaleXY(sx, sy) => "scale(\{sx} \{sy})"
    Rotate(angle, cx, cy) => "rotate(\{angle}, \{cx}, \{cy})"
  }
}

///|
fn SvgTransform::to_attr(self : SvgTransform) -> @luna_dom.Attr {
  @luna_dom.Attr::AttrString(self.to_string())
}

///|
/// Compose multiple transforms into a single attr
fn compose(transforms : Array[SvgTransform]) -> @luna_dom.Attr {
  @luna_dom.Attr::AttrString(transforms.map(fn(t) { t.to_string() }).join(" "))
}

///|
/// Convenience for the most common pattern: scale(s) translate(x/s, y/s)
fn scale_translate(scale : Double, x : Double, y : Double) -> @luna_dom.Attr {
  compose([Scale(scale), Translate(x / scale, y / scale)])
}
