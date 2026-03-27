///|
pub fn refresh_icon() -> @luna_dom.DomNode {
  @luna_dom.svg(
    [
      @luna_dom.svg_path(
        d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15",
        fill="none",
        stroke="#94a3b8",
        attrs=[
          ("stroke-linecap", @luna_dom.Attr::AttrString("round")),
          ("stroke-linejoin", @luna_dom.Attr::AttrString("round")),
          ("stroke-width", @luna_dom.Attr::AttrString("2")),
        ],
      ),
    ],
    attrs=[
      ("viewBox", @luna_dom.Attr::AttrString("0 0 24 24")),
      ("width", @luna_dom.Attr::AttrString("16")),
      ("height", @luna_dom.Attr::AttrString("16")),
      ("aria-hidden", @luna_dom.Attr::AttrString("true")),
    ],
  )
}
