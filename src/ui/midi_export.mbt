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
  sounds : () -> Array[@music.ScheduledSound],
  bpm : () -> Int,
  time_signature : () -> @music.TimeSignature,
  key_signature : () -> @music.KeySignature,
  raw_chord_progression : () -> String,
  seed : () -> Int,
) -> @luna_dom.DomNode {
  @luna_dom.button(
    class="w-full px-2 py-0.5 text-xs bg-slate-900 hover:bg-slate-700 border border-slate-600 rounded text-slate-300 text-left",
    on=@luna_dom.events().click(fn(_) {
      let text = "chords: " +
        raw_chord_progression() +
        " seed: " +
        seed().to_string()
      let bytes = @midi.encode_to_midi(
        sounds(),
        bpm(),
        time_signature=time_signature(),
        key_signature=key_signature(),
        text~,
      )
      open_bytes_as_midi(bytes)
    }),
    [@luna_dom.text("Export MIDI")],
  )
}
