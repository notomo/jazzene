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

///|
fn make_measure_with_midi(midis : Array[Int]) -> @music.Measure {
  @music.Measure::{
    chords: [],
    beats: [
      @music.Beat::{
        count: 0,
        notes: midis.map(fn(m) {
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
test "compute_ottava_spans - single measure no ottava" {
  let measures = [make_measure_with_midi([60, 62, 64, 65])]
  let key = @music.KeySignature::c_major()
  let spans = compute_ottava_spans(measures, key)
  inspect(spans.length(), content="1")
  inspect(spans[0].kind, content="OttavaNone")
  inspect(spans[0].role, content="SpanSole")
}

///|
test "compute_ottava_spans - single measure 8va below threshold" {
  // Only 1 high note — below OTTAVA_MIN_NOTE_COUNT=4, should be suppressed
  let measures = [make_measure_with_midi([85])]
  let key = @music.KeySignature::c_major()
  let spans = compute_ottava_spans(measures, key)
  inspect(spans[0].kind, content="OttavaNone")
}

///|
test "compute_ottava_spans - single measure 8va meets threshold" {
  // 4 high notes — meets OTTAVA_MIN_NOTE_COUNT=4
  let measures = [make_measure_with_midi([85, 86, 87, 88])]
  let key = @music.KeySignature::c_major()
  let spans = compute_ottava_spans(measures, key)
  inspect(spans[0].kind, content="OttavaAlta")
  inspect(spans[0].role, content="SpanSole")
}

///|
test "compute_ottava_spans - consecutive 8va measures form a single span" {
  let high_measure = make_measure_with_midi([85, 86, 87, 88])
  let measures = [high_measure, high_measure, high_measure]
  let key = @music.KeySignature::c_major()
  let spans = compute_ottava_spans(measures, key)
  inspect(spans[0].role, content="SpanFirst")
  inspect(spans[1].role, content="SpanMiddle")
  inspect(spans[2].role, content="SpanLast")
  inspect(spans[0].kind, content="OttavaAlta")
  inspect(spans[1].kind, content="OttavaAlta")
  inspect(spans[2].kind, content="OttavaAlta")
}

///|
test "compute_ottava_spans - two consecutive 8va measures form span" {
  let high_measure = make_measure_with_midi([85, 86, 87, 88])
  let measures = [high_measure, high_measure]
  let key = @music.KeySignature::c_major()
  let spans = compute_ottava_spans(measures, key)
  inspect(spans[0].role, content="SpanFirst")
  inspect(spans[1].role, content="SpanLast")
}

///|
test "compute_ottava_spans - 8va span split by normal measure" {
  let high_measure = make_measure_with_midi([85, 86, 87, 88])
  let normal_measure = make_measure_with_midi([60, 62, 64, 65])
  let measures = [high_measure, normal_measure, high_measure]
  let key = @music.KeySignature::c_major()
  let spans = compute_ottava_spans(measures, key)
  inspect(spans[0].kind, content="OttavaAlta")
  inspect(spans[0].role, content="SpanSole")
  inspect(spans[1].kind, content="OttavaNone")
  inspect(spans[2].kind, content="OttavaAlta")
  inspect(spans[2].role, content="SpanSole")
}

///|
test "compute_ottava_spans - span note count threshold across measures" {
  // Each measure has 1 high note — 2 measures = 2 notes, below threshold of 4
  let sparse_high = make_measure_with_midi([85])
  let measures = [sparse_high, sparse_high]
  let key = @music.KeySignature::c_major()
  let spans = compute_ottava_spans(measures, key)
  inspect(spans[0].kind, content="OttavaNone")
  inspect(spans[1].kind, content="OttavaNone")
}

///|
test "compute_ottava_spans - empty measures" {
  let spans = compute_ottava_spans([], @music.KeySignature::c_major())
  inspect(spans.length(), content="0")
}
