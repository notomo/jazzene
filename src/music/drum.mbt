///|
/// Drum voice types
pub(all) enum DrumVoice {
  Kick
  Snare
  HiHat
} derive(Eq, Show)

///|
/// GM standard MIDI number for drum voice
pub fn DrumVoice::midi_number(self : DrumVoice) -> MidiNumber {
  let value = match self {
    Kick => 36
    Snare => 38
    HiHat => 42
  }
  // GM drum MIDI numbers are always valid
  MidiNumber::{ value, }
}

///|
/// Check if a MIDI number corresponds to a drum voice
pub fn DrumVoice::from_midi(midi : MidiNumber) -> DrumVoice? {
  match midi.value {
    36 => Some(Kick)
    38 => Some(Snare)
    42 => Some(HiHat)
    _ => None
  }
}

///|
/// A single drum hit within a pattern
priv struct DrumHit {
  voice : DrumVoice
  /// Beat position within the measure (0-based)
  beat : Double
}

///|
/// A drum pattern for one measure
priv struct DrumPattern {
  hits : Array[DrumHit]
}

///|
/// Basic jazz drum pattern for one measure
/// - Ride cymbal (HiHat): every beat (quarter notes)
/// - Hi-hat foot (Snare): beats 2 and 4
/// - Kick: beats 1 and 3 (soft)
fn DrumPattern::jazz_basic(beats_per_measure : Double) -> DrumPattern {
  let hits : Array[DrumHit] = []
  let beat_count = beats_per_measure.to_int()
  for i = 0; i < beat_count; i = i + 1 {
    let beat = i.to_double()
    // Ride on every beat
    hits.push(DrumHit::{ voice: HiHat, beat })
    // Kick on odd beats (1, 3)
    if i % 2 == 0 {
      hits.push(DrumHit::{ voice: Kick, beat })
    }
    // Snare on even beats (2, 4)
    if i % 2 == 1 {
      hits.push(DrumHit::{ voice: Snare, beat })
    }
  }
  DrumPattern::{ hits, }
}

///|
/// Generate drum sounds for the given number of measures
/// Returns NoteValueSound array using GM drum MIDI numbers
pub fn generate_drum_sounds(
  bpm : Int,
  measure_count : Int,
  beats_per_measure~ : Double,
  swing? : SwingConfig = SwingConfig::straight(),
) -> Array[NoteValueSound] {
  let beat_duration_ms = ms_per_beat(bpm)
  let measure_duration_ms = ms_per_measure(bpm, beats_per_measure~)
  let pattern = DrumPattern::jazz_basic(beats_per_measure)
  let drum_note_duration = Duration::from_milliseconds(50.0)
  Array::makei(measure_count, fn(measure_index) {
    let measure_start_ms = measure_index.to_double() * measure_duration_ms
    pattern.hits.map(fn(hit) {
      let swing_delay = swing_offset(hit.beat, beat_duration_ms, swing)
      let start_ms = measure_start_ms +
        hit.beat * beat_duration_ms +
        swing_delay
      NoteValueSound::{
        note_value: Note(
          midi=hit.voice.midi_number(),
          duration=NoteDuration::Eighth,
        ),
        duration: drum_note_duration,
        start_time: Duration::from_milliseconds(start_ms),
      }
    })
  }).flatten()
}
