///|
/// [MIDIMessageEvent](https://developer.mozilla.org/en-US/docs/Web/API/MIDIMessageEvent)
pub struct MidiMessageEvent {
  data : Bytes
}

///|
/// [MIDIInput](https://developer.mozilla.org/en-US/docs/Web/API/MIDIInput)
pub struct MidiInput {
  id : String
  name : String
  priv raw : @js.Any
}

///|
/// [MIDIInputMap](https://developer.mozilla.org/en-US/docs/Web/API/MIDIInputMap)
pub type MidiInputMap = @sorted_map.SortedMap[String, MidiInput]

///|
/// [MIDIAccess](https://developer.mozilla.org/en-US/docs/Web/API/MIDIAccess)
pub struct MidiAccess {
  inputs : MidiInputMap
  sysex_enabled : Bool
}

///|
fn make_midi_input(raw : @js.Any) -> MidiInput {
  { id: raw._get("id").cast(), name: raw._get("name").cast(), raw }
}

///|
fn make_midi_input_map(access_any : @js.Any) -> MidiInputMap {
  let raws = ffi_collect_inputs(access_any)
  @sorted_map.from_array(
    raws.map(fn(raw) {
      let input = make_midi_input(raw)
      (input.id, input)
    }),
  )
}

///|
fn make_midi_access(raw : @js.Any) -> MidiAccess {
  {
    inputs: make_midi_input_map(raw),
    sysex_enabled: raw._get("sysexEnabled").cast(),
  }
}

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
/// Request access to MIDI devices.
pub async fn request_midi_access() -> MidiAccess {
  let raw = ffi_request_midi_access().wait()
  make_midi_access(raw)
}

///|
extern "js" fn ffi_request_midi_access() -> @js.Promise[@js.Any] =
  #| () => navigator.requestMIDIAccess()

///|
// Note: Array.from() is intentionally avoided here — it is not supported
// in some Web MIDI browser environments (e.g. Web MIDI Browser on iOS).
extern "js" fn ffi_collect_inputs(access : @js.Any) -> Array[@js.Any] =
  #| (access) => {
  #|   const inputs = []
  #|   access.inputs.forEach(input => inputs.push(input))
  #|   return inputs
  #| }

///|
/// [MIDIInput: midimessage event](https://developer.mozilla.org/en-US/docs/Web/API/MIDIInput/midimessage_event)
///
/// Set the message handler for this MIDI input.
pub fn MidiInput::set_on_midi_message(
  self : MidiInput,
  handler : (MidiMessageEvent) -> Unit,
) -> Unit {
  ffi_set_on_midi_message(self.raw, fn(event_any) {
    let data : Bytes = event_any._get("data").cast()
    handler({ data, })
  })
}

///|
extern "js" fn ffi_set_on_midi_message(
  input : @js.Any,
  handler : (@js.Any) -> Unit,
) -> Unit =
  #| (input, handler) => { input.onmidimessage = (event) => handler(event) }

///|
/// Clear the message handler for this MIDI input.
///
/// See [MIDIInput: midimessage event](https://developer.mozilla.org/en-US/docs/Web/API/MIDIInput/midimessage_event)
pub fn MidiInput::clear_on_midi_message(self : MidiInput) -> Unit {
  ffi_clear_on_midi_message(self.raw)
}

///|
extern "js" fn ffi_clear_on_midi_message(input : @js.Any) -> Unit =
  #| (input) => { input.onmidimessage = null }

///|
/// [MIDIPort.open()](https://developer.mozilla.org/en-US/docs/Web/API/MIDIPort/open)
///
/// Explicitly open this MIDI input port.
pub async fn MidiInput::open(self : MidiInput) -> Unit {
  ignore(ffi_open_midi_input(self.raw).wait())
}

///|
extern "js" fn ffi_open_midi_input(input : @js.Any) -> @js.Promise[@js.Any] =
  #| (input) => input.open()
