///|
/// FFI: open a file picker for .mid files and call onBytes with the raw bytes.
extern "js" fn open_file_picker(on_bytes : (Array[Int]) -> Unit) -> Unit =
  #|(onBytes) => {
  #|  const input = document.createElement('input');
  #|  input.type = 'file';
  #|  input.accept = '.mid,.midi';
  #|  input.onchange = (e) => {
  #|    const file = e.target.files[0];
  #|    if (!file) return;
  #|    const reader = new FileReader();
  #|    reader.onload = (ev) => {
  #|      const buf = new Uint8Array(ev.target.result);
  #|      onBytes(Array.from(buf));
  #|    };
  #|    reader.readAsArrayBuffer(file);
  #|  };
  #|  input.click();
  #|}

///|
/// Button that opens a MIDI file picker and calls on_import with the file bytes.
pub fn midi_import_button(
  on_import : (Array[Int]) -> Unit,
) -> @luna_dom.DomNode {
  @luna_dom.button(
    class="w-full px-2 py-0.5 text-xs bg-slate-900 hover:bg-slate-700 border border-slate-600 rounded text-slate-300 text-left",
    on=@luna_dom.events().click(fn(_) { open_file_picker(on_import) }),
    [@luna_dom.text("Import MIDI")],
  )
}
