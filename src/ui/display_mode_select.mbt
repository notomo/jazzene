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
fn DisplayMode::from_string(s : String) -> DisplayMode {
  match s {
    "Sheet" => Sheet
    "Piano Roll" => PianoRoll
    _ => Sheet_PianoRoll
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
/// Render display mode selection dropdown
fn display_mode_select(mode : @signal.Signal[DisplayMode]) -> @luna_dom.DomNode {
  select_input(
    label="View:",
    aria_label="display mode",
    options=DisplayMode::all().map(DisplayMode::to_string),
    initial=mode.get().to_string(),
    value=fn() { mode.get().to_string() },
    on_change=fn(value) {
      let m = DisplayMode::from_string(value)
      mode.set(m)
      set_query_param("view", m.to_query_string())
    },
  )
}
