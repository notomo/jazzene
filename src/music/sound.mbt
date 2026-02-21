///|
/// NoteValue with pre-calculated duration and start time based on BPM
pub struct NoteValueSound {
  note_value : NoteValue
  duration : Duration
  start_time : Duration
} derive(Eq, Show)

///|
/// Get MIDI value if this is a Note sound
pub fn NoteValueSound::midi(self : NoteValueSound) -> MidiNumber? {
  self.note_value.midi()
}

///|
/// Check if this note is playing at the given position
pub fn NoteValueSound::in_range(
  self : NoteValueSound,
  position : Duration,
) -> Bool {
  self.start_time <= position && position < self.start_time + self.duration
}

///|
/// Calculate which notes are currently playing at a given playback position
pub fn calculate_playing_notes(
  sounds : Array[NoteValueSound],
  position : Duration,
) -> Array[NoteValueSound] {
  sounds
  .iter()
  .take_while(fn(sound) { sound.start_time <= position })
  .filter(fn(sound) { sound.in_range(position) })
  .collect()
}

///|
/// Convert measures array to sounds array
/// Combines tied notes into single NoteValueSound entries
/// Applies swing timing to off-beat eighth notes
pub fn convert_measures_to_sounds(
  measures : Array[Measure],
  bpm : Int,
  swing? : SwingConfig = SwingConfig::straight(),
) -> Array[NoteValueSound] {
  let beat_duration_ms = ms_per_beat(bpm)

  // Flatten all notes with their absolute start times
  let flat_notes : Array[(Double, MeasureNote)] = measures
    .iter()
    .flat_map(fn(measure) {
      let measure_start_ms = measure.start_time.to_milliseconds()
      measure
      .positioned_notes()
      .iter()
      .map(fn(pair) {
        let (start_beat, note) = pair
        let swing_delay = swing_offset(start_beat, beat_duration_ms, swing)
        let note_start_ms = measure_start_ms +
          start_beat * beat_duration_ms +
          swing_delay
        (note_start_ms, note)
      })
    })
    .collect()

  // Convert to sounds, combining tied notes

  let sounds : Array[NoteValueSound] = []
  for i = 0; i < flat_notes.length(); i = i + 1 {
    let (start_ms, note) = flat_notes[i]

    // Skip TieEnd and TieBoth - they were already counted by TieStart
    match note.tie {
      Some(TieEnd | TieBoth) => continue
      _ => ()
    }

    // Calculate total duration (including any tied continuations)

    let base_beats = note.duration.to_beats()
    let total_beats = match note.tie {
      Some(TieStart) => accumulate_tied_beats(flat_notes, i + 1, base_beats)
      _ => base_beats
    }
    let duration_ms = total_beats * beat_duration_ms

    let note_value : NoteValue = match note.midi {
      Some(midi) =>
        match MidiNumber::new(midi) {
          Some(m) =>
            Note(midi=m, duration=NoteDuration::from_beats(total_beats))
          None => Rest(duration=NoteDuration::from_beats(total_beats))
        }
      None => Rest(duration=NoteDuration::from_beats(total_beats))
    }

    sounds.push(NoteValueSound::{
      note_value,
      duration: Duration::from_milliseconds(duration_ms),
      start_time: Duration::from_milliseconds(start_ms),
    })
  }
  sounds
}

///|
/// Deterministic pseudo-random value in (0.0, 1.0] from an integer key.
/// Uses splitmix32-style mixing for good distribution even on small inputs.
fn pseudo_rand(x : Int) -> Double {
  // Add golden-ratio constant to shift x away from 0 before mixing
  let h = (x + -1640531527).reinterpret_as_uint() // 0x9E3779B9
  let h = (h ^ (h >> 16)) * 0xC2B2AE35
  let h = (h ^ (h >> 13)) * 0x85EBCA6B
  let h = h ^ (h >> 16)
  ((h & 0x7FFF) + 1).reinterpret_as_int().to_double() / 32768.0
}

