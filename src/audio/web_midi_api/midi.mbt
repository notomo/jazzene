///|
/// [MIDIAccess](https://developer.mozilla.org/en-US/docs/Web/API/MIDIAccess)
#external
pub type MidiAccess

///|
pub fn MidiAccess::as_any(self : MidiAccess) -> @js.Any = "%identity"

///|
/// [MIDIInput](https://developer.mozilla.org/en-US/docs/Web/API/MIDIInput)
#external
pub type MidiInput

///|
pub fn MidiInput::as_any(self : MidiInput) -> @js.Any = "%identity"

///|
/// Check if the browser supports the Web MIDI API.
///
/// Returns `true` if [Navigator.requestMIDIAccess](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/requestMIDIAccess)
/// is available.
pub fn is_midi_supported() -> Bool {
  ffi_is_midi_supported()
}

///|
extern "js" fn ffi_is_midi_supported() -> Bool =
  #| () => typeof navigator !== 'undefined' && !!navigator.requestMIDIAccess

///|
/// [Navigator.requestMIDIAccess()](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/requestMIDIAccess)
///
/// Request access to MIDI devices. Calls `on_success` with a `MidiAccess` on
/// success, or `on_failure` if permission is denied or an error occurs.
pub fn request_midi_access(
  on_success : (MidiAccess) -> Unit,
  on_failure : () -> Unit,
) -> Unit {
  ffi_request_midi_access(on_success, on_failure)
}

///|
extern "js" fn ffi_request_midi_access(
  on_success : (MidiAccess) -> Unit,
  on_failure : () -> Unit,
) -> Unit =
  #| async (onSuccess, onFailure) => {
  #|   try {
  #|     const access = await navigator.requestMIDIAccess()
  #|     onSuccess(access)
  #|   } catch (e) {
  #|     onFailure()
  #|   }
  #| }

///|
/// [MIDIAccess.inputs](https://developer.mozilla.org/en-US/docs/Web/API/MIDIAccess/inputs)
///
/// Get all available MIDI input devices.
pub fn MidiAccess::list_inputs(self : MidiAccess) -> Array[MidiInput] {
  ffi_list_inputs(self.as_any())
}

///|
extern "js" fn ffi_list_inputs(access : @js.Any) -> Array[MidiInput] =
  #| (access) => {
  #|   const inputs = []
  #|   access.inputs.forEach(input => inputs.push(input))
  #|   return inputs
  #| }

///|
/// [MIDIPort.id](https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/id)
///
/// Get the unique identifier of the MIDI input.
pub fn MidiInput::id(self : MidiInput) -> String {
  self.as_any()._get("id").cast()
}

///|
/// [MIDIPort.name](https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/name)
///
/// Get the name of the MIDI input device.
pub fn MidiInput::name(self : MidiInput) -> String {
  self.as_any()._get("name").cast()
}

///|
/// [MIDIInput: midimessage event](https://developer.mozilla.org/en-US/docs/Web/API/MIDIInput/midimessage_event)
///
/// Set the message handler for this MIDI input. The handler receives
/// `(status, note, velocity)` from the MIDI message data bytes.
pub fn MidiInput::set_on_midi_message(
  self : MidiInput,
  handler : (Int, Int, Int) -> Unit,
) -> Unit {
  ffi_set_on_midi_message(self.as_any(), handler)
}

///|
extern "js" fn ffi_set_on_midi_message(
  input : @js.Any,
  handler : (Int, Int, Int) -> Unit,
) -> Unit =
  #| (input, handler) => {
  #|   input.onmidimessage = (event) => {
  #|     const data = event.data;
  #|     handler(data[0] !== undefined ? data[0] : 0, data[1] !== undefined ? data[1] : 0, data[2] !== undefined ? data[2] : 0);
  #|   };
  #| }

///|
/// Clear the message handler for this MIDI input.
///
/// See [MIDIInput: midimessage event](https://developer.mozilla.org/en-US/docs/Web/API/MIDIInput/midimessage_event)
pub fn MidiInput::clear_on_midi_message(self : MidiInput) -> Unit {
  ffi_clear_on_midi_message(self.as_any())
}

///|
extern "js" fn ffi_clear_on_midi_message(input : @js.Any) -> Unit =
  #| (input) => { input.onmidimessage = null; }
