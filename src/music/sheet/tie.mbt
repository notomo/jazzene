///|
/// Pre-computed tie arc layout data
pub(all) struct SheetTieArc {
  start_x : Double
  end_x : Double
  note_y : Double
  stem_up : Bool
} derive(Show)

///|
fn compute_tie_arcs(
  tie : @music.Tie?,
  note_x : Double,
  midi : Int,
  staff_y : Double,
  measure_x : Double,
  key : @music.KeySignature,
  prev_note_x : Double?,
  next_note_x : Double?,
) -> Array[SheetTieArc] {
  let note_y = midi_to_staff_y(midi, staff_y, key)
  let stem_up = midi < STEM_DIRECTION_MIDI_THRESHOLD
  let measure_start_x = measure_x
  let measure_end_x = measure_x + MEASURE_WIDTH
  match tie {
    Some(TieStart) => {
      let end_x = match next_note_x {
        Some(nx) => nx
        None => measure_end_x
      }
      [SheetTieArc::{ start_x: note_x, end_x, note_y, stem_up }]
    }
    Some(TieEnd) => {
      let start_x = match prev_note_x {
        Some(px) => px
        None => measure_start_x
      }
      [SheetTieArc::{ start_x, end_x: note_x, note_y, stem_up }]
    }
    Some(TieBoth) => {
      let start_x = match prev_note_x {
        Some(px) => px
        None => measure_start_x
      }
      let end_x = match next_note_x {
        Some(nx) => nx
        None => measure_end_x
      }
      [
        SheetTieArc::{ start_x, end_x: note_x, note_y, stem_up },
        SheetTieArc::{ start_x: note_x, end_x, note_y, stem_up },
      ]
    }
    None => []
  }
}
