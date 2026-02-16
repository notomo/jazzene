///|
/// Key signature rendering on staff

///|
const KEY_SIG_START_OFFSET = 30.0

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
  let c_major = @music.KeySignature::c_major()
  positions
  .iter()
  .mapi(fn(i, midi) {
    let symbol_x = x +
      KEY_SIG_START_OFFSET +
      i.to_double() * @sheet_layout.KEY_SIG_SYMBOL_SPACING
    let symbol_y = @sheet_layout.midi_to_staff_y(midi, y, c_major)
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
        x -
        @sheet_layout.CLEF_SPACE_WIDTH -
        @sheet_layout.key_signature_layout_width(key),
        y,
      )
    false => []
  }
}
