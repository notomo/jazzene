///|
test "positioned_notes: simple quarter notes" {
  let measure = Measure::{
    chords: [],
    start_time: Duration::from_milliseconds(0),
    beats: [
      Beat::{
        count: 0,
        notes: [
          MeasureNote::{
            midi: Some(60),
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
      Beat::{
        count: 1,
        notes: [
          MeasureNote::{
            midi: Some(62),
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
      Beat::{
        count: 2,
        notes: [
          MeasureNote::{
            midi: Some(64),
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
      Beat::{
        count: 3,
        notes: [
          MeasureNote::{
            midi: Some(65),
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
    ],
  }
  let positions = measure.positioned_notes()
  assert_eq(positions.length(), 4)
  assert_eq(positions[0].0, 0.0)
  assert_eq(positions[1].0, 1.0)
  assert_eq(positions[2].0, 2.0)
  assert_eq(positions[3].0, 3.0)
}

///|
test "positioned_notes: dotted quarter overflows into next beat" {
  // quarter rest, quarter note, dotted quarter, eighth note
  let measure = Measure::{
    chords: [],
    start_time: Duration::from_milliseconds(0),
    beats: [
      Beat::{
        count: 0,
        notes: [
          MeasureNote::{
            midi: None,
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
      Beat::{
        count: 1,
        notes: [
          MeasureNote::{
            midi: Some(60),
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
      Beat::{
        count: 2,
        notes: [
          MeasureNote::{
            midi: Some(62),
            duration: DottedQuarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
      Beat::{
        count: 3,
        notes: [
          MeasureNote::{
            midi: Some(64),
            duration: Eighth,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
    ],
  }
  let positions = measure.positioned_notes()
  assert_eq(positions.length(), 4)
  assert_eq(positions[0].0, 0.0) // quarter rest
  assert_eq(positions[1].0, 1.0) // quarter note
  assert_eq(positions[2].0, 2.0) // dotted quarter
  assert_eq(positions[3].0, 3.5) // eighth note after dotted quarter ends
}

///|
test "positioned_notes: two eighths in one beat" {
  let measure = Measure::{
    chords: [],
    start_time: Duration::from_milliseconds(0),
    beats: [
      Beat::{
        count: 0,
        notes: [
          MeasureNote::{
            midi: Some(60),
            duration: Eighth,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
          MeasureNote::{
            midi: Some(62),
            duration: Eighth,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
      Beat::{
        count: 1,
        notes: [
          MeasureNote::{
            midi: Some(64),
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
    ],
  }
  let positions = measure.positioned_notes()
  assert_eq(positions.length(), 3)
  assert_eq(positions[0].0, 0.0)
  assert_eq(positions[1].0, 0.5)
  assert_eq(positions[2].0, 1.0)
}

///|
test "positioned_notes: half note overflows two beats" {
  let measure = Measure::{
    chords: [],
    start_time: Duration::from_milliseconds(0),
    beats: [
      Beat::{
        count: 0,
        notes: [
          MeasureNote::{
            midi: Some(60),
            duration: Half,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
      // beat 1 is empty (half note occupies it)
      Beat::{ count: 1, notes: [] },
      Beat::{
        count: 2,
        notes: [
          MeasureNote::{
            midi: Some(64),
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
    ],
  }
  let positions = measure.positioned_notes()
  assert_eq(positions.length(), 2)
  assert_eq(positions[0].0, 0.0) // half note
  assert_eq(positions[1].0, 2.0) // quarter note at beat 2
}
