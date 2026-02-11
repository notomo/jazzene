///|
/// Display mode for visualization panels
pub(all) enum DisplayMode {
  Sheet_PianoRoll
  Sheet
  PianoRoll
} derive(Eq)

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
fn toggle_sheet(current : DisplayMode) -> DisplayMode {
  match current {
    Sheet_PianoRoll => PianoRoll
    Sheet => PianoRoll
    PianoRoll => Sheet_PianoRoll
  }
}

///|
fn toggle_piano(current : DisplayMode) -> DisplayMode {
  match current {
    Sheet_PianoRoll => Sheet
    PianoRoll => Sheet
    Sheet => Sheet_PianoRoll
  }
}

///|
/// Render display mode toggle buttons with "View:" label
fn display_mode_select(mode : @signal.Signal[DisplayMode]) -> @luna_dom.DomNode {
  let base = "px-3 py-2 text-sm font-medium cursor-pointer transition-colors"
  let active_class = "bg-blue-900 text-blue-200"
  let inactive_class = "bg-slate-800 text-slate-400 hover:bg-slate-700"
  let sheet_button = @luna_dom.button(
    dyn_class=fn() {
      cn([
        base,
        "rounded-l-lg",
        if mode.get().show_sheet() {
          active_class
        } else {
          inactive_class
        },
      ])
    },
    on=@luna_dom.events().click(fn(_) {
      let next = toggle_sheet(mode.get())
      mode.set(next)
      set_query_param("view", next.to_query_string())
    }),
    [@luna_dom.text("Sheet")],
  )
  let piano_button = @luna_dom.button(
    dyn_class=fn() {
      cn([
        base,
        "rounded-r-lg",
        if mode.get().show_piano_roll() {
          active_class
        } else {
          inactive_class
        },
      ])
    },
    on=@luna_dom.events().click(fn(_) {
      let next = toggle_piano(mode.get())
      mode.set(next)
      set_query_param("view", next.to_query_string())
    }),
    [@luna_dom.text("Piano")],
  )
  @luna_dom.div(
    [
      @luna_dom.span(
        [@luna_dom.text("View:")],
        class="text-sm text-slate-400 mr-2",
      ),
      @luna_dom.div(
        [sheet_button, piano_button],
        class="flex items-center rounded-lg border border-slate-600",
        attrs=[("aria-label", @luna_dom.Attr::AttrString("display mode"))],
      ),
    ],
    class="flex items-center",
  )
}
