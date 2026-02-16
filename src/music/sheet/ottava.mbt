///|
const OTTAVA_ALTA_THRESHOLD_MIDI : Int = 84

///|
const OTTAVA_BASSA_LEDGER_LINE_THRESHOLD : Int = 4

///|
const OTTAVA_SHIFT : Int = 12

///|
/// Ottava marking state for a measure
pub(all) enum OttavaMarking {
  OttavaNone
  OttavaAlta
  OttavaBassa
} derive(Eq, Show)

///|
/// Returns true if any pitched note in the measure has MIDI >= threshold
fn should_apply_8va(positioned : Array[(Double, @music.MeasureNote)]) -> Bool {
  positioned
  .iter()
  .any(fn(pair) {
    match pair.1.midi {
      Some(midi) => midi >= OTTAVA_ALTA_THRESHOLD_MIDI
      None => false
    }
  })
}

///|
/// Returns true if any pitched note needs >= threshold ledger lines below the staff
fn should_apply_8vb(
  positioned : Array[(Double, @music.MeasureNote)],
  key : @music.KeySignature,
) -> Bool {
  positioned
  .iter()
  .any(fn(pair) {
    match pair.1.midi {
      Some(midi) => {
        let step = midi_to_diatonic_step(midi, key)
        ledger_steps_below(step).length() >= OTTAVA_BASSA_LEDGER_LINE_THRESHOLD
      }
      None => false
    }
  })
}

///|
/// Creates a copy with all MIDI values shifted down by OTTAVA_SHIFT
fn shift_for_8va(
  positioned : Array[(Double, @music.MeasureNote)],
) -> Array[(Double, @music.MeasureNote)] {
  positioned.map(fn(pair) {
    let (pos, note) = pair
    let shifted_midi = note.midi.map(fn(m) { m - OTTAVA_SHIFT })
    (pos, { ..note, midi: shifted_midi })
  })
}

///|
/// Creates a copy with all MIDI values shifted up by OTTAVA_SHIFT
fn shift_for_8vb(
  positioned : Array[(Double, @music.MeasureNote)],
) -> Array[(Double, @music.MeasureNote)] {
  positioned.map(fn(pair) {
    let (pos, note) = pair
    let shifted_midi = note.midi.map(fn(m) { m + OTTAVA_SHIFT })
    (pos, { ..note, midi: shifted_midi })
  })
}
