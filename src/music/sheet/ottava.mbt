///|
const OTTAVA_ALTA_THRESHOLD_MIDI : Int = 84

///|
const OTTAVA_BASSA_LEDGER_LINE_THRESHOLD : Int = 4

///|
const OTTAVA_SHIFT : Int = 12

///|
/// Minimum number of pitched notes in a consecutive ottava run to display the marking
const OTTAVA_MIN_NOTE_COUNT : Int = 4

///|
/// Ottava marking state for a measure
pub(all) enum OttavaMarking {
  OttavaNone
  OttavaAlta
  OttavaBassa
} derive(Eq, Debug)

///|
pub impl Show for OttavaMarking with output(self, logger) {
  self.to_repr().output(logger)
}

///|
/// Position of a measure within its ottava span
pub(all) enum OttavaSpanRole {
  /// Single-measure span (shows label and end tick)
  SpanSole
  /// First measure of a multi-measure span (shows label, no end tick)
  SpanFirst
  /// Middle measure of a multi-measure span (no label, no end tick)
  SpanMiddle
  /// Last measure of a multi-measure span (no label, shows end tick)
  SpanLast
} derive(Eq, Debug)

///|
pub impl Show for OttavaSpanRole with output(self, logger) {
  self.to_repr().output(logger)
}

///|
/// Combined ottava kind and span position for a measure
pub(all) struct OttavaSpan {
  kind : OttavaMarking
  role : OttavaSpanRole
} derive(Eq, Debug)

///|
pub impl Show for OttavaSpan with output(self, logger) {
  self.to_repr().output(logger)
}

///|
pub let ottava_span_none : OttavaSpan = { kind: OttavaNone, role: SpanSole }

///|
/// Returns true if any pitched note in the measure has MIDI >= threshold
pub fn should_apply_8va(
  positioned : Array[(Double, @music.MeasureNote)],
) -> Bool {
  positioned
  .iter()
  .any(fn(pair) {
    match pair.1.midi {
      Some(midi) => midi >= OTTAVA_ALTA_THRESHOLD_MIDI
      None => false
    }
  })
}

///|
/// Returns true if any pitched note needs >= threshold ledger lines below the staff
fn should_apply_8vb(
  positioned : Array[(Double, @music.MeasureNote)],
  key : @music.KeySignature,
) -> Bool {
  positioned
  .iter()
  .any(fn(pair) {
    match pair.1.midi {
      Some(midi) => {
        let step = midi_to_diatonic_step(midi, key)
        ledger_steps_below(step).length() >= OTTAVA_BASSA_LEDGER_LINE_THRESHOLD
      }
      None => false
    }
  })
}

///|
/// Compute ottava spans for all measures, grouping consecutive runs and
/// suppressing spans with fewer than OTTAVA_MIN_NOTE_COUNT pitched notes
pub fn compute_ottava_spans(
  measures : Array[@music.Measure],
  key : @music.KeySignature,
) -> Array[OttavaSpan] {
  let n = measures.length()
  if n == 0 {
    return []
  }

  // Raw ottava per measure
  let raw : Array[OttavaMarking] = measures.map(fn(m) {
    let positioned = m.positioned_notes()
    if should_apply_8va(positioned) {
      OttavaAlta
    } else if should_apply_8vb(positioned, key) {
      OttavaBassa
    } else {
      OttavaNone
    }
  })

  let result : Array[OttavaSpan] = Array::make(n, ottava_span_none)
  let mut run_start = 0
  while run_start < n {
    let kind = raw[run_start]
    // Find end of consecutive run (exclusive)
    let mut run_end = run_start + 1
    while run_end < n && raw[run_end] == kind {
      run_end = run_end + 1
    }
    let run_len = run_end - run_start

    // Apply note-count threshold for non-None runs
    let effective_kind = match kind {
      OttavaNone => OttavaNone
      _ => {
        let note_count = Array::makei(run_len, fn(k) { run_start + k }).fold(
          init=0,
          fn(acc, idx) {
            let positioned = measures[idx].positioned_notes()
            acc +
            positioned
            .iter()
            .filter(fn(pair) { pair.1.midi is Some(_) })
            .fold(init=0, fn(c, _) { c + 1 })
          },
        )
        if note_count < OTTAVA_MIN_NOTE_COUNT {
          OttavaNone
        } else {
          kind
        }
      }
    }

    // Assign span roles
    match effective_kind {
      OttavaNone =>
        Array::makei(run_len, fn(k) { run_start + k }).each(fn(idx) {
          result[idx] = ottava_span_none
        })
      _ =>
        if run_len == 1 {
          result[run_start] = { kind: effective_kind, role: SpanSole }
        } else {
          result[run_start] = { kind: effective_kind, role: SpanFirst }
          Array::makei(run_len - 2, fn(k) { run_start + 1 + k }).each(fn(idx) {
            result[idx] = { kind: effective_kind, role: SpanMiddle }
          })
          result[run_end - 1] = { kind: effective_kind, role: SpanLast }
        }
    }

    run_start = run_end
  }

  result
}

///|
/// Creates a copy with all MIDI values shifted down by OTTAVA_SHIFT
pub fn shift_for_8va(
  positioned : Array[(Double, @music.MeasureNote)],
) -> Array[(Double, @music.MeasureNote)] {
  positioned.map(fn(pair) {
    let (pos, note) = pair
    let shifted_midi = note.midi.map(fn(m) { m - OTTAVA_SHIFT })
    (pos, { ..note, midi: shifted_midi })
  })
}

///|
/// Creates a copy with all MIDI values shifted up by OTTAVA_SHIFT
pub fn shift_for_8vb(
  positioned : Array[(Double, @music.MeasureNote)],
) -> Array[(Double, @music.MeasureNote)] {
  positioned.map(fn(pair) {
    let (pos, note) = pair
    let shifted_midi = note.midi.map(fn(m) { m + OTTAVA_SHIFT })
    (pos, { ..note, midi: shifted_midi })
  })
}
