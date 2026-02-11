///|
/// Display mode for visualization panels
pub(all) enum DisplayMode {
  Sheet_PianoRoll
  Sheet
  PianoRoll
} derive(Eq)

///|
pub fn DisplayMode::to_string(self : DisplayMode) -> String {
  match self {
    Sheet_PianoRoll => "Sheet + Piano Roll"
    Sheet => "Sheet"
    PianoRoll => "Piano Roll"
  }
}

///|
fn DisplayMode::to_query_string(self : DisplayMode) -> String {
  match self {
    Sheet_PianoRoll => "both"
    Sheet => "sheet"
    PianoRoll => "pianoroll"
  }
}

///|
fn DisplayMode::from_query_string(s : String) -> DisplayMode? {
  match s {
    "both" => Some(Sheet_PianoRoll)
    "sheet" => Some(Sheet)
    "pianoroll" => Some(PianoRoll)
    _ => None
  }
}

///|
fn DisplayMode::all() -> Array[DisplayMode] {
  [Sheet_PianoRoll, Sheet, PianoRoll]
}

///|
pub fn DisplayMode::show_sheet(self : DisplayMode) -> Bool {
  match self {
    Sheet_PianoRoll | Sheet => true
    PianoRoll => false
  }
}

///|
pub fn DisplayMode::show_piano_roll(self : DisplayMode) -> Bool {
  match self {
    Sheet_PianoRoll | PianoRoll => true
    Sheet => false
  }
}

///|
/// Render display mode segmented button group
fn display_mode_select(mode : @signal.Signal[DisplayMode]) -> @luna_dom.DomNode {
  let modes = DisplayMode::all()
  let buttons = modes.mapi(fn(i, m) {
    let rounding = match (i, modes.length() - 1) {
      (0, _) => "rounded-l-lg"
      (last, last2) if last == last2 => "rounded-r-lg"
      _ => ""
    }
    let base = "px-3 py-2 text-sm font-medium cursor-pointer transition-colors"
    @luna_dom.button(
      dyn_class=fn() {
        let active = mode.get() == m
        cn([
          base,
          rounding,
          if active {
            "bg-blue-900 text-blue-200"
          } else {
            "bg-slate-800 text-slate-400 hover:bg-slate-700"
          },
        ])
      },
      on=@luna_dom.events().click(fn(_) {
        mode.set(m)
        set_query_param("view", m.to_query_string())
      }),
      [@luna_dom.text(m.to_string())],
    )
  })
  @luna_dom.div(
    buttons,
    class="flex items-center rounded-lg border border-slate-600",
    attrs=[("aria-label", @luna_dom.Attr::AttrString("display mode"))],
  )
}