///|
/// Rhythm pattern for backing comping, cycled per measure
priv enum BackingPattern {
  Sparse // Beat 1 only
  Standard // Beat 1, and-of-2, beat 4 (jazz standard comping)
  TwoFour // Beats 2 and 4 only (Freddie Green style)
  Dense // Beat 1, and-of-2, beat 3, and-of-4 (active comping)
}

///|
fn BackingPattern::from_measure_index(idx : Int) -> BackingPattern {
  match idx % 4 {
    0 => Standard
    1 => Dense
    2 => TwoFour
    _ => Sparse
  }
}

///|
/// Calculate (start_time_ms, duration_beats) pairs for each hit within a chord slot.
/// actual_start_ms may be earlier than chord_start_ms for anticipated (non-first) chords.
/// Duration varies per hit position: downbeats sustain longer, off-beats are short stabs.
fn hit_times_for_pattern(
  pattern : BackingPattern,
  chord_start_ms : Double,
  actual_start_ms : Double,
  beats_per_chord : Double,
  beat_duration_ms : Double,
  is_last_chord : Bool,
) -> Array[(Double, Double)] {
  match pattern {
    // Sparse: single sustained hit on beat 1
    Sparse => [(actual_start_ms, 1.5)]
    // Standard: downbeat sustains, off-beat and-of-2 is a short stab, beat 4 medium
    Standard => {
      let pairs = [(actual_start_ms, 0.75)]
      // Add "and of 2" only when it won't collide with the next chord's
      // anticipated hit (which lands at beats_per_chord - 0.5 beats in).
      if beats_per_chord >= 2.0 && (is_last_chord || beats_per_chord > 2.0) {
        pairs.push((chord_start_ms + beat_duration_ms * 1.5, 0.25))
      }
      if beats_per_chord >= 4.0 {
        pairs.push((chord_start_ms + beat_duration_ms * 3.0, 0.5))
      }
      pairs
    }
    // TwoFour: beat 2 sustains (Freddie Green feel), beat 4 medium
    TwoFour => {
      let pairs : Array[(Double, Double)] = []
      if beats_per_chord >= 2.0 {
        pairs.push((chord_start_ms + beat_duration_ms * 1.0, 1.5))
      }
      if beats_per_chord >= 4.0 {
        pairs.push((chord_start_ms + beat_duration_ms * 3.0, 0.75))
      }
      pairs
    }
    // Dense: alternating medium hits and short stabs
    Dense => {
      let pairs = [(actual_start_ms, 0.5)]
      if beats_per_chord >= 2.0 && (is_last_chord || beats_per_chord > 2.0) {
        pairs.push((chord_start_ms + beat_duration_ms * 1.5, 0.25))
      }
      if beats_per_chord >= 3.0 {
        pairs.push((chord_start_ms + beat_duration_ms * 2.0, 0.5))
      }
      if beats_per_chord >= 4.0 {
        pairs.push((chord_start_ms + beat_duration_ms * 3.5, 0.25))
      }
      pairs
    }
  }
}

