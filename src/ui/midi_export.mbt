///|
extern "js" fn @js_url.URL::create_object_url(blob : @js_blob.Blob) -> String =
  #|(blob) => URL.createObjectURL(blob)

///|
extern "js" fn @js_url.URL::revoke_object_url(url : String) -> Unit =
  #|(url) => URL.revokeObjectURL(url)

///|
fn pad2(n : Int) -> String {
  if n < 10 {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}

///|
fn open_bytes_as_midi(arr : Array[Int]) -> Unit {
  let uint8 = @arraybuffer.Uint8Array::from_array(arr)
  let blob = @js_blob.Blob::new([uint8.as_any()], content_type="audio/midi")
  let url = @js_url.URL::create_object_url(blob)
  let a = @js_dom.document().create_element("a")
  a.as_any()._set("href", @js.any(url))
  let now = @js_date.Date::new()
  let datetime = now.get_full_year().to_string() +
    pad2(now.get_month() + 1) +
    pad2(now.get_date()) +
    "_" +
    pad2(now.get_hours()) +
    pad2(now.get_minutes()) +
    pad2(now.get_seconds())
  a.as_any()._set("download", @js.any("jazzene_" + datetime + ".mid"))
  a.as_any()._call("click", []) |> ignore
  @js_url.URL::revoke_object_url(url)
}

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
