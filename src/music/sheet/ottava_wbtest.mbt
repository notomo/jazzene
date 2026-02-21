///|
test "should_apply_8va - high note triggers" {
  let positioned = [
    (
      0.0,
      @music.MeasureNote::{
        midi: Some(85),
        duration: Quarter,
        accidental: None,
        tie: None,
        tone_origin: None,
      },
    ),
  ]
  inspect(should_apply_8va(positioned), content="true")
}

///|
test "should_apply_8va - normal note does not trigger" {
  let positioned = [
    (
      0.0,
      @music.MeasureNote::{
        midi: Some(72),
        duration: Quarter,
        accidental: None,
        tie: None,
        tone_origin: None,
      },
    ),
  ]
  inspect(should_apply_8va(positioned), content="false")
}

///|
test "shift_for_8va - shifts midi down by 12" {
  let positioned = [
    (
      0.0,
      @music.MeasureNote::{
        midi: Some(84),
        duration: Quarter,
        accidental: None,
        tie: None,
        tone_origin: None,
      },
    ),
  ]
  let shifted = shift_for_8va(positioned)
  inspect(shifted[0].1.midi, content="Some(72)")
}

///|
test "shift_for_8vb - shifts midi up by 12" {
  let positioned = [
    (
      0.0,
      @music.MeasureNote::{
        midi: Some(48),
        duration: Quarter,
        accidental: None,
        tie: None,
        tone_origin: None,
      },
    ),
  ]
  let shifted = shift_for_8vb(positioned)
  inspect(shifted[0].1.midi, content="Some(60)")
}
