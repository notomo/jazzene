///|
test "midi_to_diatonic_step - E4 is step 0 (bottom staff line)" {
  let key = KeySignature::c_major()
  inspect(midi_to_diatonic_step(64, key), content="0") // E4
}

///|
test "midi_to_diatonic_step - C4 is step -2 (middle C, below staff)" {
  let key = KeySignature::c_major()
  inspect(midi_to_diatonic_step(60, key), content="-2") // C4
}

///|
test "midi_to_diatonic_step - F5 is step 8 (above staff)" {
  let key = KeySignature::c_major()
  inspect(midi_to_diatonic_step(77, key), content="8") // F5
}

///|
test "midi_to_diatonic_step - B4 on Bb key" {
  let key = KeySignature::from_root(ASharp) // Bb major
  // B4 (MIDI 71) in Bb key: pitch_class=11, step=6
  let step = midi_to_diatonic_step(71, key)
  inspect(step, content="4")
}

///|
test "midi_to_staff_y - E4 at bottom staff line" {
  let key = KeySignature::c_major()
  let staff_y = 120.0
  let y = midi_to_staff_y(64, staff_y, key)
  // E4 is step 0, so y = staff_y + STAFF_LINE_SPACING * 4 + 0 = 120 + 60 = 180
  inspect(y, content="180")
}

///|
test "midi_to_staff_y - F4 one step up from E4" {
  let key = KeySignature::c_major()
  let staff_y = 120.0
  let e4_y = midi_to_staff_y(64, staff_y, key) // E4
  let f4_y = midi_to_staff_y(65, staff_y, key) // F4
  // F4 is one diatonic step above E4 → half a line spacing higher (lower y)
  inspect(e4_y - f4_y == STAFF_LINE_SPACING / 2.0, content="true")
}

///|
test "ledger_steps_below - C4 needs one ledger line" {
  let steps = ledger_steps_below(-2) // C4 = step -2
  inspect(steps, content="[-2]")
}

///|
test "ledger_steps_below - no ledger lines for notes on staff" {
  let steps = ledger_steps_below(0) // E4 = step 0 (on staff)
  inspect(steps, content="[]")
}

///|
test "ledger_steps_above - G5 needs one ledger line" {
  let steps = ledger_steps_above(10) // G5 = step 10
  inspect(steps, content="[10]")
}

///|
test "ledger_steps_above - no ledger lines for notes on staff" {
  let steps = ledger_steps_above(8) // F5 = step 8 (within threshold)
  inspect(steps, content="[]")
}

///|
test "should_apply_8va - high note triggers" {
  let positioned = [
    (
      0.0,
      MeasureNote::{
        midi: Some(85),
        duration: Quarter,
        accidental: None,
        tie: None,
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
      MeasureNote::{
        midi: Some(72),
        duration: Quarter,
        accidental: None,
        tie: None,
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
      MeasureNote::{
        midi: Some(84),
        duration: Quarter,
        accidental: None,
        tie: None,
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
      MeasureNote::{
        midi: Some(48),
        duration: Quarter,
        accidental: None,
        tie: None,
      },
    ),
  ]
  let shifted = shift_for_8vb(positioned)
  inspect(shifted[0].1.midi, content="Some(60)")
}

///|
test "key_signature_layout_width - C major has zero width" {
  let key = KeySignature::c_major()
  inspect(key_signature_layout_width(key), content="0")
}

///|
test "key_signature_layout_width - G major has width for 1 sharp" {
  let key = KeySignature::from_root(G)
  inspect(key_signature_layout_width(key), content="17")
}

///|
test "measure_position - first measure" {
  let key = KeySignature::c_major()
  let (x, y) = measure_position(0, key)
  inspect(x, content="90") // MEASURE_START_X + CLEF_SPACE_WIDTH
  inspect(y, content="120") // STAFF_TOP
}

///|
test "measure_position - second row" {
  let key = KeySignature::c_major()
  let (_, y) = measure_position(4, key)
  inspect(y, content="420") // STAFF_TOP + ROW_HEIGHT
}

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
      MeasureNote::{
        midi: Some(60),
        duration: Quarter,
        accidental: None,
        tie: None,
      },
    ),
  ]
  let measure_x = 90.0
  let beamed : Map[Int, Bool] = {}
  let positions = compute_note_positions(positioned, measure_x, beamed)
  inspect(positions.length(), content="1")
  inspect(positions[0], content="130") // measure_x + NOTE_AREA_START_OFFSET
}

