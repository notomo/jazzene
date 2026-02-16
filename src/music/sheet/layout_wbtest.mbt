///|
test "compute_sheet_measure - basic quarter note measure" {
  let measure = @music.Measure::{
    chords: [],
    beats: [
      @music.Beat::{
        count: 0,
        notes: [
          @music.MeasureNote::{
            midi: Some(60),
            duration: Quarter,
            accidental: None,
            tie: None,
          },
        ],
      },
      @music.Beat::{
        count: 1,
        notes: [
          @music.MeasureNote::{
            midi: Some(64),
            duration: Quarter,
            accidental: None,
            tie: None,
          },
        ],
      },
    ],
    start_time: @music.Duration::from_milliseconds(0.0),
  }
  let key = @music.KeySignature::c_major()
  let time_sig = @music.TimeSignature::default()
  let sheet = compute_sheet_measure(measure, 0, key, time_sig)
  inspect(sheet.notes.length(), content="2")
  inspect(sheet.beam_groups.length(), content="0")
  inspect(sheet.ottava, content="OttavaNone")
  inspect(sheet.is_first_in_row, content="true")
}

///|
test "compute_sheet_measure - eighth notes get beamed" {
  let measure = @music.Measure::{
    chords: [],
    beats: [
      @music.Beat::{
        count: 0,
        notes: [
          @music.MeasureNote::{
            midi: Some(60),
            duration: Eighth,
            accidental: None,
            tie: None,
          },
          @music.MeasureNote::{
            midi: Some(64),
            duration: Eighth,
            accidental: None,
            tie: None,
          },
        ],
      },
    ],
    start_time: @music.Duration::from_milliseconds(0.0),
  }
  let key = @music.KeySignature::c_major()
  let time_sig = @music.TimeSignature::default()
  let sheet = compute_sheet_measure(measure, 0, key, time_sig)
  inspect(sheet.notes.length(), content="2")
  inspect(sheet.beam_groups.length(), content="1")
  inspect(sheet.notes[0].beamed, content="true")
  inspect(sheet.notes[1].beamed, content="true")
}

///|
test "compute_sheet_measure - high note triggers 8va" {
  let measure = @music.Measure::{
    chords: [],
    beats: [
      @music.Beat::{
        count: 0,
        notes: [
          @music.MeasureNote::{
            midi: Some(88),
            duration: Quarter,
            accidental: None,
            tie: None,
          },
        ],
      },
    ],
    start_time: @music.Duration::from_milliseconds(0.0),
  }
  let key = @music.KeySignature::c_major()
  let time_sig = @music.TimeSignature::default()
  let sheet = compute_sheet_measure(measure, 0, key, time_sig)
  inspect(sheet.ottava, content="OttavaAlta")
  // Note should be shifted down by 12
  inspect(sheet.notes[0].midi, content="Some(76)")
}
