///|
/// Eighth note icon using the same shapes as lead sheet rendering
pub fn eighth_note_icon(active : Bool) -> @luna_dom.DomNode {
  let color = if active { "#93c5fd" } else { "#94a3b8" }
  // Note head proportions from note.mbt (rx:ry ≈ 1.49:1, rotation -25°)
  let cx = 6.5
  let cy = 12.5
  let rx = 3.5
  let ry = 2.3
  let rotation = -25.0
  // Stem position: right edge of rotated ellipse
  let stem_x = cx + rx * 0.906 // cos(25°)
  let stem_top = 0.5
  let stem_bottom = cy - ry * 0.423 // sin(25°) offset
  // Flag path from note.mbt render_flag, scaled to icon size
  let flag_scale = 0.1
  let flag_tx = stem_x / flag_scale
  let flag_ty = stem_top / flag_scale
  let flag_transform = "scale(\{flag_scale}) translate(\{flag_tx} \{flag_ty})"
  @luna_dom.svg(
    [
      @luna_dom.svg_ellipse(
        cx=cx.to_string(),
        cy=cy.to_string(),
        rx=rx.to_string(),
        ry=ry.to_string(),
        fill=color,
        stroke="none",
        attrs=[
          (
            "transform",
            @luna_dom.Attr::AttrString("rotate(\{rotation} \{cx} \{cy})"),
          ),
        ],
      ),
      @luna_dom.svg_line(
        x1=stem_x.to_string(),
        y1=stem_bottom.to_string(),
        x2=stem_x.to_string(),
        y2=stem_top.to_string(),
        stroke=color,
        attrs=[("stroke-width", @luna_dom.Attr::AttrString("1"))],
      ),
      @luna_dom.svg_path(
        d="m 0.1322915,0.20079656 v 29.17519544 c 0,0 0.94525,1.04738 2.86031,2.860314 2.96256,2.804577 11.7267205,11.463111 16.3037905,16.875851 4.32124,5.11019 8.60276,12.11629 9.13525,19.19871 0.53655,7.13637 -1.14271,16.58785 -4.70907,26.52439 -1.9313,5.380953 -3.62376,8.222963 -3.06452,8.587383 0.79714,0.51945 2.7385,-2.97941 6.4668,-10.625733 6.32003,-12.96167 7.43952,-25.40692 6.55264,-34.62269 -1.15046,-11.95469 -2.28519,-23.402003 -9.94627,-35.007151 -6.79549,-10.293932 -14.7193405,-17.7092604 -19.5333005,-20.7143534 -2.59687,-1.62108305 -4.06563,-2.25191604 -4.06563,-2.25191604 z",
        fill=color,
        stroke="none",
        attrs=[("transform", @luna_dom.Attr::AttrString(flag_transform))],
      ),
    ],
    attrs=[
      ("viewBox", @luna_dom.Attr::AttrString("0 0 16 16")),
      ("width", @luna_dom.Attr::AttrString("16")),
      ("height", @luna_dom.Attr::AttrString("16")),
    ],
  )
}
