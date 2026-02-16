///|
test "beam_stem_up - low note goes up" {
  let positioned = [
    (
      0.0,
      @music.MeasureNote::{
        midi: Some(60),
        duration: Eighth,
        accidental: None,
        tie: None,
      },
    ),
  ]
  inspect(beam_stem_up([0], positioned), content="true")
}

///|
test "beam_stem_up - high note goes down" {
  let positioned = [
    (
      0.0,
      @music.MeasureNote::{
        midi: Some(80),
        duration: Eighth,
        accidental: None,
        tie: None,
      },
    ),
  ]
  inspect(beam_stem_up([0], positioned), content="false")
}
