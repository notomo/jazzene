///|
pub const STAFF_TOP : Double = 120.0

///|
pub const MEASURES_PER_ROW : Int = 4

///|
pub const MIN_MEASURE_WIDTH : Double = 320.0

///|
pub const CLEF_SPACE_WIDTH : Double = 50.0

///|
pub const MEASURE_START_X : Double = 40.0

///|
pub const ROW_HEIGHT : Double = 300.0

///|
pub const KEY_SIG_SYMBOL_SPACING : Double = 12.0

///|
/// Pre-computed measure layout data
pub(all) struct SheetMeasure {
  x : Double
  y : Double
  width : Double
  notes : Array[SheetNote]
  beam_groups : Array[SheetBeamGroup]
  ottava : OttavaMarking
  is_first_in_row : Bool
} derive(Show)

///|
/// Calculate the width of the key signature rendering area
pub fn key_signature_layout_width(key : @music.KeySignature) -> Double {
  let count = key.altered_steps.length()
  if count == 0 {
    0.0
  } else {
    count.to_double() * KEY_SIG_SYMBOL_SPACING + 5.0
  }
}

///|
/// Calculate measure position in the layout grid
pub fn measure_position(
  measure_index : Int,
  key : @music.KeySignature,
  measure_width? : Double = MIN_MEASURE_WIDTH,
) -> (Double, Double) {
  let col = measure_index % MEASURES_PER_ROW
  let row = measure_index / MEASURES_PER_ROW
  let clef_offset = CLEF_SPACE_WIDTH + key_signature_layout_width(key)
  let x = MEASURE_START_X + clef_offset + col.to_double() * measure_width
  let y = STAFF_TOP + row.to_double() * ROW_HEIGHT
  (x, y)
}
