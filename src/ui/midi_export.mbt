///|
/// FFI: receive byte array, create Blob, and download as jazzene_{datetime}.mid
extern "js" fn open_bytes_as_midi(arr : Array[Int]) -> Unit =
  #|(arr) => {
  #|  const bytes = new Uint8Array(arr);
  #|  const blob = new Blob([bytes], { type: 'audio/midi' });
  #|  const url = URL.createObjectURL(blob);
  #|  const a = document.createElement('a');
  #|  a.href = url;
  #|  const now = new Date();
  #|  const pad = n => String(n).padStart(2, '0');
  #|  const datetime = `${now.getFullYear()}${pad(now.getMonth()+1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
  #|  a.download = `jazzene_${datetime}.mid`;
  #|  a.click();
  #|  URL.revokeObjectURL(url);
  #|}

///|
/// Export button that encodes current sounds to MIDI and opens in a new tab
pub fn midi_export_button(
  get_midi_bytes : () -> Array[Int],
) -> @luna_dom.DomNode {
  @luna_dom.button(
    class="flex-1 px-2 py-0.5 text-xs bg-slate-900 hover:bg-slate-700 border border-slate-600 rounded text-slate-300 text-center",
    on=@luna_dom.events().click(fn(_) { open_bytes_as_midi(get_midi_bytes()) }),
    [@luna_dom.text("Export")],
  )
}
