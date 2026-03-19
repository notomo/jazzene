///|
fn open_file_picker(on_bytes : (Array[Int]) -> Unit) -> Unit {
  let input = @js_dom.document().create_element("input")
  input.as_any()._set("type", @js.any("file"))
  input.as_any()._set("accept", @js.any(".mid,.midi"))
  input
  .as_event_target()
  .addEventListener("change", fn(e) {
    let files = e._get("target")._get("files")
    let length : Int = files._get("length").cast()
    if length == 0 {
      return
    }
    let file = files._get_by_index(0)
    let reader = @js_file.FileReader::new()
    reader
    .as_any()
    ._set(
      "onload",
      @js.from_fn1(fn(ev : @js.Any) {
        let result = ev._get("target")._get("result")
        let uint8 = @arraybuffer.Uint8Array::from_array_buffer(result.cast())
        let bytes = @arraybuffer.uint8array_to_bytes(uint8)
        let arr = Array::makei(bytes.length(), fn(i) { bytes[i].to_int() })
        on_bytes(arr)
      }),
    )
    reader.as_any()._call("readAsArrayBuffer", [file]) |> ignore
  })
  input.as_any()._call("click", []) |> ignore
}

///|
/// Button that opens a MIDI file picker and calls on_import with the file bytes.
pub fn midi_import_button(
  on_import : (Array[Int]) -> Unit,
) -> @luna_dom.DomNode {
  @luna_dom.button(
    class="flex-1 px-2 py-0.5 text-xs bg-slate-900 hover:bg-slate-700 border border-slate-600 rounded text-slate-300 text-center",
    on=@luna_dom.events().click(fn(_) { open_file_picker(on_import) }),
    [@luna_dom.text("Import")],
  )
}