///|
test "compute_note_positions - two equal notes" {
  let note = MeasureNote::{
    midi: Some(60),
    duration: Quarter,
    accidental: None,
    tie: None,
  }
  let positioned = [(0.0, note), (1.0, note)]
  let measure_x = 90.0
  let beamed : Map[Int, Bool] = {}
  let positions = compute_note_positions(positioned, measure_x, beamed)
  inspect(positions.length(), content="2")
  // First note at start, second proportionally placed
  inspect(positions[0], content="130")
}

///|
test "compute_note_positions - whole rest centered" {
  let positioned = [
    (
      0.0,
      MeasureNote::{ midi: None, duration: Whole, accidental: None, tie: None },
    ),
  ]
  let measure_x = 90.0
  let beamed : Map[Int, Bool] = {}
  let positions = compute_note_positions(positioned, measure_x, beamed)
  inspect(positions[0], content="250") // measure_x + MEASURE_WIDTH / 2.0
}

///|
test "beam_stem_up - low note goes up" {
  let positioned = [
    (
      0.0,
      MeasureNote::{
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
      MeasureNote::{
        midi: Some(80),
        duration: Eighth,
        accidental: None,
        tie: None,
      },
    ),
  ]
  inspect(beam_stem_up([0], positioned), content="false")
}

///|
test "compute_sheet_measure - basic quarter note measure" {
  let measure = Measure::{
    chords: [],
    beats: [
      Beat::{
        count: 0,
        notes: [
          MeasureNote::{
            midi: Some(60),
            duration: Quarter,
            accidental: None,
            tie: None,
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
          },
        ],
      },
    ],
    start_time: Duration::from_milliseconds(0.0),
  }
  let key = KeySignature::c_major()
  let time_sig = TimeSignature::default()
  let sheet = compute_sheet_measure(measure, 0, key, time_sig)
  inspect(sheet.notes.length(), content="2")
  inspect(sheet.beam_groups.length(), content="0")
  inspect(sheet.ottava, content="OttavaNone")
  inspect(sheet.is_first_in_row, content="true")
}

///|
test "compute_sheet_measure - eighth notes get beamed" {
  let measure = Measure::{
    chords: [],
    beats: [
      Beat::{
        count: 0,
        notes: [
          MeasureNote::{
            midi: Some(60),
            duration: Eighth,
            accidental: None,
            tie: None,
          },
          MeasureNote::{
            midi: Some(64),
            duration: Eighth,
            accidental: None,
            tie: None,
          },
        ],
      },
    ],
    start_time: Duration::from_milliseconds(0.0),
  }
  let key = KeySignature::c_major()
  let time_sig = TimeSignature::default()
  let sheet = compute_sheet_measure(measure, 0, key, time_sig)
  inspect(sheet.notes.length(), content="2")
  inspect(sheet.beam_groups.length(), content="1")
  inspect(sheet.notes[0].beamed, content="true")
  inspect(sheet.notes[1].beamed, content="true")
}

///|
test "compute_sheet_measure - high note triggers 8va" {
  let measure = Measure::{
    chords: [],
    beats: [
      Beat::{
        count: 0,
        notes: [
          MeasureNote::{
            midi: Some(88),
            duration: Quarter,
            accidental: None,
            tie: None,
          },
        ],
      },
    ],
    start_time: Duration::from_milliseconds(0.0),
  }
  let key = KeySignature::c_major()
  let time_sig = TimeSignature::default()
  let sheet = compute_sheet_measure(measure, 0, key, time_sig)
  inspect(sheet.ottava, content="OttavaAlta")
  // Note should be shifted down by 12
  inspect(sheet.notes[0].midi, content="Some(76)")
}
