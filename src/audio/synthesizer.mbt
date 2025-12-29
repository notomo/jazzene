///|
/// Play a sequence of notes with timing
pub fn play_note_sequence(
  engine : AudioEngine,
  notes : Array[@core.Note],
  bpm : Int,
  on_note_callback : (Int) -> Unit,
) -> Unit {
  let ms_per_quarter = 60000 / bpm
  for i = 0; i < notes.length(); i = i + 1 {
    let note = notes[i]
    let delay_ms = i * ms_per_quarter

    // Schedule note playback
    ffi_set_timeout(
      fn() {
        engine.play_note(note, ms_per_quarter - 50) // Slight gap between notes
        on_note_callback(i)
      },
      delay_ms,
    )
  }
}

///|
/// FFI: JavaScript setTimeout
extern "js" fn ffi_set_timeout(callback : () -> Unit, delay_ms : Int) -> Unit =
  #| (callback, delayMs) => {
  #|   setTimeout(callback, delayMs);
  #| }
