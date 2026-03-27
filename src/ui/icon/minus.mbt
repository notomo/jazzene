///|
pub fn minus_icon() -> @luna_dom.DomNode {
  @luna_dom.svg(
    [
      @luna_dom.svg_path(d="M5 12h14", fill="none", stroke="#93c5fd", attrs=[
        ("stroke-linecap", @luna_dom.Attr::AttrString("round")),
        ("stroke-width", @luna_dom.Attr::AttrString("2.5")),
      ]),
    ],
    attrs=[
      ("viewBox", @luna_dom.Attr::AttrString("0 0 24 24")),
      ("width", @luna_dom.Attr::AttrString("18")),
      ("height", @luna_dom.Attr::AttrString("18")),
      ("aria-hidden", @luna_dom.Attr::AttrString("true")),
    ],
  )
}
