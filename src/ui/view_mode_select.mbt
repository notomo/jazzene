///|
/// View state for visualization panels and settings
pub struct ViewState {
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
      view_state.set(toggle_sheet(view_state.get()))
    }),
    [@icon.eighth_note_icon(view_state.get().show_sheet)],
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
      view_state.set(toggle_piano(view_state.get()))
    }),
    [@icon.piano_icon(view_state.get().show_piano_roll)],
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
      view_state.set({
        ..view_state.get(),
        show_settings: not(view_state.get().show_settings),
      })
    }),
    [@icon.settings_icon(view_state.get().show_settings)],
    attrs=[("title", @luna_dom.Attr::AttrString("Settings"))],
  )
  @luna_dom.div(
    [sheet_button, piano_button, settings_button],
    class="flex items-center rounded-lg border border-slate-600",
    attrs=[("aria-label", @luna_dom.Attr::AttrString("view mode"))],
  )
}
