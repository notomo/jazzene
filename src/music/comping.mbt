///|
/// Comping (rhythmic chord accompaniment) logic for jazz backing tracks.
///
/// Comping is the jazz practice of rhythmically accompanying a soloist
/// with chords on piano/guitar. This module provides rhythm patterns
/// and sound generation for realistic jazz comping.

///|
/// Deterministic pseudo-random value in (0.0, 1.0] from an integer key.
/// Uses splitmix32-style mixing for good distribution even on small inputs.
pub fn pseudo_rand(x : Int) -> Double {
  // Add golden-ratio constant to shift x away from 0 before mixing
  let h = (x + -1640531527).reinterpret_as_uint() // 0x9E3779B9
  let h = (h ^ (h >> 16)) * 0xC2B2AE35
  let h = (h ^ (h >> 13)) * 0x85EBCA6B
  let h = h ^ (h >> 16)
  ((h & 0x7FFF) + 1).reinterpret_as_int().to_double() / 32768.0
}

///|
/// Rhythm pattern for jazz comping, cycled per measure.
/// Each pattern defines where the chord hits land within a measure.
pub(all) enum CompingPattern {
  Sparse // Beat 1 only
  Standard // Beat 1, and-of-2, beat 4 (jazz standard comping)
  TwoFour // Beats 2 and 4 only (Freddie Green style)
  Dense // Beat 1, and-of-2, beat 3, and-of-4 (active comping)
} derive(Eq, Show)

///|
pub fn CompingPattern::from_measure_index(idx : Int) -> CompingPattern {
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
pub fn comping_rhythm(
  pattern : CompingPattern,
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
    // In 3/4: beat 1 + and-of-2 + beat 3 (waltz feel)
    Standard => {
      let pairs = [(actual_start_ms, 0.75)]
      // Add "and of 2" only when it won't collide with the next chord's
      // anticipated hit (which lands at beats_per_chord - 0.5 beats in).
      if beats_per_chord >= 2.0 && (is_last_chord || beats_per_chord > 2.0) {
        pairs.push((chord_start_ms + beat_duration_ms * 1.5, 0.25))
      }
      if beats_per_chord >= 4.0 {
        pairs.push((chord_start_ms + beat_duration_ms * 3.0, 0.5))
      } else if beats_per_chord >= 3.0 {
        // 3/4: add beat 3 for waltz feel
        pairs.push((chord_start_ms + beat_duration_ms * 2.0, 0.5))
      }
      pairs
    }
    // TwoFour: beat 2 sustains (Freddie Green feel), beat 4 medium
    // In 3/4: beats 2 and 3 (waltz "chick-chick"), shorter beat-2 duration to avoid
    // overlapping with beat-3 (which starts only 1 beat later vs 2 beats in 4/4)
    TwoFour => {
      let pairs : Array[(Double, Double)] = []
      if beats_per_chord >= 2.0 {
        // In 4/4 beat-4 is 2 beats away so 1.5 is safe; in 3/4 beat-3 is only
        // 1 beat away, so cap at 0.75 to prevent overlap even with max jitter.
        let beat2_dur = if beats_per_chord >= 4.0 { 1.5 } else { 0.75 }
        pairs.push((chord_start_ms + beat_duration_ms * 1.0, beat2_dur))
      }
      if beats_per_chord >= 4.0 {
        pairs.push((chord_start_ms + beat_duration_ms * 3.0, 0.75))
      } else if beats_per_chord >= 3.0 {
        // 3/4: add beat 3 instead of beat 4
        pairs.push((chord_start_ms + beat_duration_ms * 2.0, 0.75))
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
/// Generate comping sounds (guide tones: 3rd and 7th/5th) for a chord progression.
/// Chords are evenly distributed across each measure's beats.
/// Each guide tone is placed below the lowest melody note in the same chord window.
/// Rhythm pattern cycles every 4 measures: Standard → Dense → TwoFour → Sparse.
/// seed controls duration jitter (±20%) and occasional hit omission (~25%).
pub fn generate_comping_sounds(
  measures : Array[Measure],
  bpm : Int,
  melody_sounds : Array[NoteValueSound],
  seed? : Int = 0,
) -> Array[NoteValueSound] {
  let beat_duration_ms = ms_per_beat(bpm)
  let sounds : Array[NoteValueSound] = []
  for mi = 0; mi < measures.length(); mi = mi + 1 {
    let measure = measures[mi]
    let pattern = CompingPattern::from_measure_index(mi)
    let n = measure.chords.length()
    if n > 0 {
      let beats_per_chord = measure.beats.length().to_double() / n.to_double()
      let chord_duration_ms = beats_per_chord * beat_duration_ms
      let measure_start_ms = measure.start_time.to_milliseconds()
      for i = 0; i < n; i = i + 1 {
        let chord = measure.chords[i]
        let chord_start_ms = measure_start_ms +
          i.to_double() * chord_duration_ms
        // Jazz syncopation: anticipate chord changes (except beat 1) by one 8th note
        let actual_start_ms = if i == 0 {
          chord_start_ms
        } else {
          chord_start_ms - beat_duration_ms * 0.5
        }
        let intervals = chord.quality.intervals()
        let base_midi = chord.root.midi() - 12
        let voice_leading_intervals = if intervals.length() >= 4 {
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

        let is_last_chord = i == n - 1
        let hits = comping_rhythm(
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
          // Per-hit: find the lowest melody note that overlaps this hit's exact time range.
          // This catches crossing regardless of when within the chord the hit falls.
          let hit_end_ms = hit_start_ms + jittered_duration_ms
          let mut min_melody_midi : Int? = None
          for s in melody_sounds {
            let s_start = s.start_time.to_milliseconds()
            let s_end = s_start + s.duration.to_milliseconds()
            if hit_start_ms < s_end && hit_end_ms > s_start {
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
          for interval in voice_leading_intervals {
            let raw_midi = base_midi + interval
            // Lower the note by octaves until at least a perfect fourth (5 semitones)
            // below the lowest melody note, preventing near-crossing that makes
            // simultaneous play uncomfortable.
            let mut midi_val = raw_midi
            match min_melody_midi {
              Some(min_mel) =>
                while midi_val > min_mel - 5 {
                  midi_val = midi_val - 12
                }
              None => ()
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
