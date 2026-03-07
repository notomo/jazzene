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
    let selected_id : @signals.Signal[String] = @signals.signal("none")
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

    // Create the actual DOM element directly to allow imperative manipulation
    // (using @luna_dom.create_element would return a Luna wrapper, not the raw element)
    let select_elem = @js_dom.document().createElement("select")
    select_elem.setClassName(
      "w-full px-2 py-1 text-xs bg-slate-900 text-white rounded border border-slate-600 focus:border-blue-500 focus:outline-none",
    )
    select_elem.setAttribute("aria-label", "MIDI input device")
    ffi_add_none_option(select_elem)
    ffi_add_change_listener(select_elem, fn(new_id) {
      let prev_id = selected_id.get()
      if prev_id != "none" {
        available_inputs
        .get()
        .iter()
        .filter(fn(input) { @web_midi.MidiInput::id(input) == prev_id })
        .each(fn(input) { @web_midi.MidiInput::clear_on_midi_message(input) })
      }
      midi_active_notes.set([])
      selected_id.set(new_id)
      if new_id != "none" {
        available_inputs
        .get()
        .iter()
        .filter(fn(input) { @web_midi.MidiInput::id(input) == new_id })
        .each(fn(input) {
          @web_midi.MidiInput::set_on_midi_message(input, on_message)
        })
      }
    })
    @web_midi.request_midi_access(
      fn(access) {
        let inputs = @web_midi.MidiAccess::list_inputs(access)
        available_inputs.set(inputs)
        ffi_update_select_options(
          select_elem,
          inputs.map(fn(input) { @web_midi.MidiInput::id(input) }),
          inputs.map(fn(input) { @web_midi.MidiInput::name(input) }),
        )
      },
      fn() { () },
    )
    @luna_dom.ToDomNode::to_dom_node(select_elem)
  }
}

///|
extern "js" fn ffi_add_none_option(select : @js_dom.Element) -> Unit =
  #| (select) => {
  #|   const opt = document.createElement('option');
  #|   opt.value = 'none';
  #|   opt.textContent = 'None';
  #|   select.appendChild(opt);
  #| }

///|
extern "js" fn ffi_add_change_listener(
  select : @js_dom.Element,
  callback : (String) -> Unit,
) -> Unit =
  #| (select, callback) => {
  #|   select.addEventListener('change', (e) => callback(e.target.value));
  #| }

///|
extern "js" fn ffi_update_select_options(
  select : @js_dom.Element,
  ids : Array[String],
  names : Array[String],
) -> Unit =
  #| (select, ids, names) => {
  #|   while (select.options.length > 1) select.remove(1);
  #|   ids.forEach((id, i) => {
  #|     const opt = document.createElement('option');
  #|     opt.value = id;
  #|     opt.textContent = names[i];
  #|     select.appendChild(opt);
  #|   });
  #| }
