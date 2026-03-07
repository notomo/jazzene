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
    @web_midi.request_midi_access(
      fn(access) {
        let inputs = @web_midi.MidiAccess::list_inputs(access)
        available_inputs.set(inputs)
        // Auto-select and activate the first available device
        if inputs.length() > 0 {
          let first = inputs[0]
          selected_id.set(@web_midi.MidiInput::id(first))
          @web_midi.MidiInput::set_on_midi_message(first, on_message)
        }
      },
      fn() { () },
    )
    @luna_dom.create_element(
      "select",
      [
        (
          "class",
          @luna_dom.AttrValue::Static(
            "w-full px-2 py-1 text-xs bg-slate-900 text-white rounded border border-slate-600 focus:border-blue-500 focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed",
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
        ("value", @luna_dom.AttrValue::Dynamic(fn() { selected_id.get() })),
        (
          "change",
          @luna_dom.AttrValue::Handler(fn(e) {
            let new_id = get_event_target_value(e)
            let prev_id = selected_id.get()
            if prev_id != "" {
              available_inputs
              .get()
              .iter()
              .filter(fn(input) { @web_midi.MidiInput::id(input) == prev_id })
              .each(fn(input) {
                @web_midi.MidiInput::clear_on_midi_message(input)
              })
            }
            midi_active_notes.set([])
            selected_id.set(new_id)
            available_inputs
            .get()
            .iter()
            .filter(fn(input) { @web_midi.MidiInput::id(input) == new_id })
            .each(fn(input) {
              @web_midi.MidiInput::set_on_midi_message(input, on_message)
            })
          }),
        ),
      ],
      [
        @luna_dom.for_each(fn() { available_inputs.get() }, fn(input, _i) {
          let id = @web_midi.MidiInput::id(input)
          @luna_dom.create_element(
            "option",
            [("value", @luna_dom.AttrValue::Static(id))],
            [@luna_dom.text(@web_midi.MidiInput::name(input))],
          )
        }),
      ],
    )
  }
}
