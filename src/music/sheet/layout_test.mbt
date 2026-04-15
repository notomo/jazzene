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
            tone_origin: None,
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
            tone_origin: None,
          },
        ],
      },
    ],
    start_time: @music.Duration::from_milliseconds(0.0),
  }
  let key = @music.KeySignature::c_major()
  let time_signature = @music.TimeSignature::default()
  let sheet = compute_sheet_measure(measure, 0, key, time_signature)
  inspect(sheet.notes.length(), content="2")
  inspect(sheet.beam_groups.length(), content="0")
  inspect(sheet.ottava.kind, content="OttavaNone")
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
            tone_origin: None,
          },
          @music.MeasureNote::{
            midi: Some(64),
            duration: Eighth,
            accidental: None,
            tie: None,
            tone_origin: None,
          },
        ],
      },
    ],
    start_time: @music.Duration::from_milliseconds(0.0),
  }
  let key = @music.KeySignature::c_major()
  let time_signature = @music.TimeSignature::default()
  let sheet = compute_sheet_measure(measure, 0, key, time_signature)
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
            tone_origin: None,
          },
        ],
      },
    ],
    start_time: @music.Duration::from_milliseconds(0.0),
  }
  let key = @music.KeySignature::c_major()
  let time_signature = @music.TimeSignature::default()
  let sheet = compute_sheet_measure(measure, 0, key, time_signature, ottava={
    kind: OttavaAlta,
    role: SpanSole,
  })
  inspect(sheet.ottava.kind, content="OttavaAlta")
  // Note should be shifted down by 12
  inspect(sheet.notes[0].midi, content="Some(76)")
}

///|
fn make_high_note_measure() -> @music.Measure {
  @music.Measure::{
    chords: [],
    beats: [
      @music.Beat::{
        count: 0,
        notes: [88, 89, 90, 91].map(fn(m) {
          @music.MeasureNote::{
            midi: Some(m),
            duration: Quarter,
            accidental: None,
            tie: None,
            tone_origin: None,
          }
        }),
      },
    ],
    start_time: @music.Duration::from_milliseconds(0.0),
  }
}

///|
test "cross-measure 8va span: consecutive measures share span roles via compute_ottava_spans" {
  let key = @music.KeySignature::c_major()
  let time_signature = @music.TimeSignature::default()
  let high = make_high_note_measure()
  let measures = [high, high, high]

  let spans = compute_ottava_spans(measures, key)
  let sheets = spans
    .iter()
    .mapi(fn(i, span) {
      compute_sheet_measure(measures[i], i, key, time_signature, ottava=span)
    })
    .collect()

  // All three measures are 8va
  inspect(sheets[0].ottava.kind, content="OttavaAlta")
  inspect(sheets[1].ottava.kind, content="OttavaAlta")
  inspect(sheets[2].ottava.kind, content="OttavaAlta")

  // Span roles show the cross-measure continuity
  inspect(sheets[0].ottava.role, content="SpanFirst")
  inspect(sheets[1].ottava.role, content="SpanMiddle")
  inspect(sheets[2].ottava.role, content="SpanLast")

  // Notes are shifted down by 12 in all measures
  inspect(sheets[0].notes[0].midi, content="Some(76)")
  inspect(sheets[2].notes[0].midi, content="Some(76)")
}
