///|
/// Walking bass line generation for jazz accompaniment.
///
/// Walking bass is a jazz bass technique where the bassist plays one note
/// per beat, creating a smooth, "walking" line through the chord changes.
/// Strong beats (1, 3) favor chord tones; weak beats (2, 4) use passing
/// tones, scale tones, or chromatic approaches to the next chord root.

///|
/// Bass style selection for the accompaniment.
pub(all) enum BassStyle {
  RootOnly // Root note on beat 1 only; rests on other beats
  RootFifth // Root on beat 1, 5th on beat 3; rests on beats 2 and 4
  WalkingBass // Full walking bass: chord tones + approach tones, one note per beat
} derive(Eq, Show)

///|
/// Comfortable MIDI range for bass (E1 to E3)
let bass_min : Int = 28 // E1

///|
let bass_max : Int = 52 // E3

///|
let bass_default_ref : Int = 40 // E2 — typical bass starting reference

///|
/// Find the MIDI number with the given pitch class closest to a reference MIDI,
/// clamped to the comfortable bass range (bass_min..bass_max).
fn bass_note_in_range(pitch_class : Int, reference : Int) -> Int {
  let base = reference / 12 * 12 + pitch_class
  let candidates = [base - 12, base, base + 12]
  let best = candidates.fold(init=base, fn(best, c) {
    if (c - reference).abs() < (best - reference).abs() {
      c
    } else {
      best
    }
  })
  let mut m = best
  while m < bass_min {
    m = m + 12
  }
  while m > bass_max {
    m = m - 12
  }
  m
}

///|
/// Get the 5th interval index for a chord quality (or 3rd if no 5th).
fn fifth_or_third_interval(intervals : Array[Int]) -> Int {
  if intervals.length() >= 3 {
    intervals[2]
  } else {
    intervals[1]
  }
}

