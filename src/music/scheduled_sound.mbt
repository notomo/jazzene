///|
/// SoundEvent with pre-calculated duration and start time based on BPM
pub(all) struct ScheduledSound {
  sound_event : SoundEvent
  duration : Duration
  start_time : Duration
  tone_origin : ToneOrigin?
  beat_position : Double // beat within measure (0.0 = beat 1, 1.0 = beat 2, ...)
} derive(Eq, Show)

///|
/// Get MIDI value if this is a Note sound
pub fn ScheduledSound::midi(self : ScheduledSound) -> MidiNumber? {
  self.sound_event.midi()
}

///|
/// Check if this note is playing at the given position
pub fn ScheduledSound::in_range(
  self : ScheduledSound,
  position : Duration,
) -> Bool {
  self.start_time <= position && position < self.start_time + self.duration
}

///|
/// Calculate which notes are currently playing at a given playback position
pub fn calculate_playing_notes(
  sounds : Array[ScheduledSound],
  position : Duration,
) -> Array[ScheduledSound] {
  sounds
  .iter()
  .take_while(fn(sound) { sound.start_time <= position })
  .filter(fn(sound) { sound.in_range(position) })
  .collect()
}

///|
/// Convert measures array to sounds array
/// Combines tied notes into single ScheduledSound entries
/// Applies swing timing to off-beat eighth notes
pub fn convert_measures_to_sounds(
  measures : Array[Measure],
  bpm : Int,
  swing? : SwingConfig = SwingConfig::straight(),
) -> Array[ScheduledSound] {
  let beat_duration_ms = ms_per_beat(bpm)

  // Flatten all notes with their absolute start times
  let flat_notes : Array[(Double, Double, Double, MeasureNote)] = measures
    .iter()
    .flat_map(fn(measure) {
      let measure_start_ms = measure.start_time.to_milliseconds()
      measure
      .positioned_notes()
      .iter()
      .map(fn(pair) {
        let (start_beat, note) = pair
        // Swing only applies to eighth notes and longer (not sixteenth notes)
        let swing_delay = if note.duration.to_beats() >= 0.5 {
          swing_offset(start_beat, beat_duration_ms, swing)
        } else {
          0.0
        }
        let note_start_ms = measure_start_ms +
          start_beat * beat_duration_ms +
          swing_delay
        (note_start_ms, swing_delay, start_beat, note)
      })
    })
    .collect()

  // Convert to sounds, combining tied notes

  let sounds : Array[ScheduledSound] = []
  for i in 0..<flat_notes.length() {
    let (start_ms, swing_delay, start_beat, note) = flat_notes[i]

    // Skip TieEnd and TieBoth - they were already counted by TieStart
    match note.tie {
      Some(TieEnd | TieBoth) => continue
      _ => ()
    }

    // Calculate total duration (including any tied continuations)
    // - On-beat notes: extend by the next off-beat note's swing_delay to fill
    //   the swing gap (e.g., eighth → 2/3 beat instead of 1/2 beat)
    // - Off-beat notes: subtract swing_delay so the note ends at the next beat,
    //   preventing overlap

    let base_beats = note.duration.to_beats()
    let total_beats = match note.tie {
      Some(TieStart) => accumulate_tied_beats(flat_notes, i + 1, base_beats)
      _ => base_beats
    }
    let duration_adjustment = if swing_delay == 0.0 {
      find_next_swing_delay(flat_notes, i + 1)
    } else {
      -swing_delay
    }
    let duration_ms = total_beats * beat_duration_ms + duration_adjustment

    let sound_event : SoundEvent = match note.midi {
      Some(midi) =>
        match MidiNumber::new(midi) {
          Some(m) =>
            Note(midi=m, duration=NoteDuration::from_beats(total_beats))
          None => Rest(duration=NoteDuration::from_beats(total_beats))
        }
      None => Rest(duration=NoteDuration::from_beats(total_beats))
    }

    sounds.push(ScheduledSound::{
      sound_event,
      duration: Duration::from_milliseconds(duration_ms),
      start_time: Duration::from_milliseconds(start_ms),
      tone_origin: note.tone_origin,
      beat_position: start_beat,
    })
  }
  sounds
}

