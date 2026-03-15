///|
/// Compute semitone shift from imported key to current key, normalized to [-6, 6]
pub fn key_shift(data : ImportedMidi, current_key : @music.KeySignature) -> Int {
  match data.key {
    None => 0
    Some(orig_key) => {
      let raw = current_key.root.midi() - orig_key.root.midi()
      if raw > 6 {
        raw - 12
      } else if raw < -6 {
        raw + 12
      } else {
        raw
      }
    }
  }
}

///|
/// Adapt melody/comping/bass sounds: rescale timing by BPM and transpose by key
pub fn adapt_pitched(
  data : ImportedMidi,
  current_bpm : Int,
  current_key : @music.KeySignature,
  sounds : Array[@music.ScheduledSound],
) -> Array[@music.ScheduledSound] {
  sounds
  |> @music.rescale_sounds(data.bpm.unwrap_or(current_bpm), current_bpm)
  |> @music.transpose_sounds(key_shift(data, current_key))
}
