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
  let all_modes = DisplayMode::all()
  @luna_dom.div(class="flex items-center gap-2", [
    @luna_dom.label(class="text-sm text-slate-400", [@luna_dom.text("View:")]),
    @luna_dom.create_element(
      "select",
      [
        (
          "class",
          @luna_dom.AttrValue::Static(
            "px-3 py-2 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none",
          ),
        ),
        ("aria-label", @luna_dom.AttrValue::Static("display mode")),
        ("value", @luna_dom.AttrValue::Dynamic(fn() { mode.get().to_string() })),
        (
          "change",
          @luna_dom.AttrValue::Handler(fn(e) {
            let value = get_event_target_value(e)
            mode.set(DisplayMode::from_string(value))
          }),
        ),
      ],
      {
        let initial = mode.get().to_string()
        all_modes.map(fn(m) {
          let name = m.to_string()
          let attrs : Array[(String, @luna_dom.AttrValue)] = [
            ("value", @luna_dom.AttrValue::Static(name)),
          ]
          if name == initial {
            attrs.push(("selected", @luna_dom.AttrValue::Static("selected")))
          }
          @luna_dom.create_element("option", attrs, [@luna_dom.text(name)])
        })
      },
    ),
  ])
}
