///|
/// Key signature rendering on staff

///|
const KEY_SIG_SYMBOL_SPACING = 12.0

///|
const KEY_SIG_START_OFFSET = 30.0

///|
/// Calculate the width of the key signature rendering area
fn key_signature_width(key : @music.KeySignature) -> Double {
  let count = key.altered_steps.length()
  if count == 0 {
    0.0
  } else {
    count.to_double() * KEY_SIG_SYMBOL_SPACING + 5.0
  }
}

///|
/// Render key signature accidentals after the treble clef
fn render_key_signature(
  key : @music.KeySignature,
  x : Double,
  y : Double,
) -> Array[@luna_dom.DomNode] {
  let positions = key.signature_midi_positions()
  if positions.is_empty() {
    return []
  }
  // Use C major for key signature position calculation since these are
  // standard treble clef positions independent of the current key
  let c_major = @music.KeySignature::c_major()
  positions
  .iter()
  .mapi(fn(i, midi) {
    let symbol_x = x +
      KEY_SIG_START_OFFSET +
      i.to_double() * KEY_SIG_SYMBOL_SPACING
    let symbol_y = midi_to_staff_y(midi, y, c_major)
    match key.accidental_type {
      Sharp => render_sharp(symbol_x, symbol_y)
      Flat => render_flat(symbol_x, symbol_y)
      Natural => render_natural(symbol_x, symbol_y)
    }
  })
  .collect()
}

///|
/// Render key signature for a measure (only on first measure of each row)
fn render_measure_key_signature(
  key : @music.KeySignature,
  x : Double,
  y : Double,
  is_first_in_row : Bool,
) -> Array[@luna_dom.DomNode] {
  match is_first_in_row {
    true =>
      render_key_signature(
        key,
        x - CLEF_SPACE_WIDTH - key_signature_width(key),
        y,
      )
    false => []
  }
}