///|
/// Convert an array of ScheduledSounds back into Measures for sheet music rendering.
/// Notes are quantized to beats and grouped by measure.
pub fn sounds_to_measures(
  sounds : Array[ScheduledSound],
  bpm : Int,
  time_signature : TimeSignature,
  measure_count : Int,
  key : KeySignature,
) -> Array[Measure] {
  let beat_ms = ms_per_beat(bpm)
  let beats_per_meas = time_signature.beats_per_measure()
  let meas_ms = ms_per_measure(bpm, beats_per_measure=beats_per_meas)
  let num_beats = time_signature.numerator
  Array::makei(measure_count, fn(mi) {
    let meas_start = mi.to_double() * meas_ms
    let calc_accidental = create_accidental_calculator(key)
    let beats = Array::makei(num_beats, fn(bi) {
      let beat_start = meas_start + bi.to_double() * beat_ms
      let beat_end = beat_start + beat_ms
      let notes = sounds
        .iter()
        .filter(fn(s) {
          let t = s.start_time.to_milliseconds()
          t >= beat_start && t < beat_end
        })
        .filter_map(fn(s) {
          match s.midi() {
            None => None
            Some(m) => {
              let dur_beats = s.duration.to_milliseconds() / beat_ms
              let duration = NoteDuration::from_beats(dur_beats)
              let accidental = calc_accidental(m)
              Some(MeasureNote::{
                midi: Some(m.value),
                duration,
                accidental,
                tie: None,
                tone_origin: s.tone_origin,
              })
            }
          }
        })
        .collect()
      Beat::{ count: bi, notes }
    })
    Measure::{
      chords: [],
      beats,
      start_time: Duration::from_milliseconds(meas_start),
    }
  })
}

///|
/// Scale all timing values proportionally when BPM changes (original_bpm / current_bpm)
pub fn rescale_sounds(
  sounds : Array[ScheduledSound],
  original_bpm : Int,
  current_bpm : Int,
) -> Array[ScheduledSound] {
  if original_bpm == current_bpm {
    return sounds
  }
  let scale = original_bpm.to_double() / current_bpm.to_double()
  sounds.map(fn(s) {
    ScheduledSound::{
      ..s,
      start_time: Duration::from_milliseconds(
        s.start_time.to_milliseconds() * scale,
      ),
      duration: Duration::from_milliseconds(
        s.duration.to_milliseconds() * scale,
      ),
    }
  })
}

///|
/// Transpose all Note sounds by the given number of semitones
pub fn transpose_sounds(
  sounds : Array[ScheduledSound],
  semitones : Int,
) -> Array[ScheduledSound] {
  if semitones == 0 {
    return sounds
  }
  sounds.map(fn(s) {
    match s.sound_event {
      Note(midi~, duration~) =>
        match MidiNumber::new(midi.value + semitones) {
          Some(new_midi) =>
            ScheduledSound::{ ..s, sound_event: Note(midi=new_midi, duration~) }
          None => s
        }
      Rest(_) => s
    }
  })
}

///|
/// Find the swing_delay of the next sounding note (skipping TieEnd/TieBoth)
/// Returns 0.0 if no such note exists or if the next note is on-beat
fn find_next_swing_delay(
  flat_notes : Array[(Double, Double, Double, MeasureNote)],
  start_index : Int,
) -> Double {
  for j in start_index..<flat_notes.length() {
    let (_, delay, _, note) = flat_notes[j]
    match note.tie {
      Some(TieEnd | TieBoth) => continue
      _ => return delay
    }
  }
  0.0
}

///|
/// Accumulate beats from tied notes (TieEnd/TieBoth) following a TieStart
fn accumulate_tied_beats(
  flat_notes : Array[(Double, Double, Double, MeasureNote)],
  start_index : Int,
  initial_beats : Double,
) -> Double {
  let mut total = initial_beats

  for j in start_index..<flat_notes.length() {
    let (_, _, _, next_note) = flat_notes[j]
    match next_note.tie {
      Some(TieBoth) => total = total + next_note.duration.to_beats()
      Some(TieEnd) => {
        total = total + next_note.duration.to_beats()
        break
      }
      _ => break
    }
  }
  total
}
