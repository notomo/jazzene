///|
test "duration_visual_weight - quarter note is 1.0" {
  inspect(duration_visual_weight(Quarter), content="1")
}

///|
test "duration_visual_weight - whole note is 2.25" {
  inspect(duration_visual_weight(Whole), content="2.25")
}

///|
test "compute_note_positions - single note" {
  let positioned = [
    (
      0.0,
      @music.MeasureNote::{
        midi: Some(60),
        duration: Quarter,
        accidental: None,
        tie: None,
        tone_origin: None,
      },
    ),
  ]
  let measure_x = 90.0
  let beamed : Map[Int, Bool] = {}
  let positions = compute_note_positions(positioned, measure_x, beamed)
  inspect(positions.length(), content="1")
  inspect(positions[0], content="132") // measure_x + NOTE_AREA_START_OFFSET
}

///|
test "compute_note_positions - two equal notes" {
  let note = @music.MeasureNote::{
    midi: Some(60),
    duration: Quarter,
    accidental: None,
    tie: None,
    tone_origin: None,
  }
  let positioned = [(0.0, note), (1.0, note)]
  let measure_x = 90.0
  let beamed : Map[Int, Bool] = {}
  let positions = compute_note_positions(positioned, measure_x, beamed)
  inspect(positions.length(), content="2")
  // First note at start, second proportionally placed
  inspect(positions[0], content="132")
}

///|
test "compute_note_positions - whole rest centered" {
  let positioned = [
    (
      0.0,
      @music.MeasureNote::{
        midi: None,
        duration: Whole,
        accidental: None,
        tie: None,
        tone_origin: None,
      },
    ),
  ]
  let measure_x = 90.0
  let beamed : Map[Int, Bool] = {}
  let positions = compute_note_positions(positioned, measure_x, beamed)
  inspect(positions[0], content="250") // measure_x + MIN_MEASURE_WIDTH / 2.0
}