///|
/// Convert measures array to backing sounds (guide tones: 3rd and 7th/5th)
/// Chords are evenly distributed across each measure's beats.
/// Each guide tone is placed below the lowest melody note in the same chord window.
/// Rhythm pattern cycles every 4 measures: Standard → Dense → TwoFour → Sparse.
/// seed controls duration jitter (±20%) and occasional hit omission (~25%).
pub fn convert_measures_to_backing_sounds(
  measures : Array[Measure],
  bpm : Int,
  melody_sounds : Array[NoteValueSound],
  seed? : Int = 0,
) -> Array[NoteValueSound] {
  let beat_duration_ms = ms_per_beat(bpm)
  let sounds : Array[NoteValueSound] = []
  for mi = 0; mi < measures.length(); mi = mi + 1 {
    let measure = measures[mi]
    let pattern = BackingPattern::from_measure_index(mi)
    let n = measure.chords.length()
    if n > 0 {
      let beats_per_chord = measure.beats.length().to_double() / n.to_double()
      let chord_duration_ms = beats_per_chord * beat_duration_ms
      let measure_start_ms = measure.start_time.to_milliseconds()
      for i = 0; i < n; i = i + 1 {
        let chord = measure.chords[i]
        let chord_start_ms = measure_start_ms +
          i.to_double() * chord_duration_ms
        let chord_end_ms = chord_start_ms + chord_duration_ms
        // Jazz syncopation: anticipate chord changes (except beat 1) by one 8th note
        let actual_start_ms = if i == 0 {
          chord_start_ms
        } else {
          chord_start_ms - beat_duration_ms * 0.5
        }
        let intervals = chord.quality.intervals()
        let base_midi = chord.root.midi() - 12
        let guide_intervals = if intervals.length() >= 4 {
          // F, G, A roots use 7-3 voicing (7th below, 3rd above)
          // for smooth voice leading in II-V-I progressions
          let use_73_voicing = match chord.root {
            F | G | A => true
            _ => false
          }
          if use_73_voicing {
            [intervals[3] - 12, intervals[1]]
          } else {
            [intervals[1], intervals[3]]
          }
        } else {
          [intervals[1], intervals[2]]
        }

        // Find the lowest melody note overlapping this chord's time range
        let mut min_melody_midi : Int? = None
        for s in melody_sounds {
          let s_start = s.start_time.to_milliseconds()
          let s_end = s_start + s.duration.to_milliseconds()
          if chord_start_ms < s_end && chord_end_ms > s_start {
            match s.midi() {
              Some(m) =>
                match min_melody_midi {
                  None => min_melody_midi = Some(m.value)
                  Some(cur) =>
                    if m.value < cur {
                      min_melody_midi = Some(m.value)
                    }
                }
              None => ()
            }
          }
        }

        let is_last_chord = i == n - 1
        let hits = hit_times_for_pattern(
          pattern, chord_start_ms, actual_start_ms, beats_per_chord, beat_duration_ms,
          is_last_chord,
        )
        for hi = 0; hi < hits.length(); hi = hi + 1 {
          let (hit_start_ms, duration_beats) = hits[hi]
          // Omit non-first hits with ~25% probability for jazz comping sparseness
          let rand_key = seed * 49999 + mi * 1009 + i * 97 + hi
          if hi > 0 && pseudo_rand(rand_key) < 0.25 {
            continue
          }
          // Duration jitter: ±20% for human feel, with 0.5-beat minimum to avoid abrupt cutoffs
          let jitter = 0.8 + pseudo_rand(rand_key + 7) * 0.4
          let raw_duration_ms = beat_duration_ms * duration_beats * jitter
          let min_duration_ms = beat_duration_ms * 0.5
          let jittered_duration_ms = if raw_duration_ms < min_duration_ms {
            min_duration_ms
          } else {
            raw_duration_ms
          }
          for interval in guide_intervals {
            let raw_midi = base_midi + interval
            // Lower the note by octaves until it is below the melody's lowest note
            let midi_val = match min_melody_midi {
              Some(min_mel) => {
                let v = if raw_midi >= min_mel {
                  raw_midi - 12
                } else {
                  raw_midi
                }
                if v >= min_mel {
                  v - 12
                } else {
                  v
                }
              }
              None => raw_midi
            }
            match MidiNumber::new(midi_val) {
              Some(m) =>
                sounds.push(NoteValueSound::{
                  note_value: Note(
                    midi=m,
                    duration=NoteDuration::from_beats(beats_per_chord),
                  ),
                  duration: Duration::from_milliseconds(jittered_duration_ms),
                  start_time: Duration::from_milliseconds(hit_start_ms),
                })
              None => ()
            }
          }
        }
      }
    }
  }
  sounds
}

///|
/// Accumulate beats from tied notes (TieEnd/TieBoth) following a TieStart
fn accumulate_tied_beats(
  flat_notes : Array[(Double, MeasureNote)],
  start_index : Int,
  initial_beats : Double,
) -> Double {
  let mut total = initial_beats

  for j = start_index; j < flat_notes.length(); j = j + 1 {
    let (_, next_note) = flat_notes[j]
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
