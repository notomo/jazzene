///|
/// View state for visualization panels and settings
pub(all) struct ViewState {
  show_sheet : Bool
  show_piano_roll : Bool
  show_settings : Bool
} derive(Eq)

///|
fn ViewState::default() -> ViewState {
  { show_sheet: true, show_piano_roll: true, show_settings: false }
}

///|
fn ViewState::to_view_query_string(self : ViewState) -> String {
  let parts : Array[String] = []
  if self.show_sheet {
    parts.push("sheet")
  }
  if self.show_piano_roll {
    parts.push("pianoroll")
  }
  if self.show_settings {
    parts.push("setting")
  }
  parts.join(",")
}

///|
fn ViewState::from_query_string(s : String) -> ViewState {
  let parts = s.split(",").to_array()
  let show_sheet = parts.contains("sheet")
  let show_piano_roll = parts.contains("pianoroll")
  let show_settings = parts.contains("setting")
  if not(show_sheet) && not(show_piano_roll) {
    { ..ViewState::default(), show_settings, }
  } else {
    { show_sheet, show_piano_roll, show_settings }
  }
}

///|
fn toggle_sheet(current : ViewState) -> ViewState {
  match (current.show_sheet, current.show_piano_roll) {
    (true, true) => { ..current, show_sheet: false }
    (false, _) => { ..current, show_sheet: true }
    (true, false) => { ..current, show_sheet: false, show_piano_roll: true }
  }
}

///|
fn toggle_piano(current : ViewState) -> ViewState {
  match (current.show_sheet, current.show_piano_roll) {
    (true, true) => { ..current, show_piano_roll: false }
    (_, false) => { ..current, show_piano_roll: true }
    (false, true) => { ..current, show_sheet: true, show_piano_roll: false }
  }
}

///|
/// Eighth note icon using the same shapes as lead sheet rendering
fn eighth_note_icon(active : Bool) -> @luna_dom.DomNode {
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

///|
/// Piano keyboard icon (white keys with divider lines, filled black keys)
fn piano_icon(active : Bool) -> @luna_dom.DomNode {
  let color = if active { "#93c5fd" } else { "#94a3b8" }
  // Outer border
  let border : @luna_dom.DomNode = @luna_dom.svg_rect(
    x="1",
    y="1",
    width="14",
    height="14",
    fill="none",
    stroke=color,
    attrs=[("stroke-width", @luna_dom.Attr::AttrString("1"))],
  )
  // Black key positions: center_x values for divider alignment
  let black_key_centers = [5.5, 10.5]
  // White key divider lines (aligned to black key centers)
  let dividers : Array[@luna_dom.DomNode] = black_key_centers.map(fn(cx) {
    let x = cx.to_string()
    @luna_dom.svg_line(x1=x, y1="1", x2=x, y2="15", stroke=color, attrs=[
      ("stroke-width", @luna_dom.Attr::AttrString("0.8")),
    ])
  })
  // Black keys (filled rectangles)
  let black_keys : Array[@luna_dom.DomNode] = black_key_centers.map(fn(cx) {
    let x = (cx - 1.5).to_string()
    @luna_dom.svg_rect(x~, y="1", width="3", height="8", fill=color)
  })
  @luna_dom.svg([border] + dividers + black_keys, attrs=[
    ("viewBox", @luna_dom.Attr::AttrString("0 0 16 16")),
    ("width", @luna_dom.Attr::AttrString("16")),
    ("height", @luna_dom.Attr::AttrString("16")),
  ])
}

///|
/// Gear/settings icon
fn settings_icon(active : Bool) -> @luna_dom.DomNode {
  let color = if active { "#93c5fd" } else { "#94a3b8" }
  @luna_dom.svg(
    [
      @luna_dom.svg_path(
        d="M19.43 12.98c.04-.32.07-.64.07-.98s-.03-.66-.07-.98l2.11-1.65c.19-.15.24-.42.12-.64l-2-3.46c-.12-.22-.39-.3-.61-.22l-2.49 1c-.52-.4-1.08-.73-1.69-.98l-.38-2.65C14.46 2.18 14.25 2 14 2h-4c-.25 0-.46.18-.49.42l-.38 2.65c-.61.25-1.17.59-1.69.98l-2.49-1c-.23-.09-.49 0-.61.22l-2 3.46c-.13.22-.07.49.12.64l2.11 1.65c-.04.32-.07.65-.07.98s.03.66.07.98l-2.11 1.65c-.19.15-.24.42-.12.64l2 3.46c.12.22.39.3.61.22l2.49-1c.52.4 1.08.73 1.69.98l.38 2.65c.03.24.24.42.49.42h4c.25 0 .46-.18.49-.42l.38-2.65c.61-.25 1.17-.59 1.69-.98l2.49 1c.23.09.49 0 .61-.22l2-3.46c.13-.22.07-.49-.12-.64l-2.11-1.65zM12 15.5c-1.93 0-3.5-1.57-3.5-3.5s1.57-3.5 3.5-3.5 3.5 1.57 3.5 3.5-1.57 3.5-3.5 3.5z",
        fill=color,
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

///|
/// Render view mode toggle buttons
fn view_mode_select(
  view_state : @signals.Signal[ViewState],
) -> @luna_dom.DomNode {
  let base = "px-2 lg:px-3 py-1 lg:py-2 font-medium cursor-pointer transition-colors flex items-center"
  let active_class = "bg-blue-900 text-blue-200"
  let inactive_class = "bg-slate-800 text-slate-400 hover:bg-slate-700"
  let sheet_button = @luna_dom.button(
    dyn_class=fn() {
      cn([
        base,
        "rounded-l-lg",
        if view_state.get().show_sheet {
          active_class
        } else {
          inactive_class
        },
      ])
    },
    on=@luna_dom.events().click(fn(_) {
      let next = toggle_sheet(view_state.get())
      view_state.set(next)
      set_query_param(
        "view",
        next.to_view_query_string(),
        default="sheet,pianoroll",
      )
    }),
    [eighth_note_icon(view_state.get().show_sheet)],
    attrs=[("title", @luna_dom.Attr::AttrString("Sheet"))],
  )
  let piano_button = @luna_dom.button(
    dyn_class=fn() {
      cn([
        base,
        if view_state.get().show_piano_roll {
          active_class
        } else {
          inactive_class
        },
      ])
    },
    on=@luna_dom.events().click(fn(_) {
      let next = toggle_piano(view_state.get())
      view_state.set(next)
      set_query_param(
        "view",
        next.to_view_query_string(),
        default="sheet,pianoroll",
      )
    }),
    [piano_icon(view_state.get().show_piano_roll)],
    attrs=[("title", @luna_dom.Attr::AttrString("Piano"))],
  )
  let settings_button = @luna_dom.button(
    dyn_class=fn() {
      cn([
        base,
        "rounded-r-lg",
        if view_state.get().show_settings {
          active_class
        } else {
          inactive_class
        },
      ])
    },
    on=@luna_dom.events().click(fn(_) {
      let next = {
        ..view_state.get(),
        show_settings: not(view_state.get().show_settings),
      }
      view_state.set(next)
      set_query_param(
        "view",
        next.to_view_query_string(),
        default="sheet,pianoroll",
      )
    }),
    [settings_icon(view_state.get().show_settings)],
    attrs=[("title", @luna_dom.Attr::AttrString("Settings"))],
  )
  @luna_dom.div(
    [sheet_button, piano_button, settings_button],
    class="flex items-center rounded-lg border border-slate-600",
    attrs=[("aria-label", @luna_dom.Attr::AttrString("view mode"))],
  )
}
