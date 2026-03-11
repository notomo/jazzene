///|
/// FFI: receive byte array, create Blob, and download as melody.mid
extern "js" fn open_bytes_as_midi(arr : Array[Int]) -> Unit =
  #|(arr) => {
  #|  const bytes = new Uint8Array(arr);
  #|  const blob = new Blob([bytes], { type: 'audio/midi' });
  #|  const url = URL.createObjectURL(blob);
  #|  const a = document.createElement('a');
  #|  a.href = url;
  #|  a.download = 'melody.mid';
  #|  a.click();
  #|  URL.revokeObjectURL(url);
  #|}

///|
/// Export button that encodes current sounds to MIDI and opens in a new tab
pub fn midi_export_button(
  get_midi_bytes : () -> Array[Int],
) -> @luna_dom.DomNode {
  @luna_dom.button(
    class="w-full px-2 py-0.5 text-xs bg-slate-900 hover:bg-slate-700 border border-slate-600 rounded text-slate-300 text-left",
    on=@luna_dom.events().click(fn(_) { open_bytes_as_midi(get_midi_bytes()) }),
    [@luna_dom.text("Export MIDI")],
  )
}
