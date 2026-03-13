///|
/// MIDI device select component.
/// Shows a dropdown of available MIDI input devices and highlights pressed
/// keys in the piano roll using the MIDI active notes signal.
/// When the browser does not support Web MIDI, shows a disabled select.
pub fn midi_device_select(
  midi_active_notes : @signals.Signal[Array[@music.MidiNumber]],
) -> @luna_dom.DomNode {
  if not(@web_midi.is_midi_supported()) {
    @luna_dom.create_element(
      "select",
      [
        (
          "class",
          @luna_dom.AttrValue::Static(
            "w-full px-2 py-1 text-xs bg-slate-900 text-slate-500 rounded border border-slate-700 cursor-not-allowed",
          ),
        ),
        ("disabled", @luna_dom.AttrValue::Static("true")),
        (
          "aria-label",
          @luna_dom.AttrValue::Static("MIDI input device (not supported)"),
        ),
      ],
      [
        @luna_dom.create_element("option", [], [@luna_dom.text("Not supported")]),
      ],
    )
  } else {
    let available_inputs : @signals.Signal[Array[@web_midi.MidiInput]] = @signals.signal([],
    )
    let selected_id : @signals.Signal[String] = @signals.signal("")
    let refresh_count : @signals.Signal[Int] = @signals.signal(0)
    let on_message = fn(status : Int, note : Int, velocity : Int) {
      let high_nibble = status / 16
      match @music.MidiNumber::new(note) {
        Some(midi) =>
          match (high_nibble, velocity) {
            (9, v) if v > 0 =>
              midi_active_notes.update(fn(notes) {
                if notes.iter().any(fn(n) { n == midi }) {
                  notes
                } else {
                  let new_notes = notes.copy()
                  new_notes.push(midi)
                  new_notes
                }
              })
            (8, _) =>
              midi_active_notes.update(fn(notes) {
                notes.filter(fn(n) { n != midi })
              })
            (9, 0) =>
              midi_active_notes.update(fn(notes) {
                notes.filter(fn(n) { n != midi })
              })
            _ => ()
          }
        None => ()
      }
    }
    let attach_handler = fn(input : @web_midi.MidiInput) {
      @web_midi.MidiInput::open(
        input,
        fn() { @web_midi.MidiInput::set_on_midi_message(input, on_message) },
        fn(_) { () },
      )
    }
    let do_request = fn() {
      @web_midi.request_midi_access(
        fn(access) {
          let inputs = @web_midi.MidiAccess::list_inputs(access)
          available_inputs.set(inputs)
          let current_id = selected_id.get()
          let still_available = current_id != "" &&
            inputs
            .iter()
            .any(fn(input) { @web_midi.MidiInput::id(input) == current_id })
          if still_available {
            inputs
            .iter()
            .filter(fn(input) { @web_midi.MidiInput::id(input) == current_id })
            .each(fn(input) { attach_handler(input) })
          } else if inputs.length() > 0 {
            let first = inputs[0]
            selected_id.set(@web_midi.MidiInput::id(first))
            attach_handler(first)
          }
          refresh_count.update(fn(n) { n + 1 })
        },
        fn() { () },
      )
    }
    do_request()
    @luna_dom.create_element(
      "div",
      [("class", @luna_dom.AttrValue::Static("flex items-center gap-1 w-full"))],
      [
        @luna_dom.create_element(
          "select",
          [
            (
              "class",
              @luna_dom.AttrValue::Static(
                "flex-1 px-2 py-1 text-xs bg-slate-900 text-white rounded border border-slate-600 focus:border-blue-500 focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed",
              ),
            ),
            ("aria-label", @luna_dom.AttrValue::Static("MIDI input device")),
            (
              "disabled",
              @luna_dom.AttrValue::Dynamic(fn() {
                if available_inputs.get().length() == 0 {
                  "true"
                } else {
                  "false"
                }
              }),
            ),
            (
              "value",
              @luna_dom.AttrValue::Dynamic(fn() {
                let _ = refresh_count.get()
                selected_id.get()
              }),
            ),
            (
              "change",
              @luna_dom.AttrValue::Handler(fn(e) {
                let idx = get_event_target_selected_index(e)
                let inputs = available_inputs.get()
                let prev_id = selected_id.get()
                if prev_id != "" {
                  inputs
                  .iter()
                  .filter(fn(input) {
                    @web_midi.MidiInput::id(input) == prev_id
                  })
                  .each(fn(input) {
                    @web_midi.MidiInput::clear_on_midi_message(input)
                  })
                }
                midi_active_notes.set([])
                if idx >= 0 && idx < inputs.length() {
                  let new_input = inputs[idx]
                  selected_id.set(@web_midi.MidiInput::id(new_input))
                  attach_handler(new_input)
                }
              }),
            ),
          ],
          [
            @luna_dom.create_element(
              "option",
              [
                ("value", @luna_dom.AttrValue::Static("")),
                ("disabled", @luna_dom.AttrValue::Static("true")),
                ("selected", @luna_dom.AttrValue::Static("true")),
                ("hidden", @luna_dom.AttrValue::Static("true")),
              ],
              [@luna_dom.text("Input device")],
            ),
            @luna_dom.for_each(fn() { available_inputs.get() }, fn(input, _i) {
              let id = @web_midi.MidiInput::id(input)
              @luna_dom.create_element(
                "option",
                [("value", @luna_dom.AttrValue::Static(id))],
                [@luna_dom.text(@web_midi.MidiInput::name(input))],
              )
            }),
          ],
        ),
        @luna_dom.button(
          [
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
            ),
          ],
          on=@luna_dom.events().click(fn(_) { do_request() }),
          class="p-1 hover:bg-slate-700 rounded flex-shrink-0",
          attrs=[
            ("aria-label", @luna_dom.Attr::AttrString("Reload MIDI devices")),
          ],
        ),
      ],
    )
  }
}