///|
/// Generate walking bass sounds for a chord progression.
///
/// For WalkingBass: places one quarter note per beat.
/// - Even beats within a chord (0, 2, ...): chord root
/// - Odd beats within a chord (1, 3, ...): chord 5th (or 3rd if no 5th)
/// - Last beat of measure: chromatic approach (half-step below) to next root
///
/// For RootFifth: root on first beat of each chord slot, 5th on second half.
///
/// For RootOnly: single note on beat 1 of each chord slot.
///
/// Bass notes stay in the comfortable bass range (E1 to E3, MIDI 28-52).
pub fn generate_walking_bass_sounds(
  measures : Array[Measure],
  bpm : Int,
  style : BassStyle,
) -> Array[NoteValueSound] {
  let beat_duration_ms = ms_per_beat(bpm)
  let sounds : Array[NoteValueSound] = []
  let mut prev_bass_midi = bass_default_ref
  for mi = 0; mi < measures.length(); mi = mi + 1 {
    let measure = measures[mi]
    let beats_in_measure = measure.beats.length()
    let n_chords = measure.chords.length()
    if n_chords == 0 || beats_in_measure == 0 {
      continue
    }
    let measure_start_ms = measure.start_time.to_milliseconds()
    let beats_per_chord = beats_in_measure.to_double() / n_chords.to_double()
    // Find next measure's first chord root for chromatic approach
    let next_root_pc : Int? = if mi + 1 < measures.length() &&
      not(measures[mi + 1].chords.is_empty()) {
      Some(measures[mi + 1].chords[0].root.midi() % 12)
    } else {
      None
    }
    match style {
      RootOnly =>
        // One note per chord slot: root on beat 1 only
        for ci = 0; ci < n_chords; ci = ci + 1 {
          let chord = measure.chords[ci]
          let chord_beat = (ci.to_double() * beats_per_chord).to_int()
          let start_ms = measure_start_ms +
            chord_beat.to_double() * beat_duration_ms
          let root_pc = chord.root.midi() % 12
          let midi_val = bass_note_in_range(root_pc, prev_bass_midi)
          prev_bass_midi = midi_val
          match MidiNumber::new(midi_val) {
            Some(m) =>
              sounds.push(NoteValueSound::{
                note_value: Note(
                  midi=m,
                  duration=NoteDuration::from_beats(beats_per_chord),
                ),
                duration: Duration::from_milliseconds(
                  beat_duration_ms * beats_per_chord * 0.9,
                ),
                start_time: Duration::from_milliseconds(start_ms),
              })
            None => ()
          }
        }
      RootFifth =>
        // Root on first beat of chord, 5th on halfway through chord slot
        for ci = 0; ci < n_chords; ci = ci + 1 {
          let chord = measure.chords[ci]
          let intervals = chord.quality.intervals()
          let chord_beat = (ci.to_double() * beats_per_chord).to_int()
          let root_pc = chord.root.midi() % 12
          let fifth_pc = (
              chord.root.midi() + fifth_or_third_interval(intervals)
            ) %
            12
          // Root on first beat of chord slot
          let root_ms = measure_start_ms +
            chord_beat.to_double() * beat_duration_ms
          let root_midi = bass_note_in_range(root_pc, prev_bass_midi)
          prev_bass_midi = root_midi
          match MidiNumber::new(root_midi) {
            Some(m) =>
              sounds.push(NoteValueSound::{
                note_value: Note(
                  midi=m,
                  duration=NoteDuration::from_beats(beats_per_chord / 2.0),
                ),
                duration: Duration::from_milliseconds(
                  beat_duration_ms * (beats_per_chord / 2.0) * 0.9,
                ),
                start_time: Duration::from_milliseconds(root_ms),
              })
            None => ()
          }
          // 5th on second half of chord slot (only when chord lasts >= 2 beats)
          if beats_per_chord >= 2.0 {
            let fifth_beat = chord_beat + (beats_per_chord / 2.0).to_int()
            let fifth_ms = measure_start_ms +
              fifth_beat.to_double() * beat_duration_ms
            let fifth_midi = bass_note_in_range(fifth_pc, prev_bass_midi)
            prev_bass_midi = fifth_midi
            match MidiNumber::new(fifth_midi) {
              Some(m) =>
                sounds.push(NoteValueSound::{
                  note_value: Note(
                    midi=m,
                    duration=NoteDuration::from_beats(beats_per_chord / 2.0),
                  ),
                  duration: Duration::from_milliseconds(
                    beat_duration_ms * (beats_per_chord / 2.0) * 0.9,
                  ),
                  start_time: Duration::from_milliseconds(fifth_ms),
                })
              None => ()
            }
          }
        }
      WalkingBass =>
        // One note per beat: chord tones on even beats, 5th on odd, approach on last
        for beat_idx = 0; beat_idx < beats_in_measure; beat_idx = beat_idx + 1 {
          let beat_start_ms = measure_start_ms +
            beat_idx.to_double() * beat_duration_ms
          let is_last_beat = beat_idx == beats_in_measure - 1
          // Which chord is active at this beat?
          let chord_idx = @cmp.minimum(
            (beat_idx.to_double() / beats_per_chord).to_int(),
            n_chords - 1,
          )
          let chord = measure.chords[chord_idx]
          let intervals = chord.quality.intervals()
          let root_pc = chord.root.midi() % 12
          // Beat position within this chord slot
          let chord_start_beat = (chord_idx.to_double() * beats_per_chord).to_int()
          let beat_in_chord = beat_idx - chord_start_beat
          // Select pitch class for this beat
          let bass_pc = if is_last_beat {
            // Approach to next root by half-step below (leading tone)
            match next_root_pc {
              Some(target_pc) => (target_pc - 1 + 12) % 12
              None => root_pc
            }
          } else if beat_in_chord % 2 == 0 {
            // Even beat within chord slot: chord root
            root_pc
          } else {
            // Odd beat within chord slot: chord 5th (or 3rd if no 5th)
            let fifth_interval = fifth_or_third_interval(intervals)
            (chord.root.midi() + fifth_interval) % 12
          }
          let bass_midi = bass_note_in_range(bass_pc, prev_bass_midi)
          prev_bass_midi = bass_midi
          match MidiNumber::new(bass_midi) {
            Some(m) =>
              sounds.push(NoteValueSound::{
                note_value: Note(midi=m, duration=Quarter),
                duration: Duration::from_milliseconds(beat_duration_ms * 0.85),
                start_time: Duration::from_milliseconds(beat_start_ms),
              })
            None => ()
          }
        }
    }
  }
  sounds
}
