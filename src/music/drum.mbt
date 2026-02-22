///|
/// Drum voice types
pub(all) enum DrumVoice {
  Kick
  Snare
  HiHat
  Ride
} derive(Eq, Show)

///|
/// GM standard MIDI number for drum voice
pub fn DrumVoice::midi_number(self : DrumVoice) -> MidiNumber {
  let value = match self {
    Kick => 36
    Snare => 38
    HiHat => 42
    Ride => 51
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
    51 => Some(Ride)
    _ => None
  }
}

///|
/// Drum pattern style
pub(all) enum DrumPatternStyle {
  Basic // Basic jazz pattern (hi-hat every beat, kick 1&3, snare 2&4)
  SwingRide // Swing ride pattern (ride spang-a-lang, hi-hat foot 2&4)
  BossaNova // Bossa nova pattern
  Brushes // Brush pattern for ballads
} derive(Eq, Show)

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
/// Basic jazz 4/4 drum pattern
/// - HiHat: every beat
/// - Kick: beats 1, 3
/// - Snare: beats 2, 4
fn DrumPattern::jazz_4_4() -> DrumPattern {
  DrumPattern::{
    hits: [
      DrumHit::{ voice: HiHat, beat: 0.0 },
      DrumHit::{ voice: Kick, beat: 0.0 },
      DrumHit::{ voice: HiHat, beat: 1.0 },
      DrumHit::{ voice: Snare, beat: 1.0 },
      DrumHit::{ voice: HiHat, beat: 2.0 },
      DrumHit::{ voice: Kick, beat: 2.0 },
      DrumHit::{ voice: HiHat, beat: 3.0 },
      DrumHit::{ voice: Snare, beat: 3.0 },
    ],
  }
}

///|
/// Jazz waltz 3/4 drum pattern
/// - Kick: beat 1
/// - HiHat: beats 2, 3
fn DrumPattern::jazz_waltz() -> DrumPattern {
  DrumPattern::{
    hits: [
      DrumHit::{ voice: Kick, beat: 0.0 },
      DrumHit::{ voice: HiHat, beat: 1.0 },
      DrumHit::{ voice: HiHat, beat: 2.0 },
    ],
  }
}

///|
/// Swing ride 4/4 pattern (spang-a-lang)
/// - Ride: beats 1, 2, and-2, 3, 4, and-4
/// - HiHat foot: beats 2, 4
/// - Kick: beats 1, 3
/// - Snare: beats 2, 4
fn DrumPattern::swing_ride_4_4() -> DrumPattern {
  DrumPattern::{
    hits: [
      DrumHit::{ voice: Kick, beat: 0.0 },
      DrumHit::{ voice: Ride, beat: 0.0 },
      DrumHit::{ voice: Snare, beat: 1.0 },
      DrumHit::{ voice: HiHat, beat: 1.0 },
      DrumHit::{ voice: Ride, beat: 1.0 },
      DrumHit::{ voice: Ride, beat: 1.5 },
      DrumHit::{ voice: Kick, beat: 2.0 },
      DrumHit::{ voice: Ride, beat: 2.0 },
      DrumHit::{ voice: Snare, beat: 3.0 },
      DrumHit::{ voice: HiHat, beat: 3.0 },
      DrumHit::{ voice: Ride, beat: 3.0 },
      DrumHit::{ voice: Ride, beat: 3.5 },
    ],
  }
}

///|
/// Brush pattern for ballads (4/4)
/// - Snare brush: every beat
/// - Kick: beat 1
fn DrumPattern::brushes_4_4() -> DrumPattern {
  DrumPattern::{
    hits: [
      DrumHit::{ voice: Kick, beat: 0.0 },
      DrumHit::{ voice: Snare, beat: 0.0 },
      DrumHit::{ voice: Snare, beat: 1.0 },
      DrumHit::{ voice: Snare, beat: 2.0 },
      DrumHit::{ voice: Snare, beat: 3.0 },
    ],
  }
}

///|
/// Bossa nova 4/4 pattern
/// - HiHat: every eighth note
/// - Kick: beats 1, 1.5 (syncopated)
/// - Snare: beats 2, 3 (rimshot feel)
fn DrumPattern::bossa_nova_4_4() -> DrumPattern {
  DrumPattern::{
    hits: [
      DrumHit::{ voice: Kick, beat: 0.0 },
      DrumHit::{ voice: HiHat, beat: 0.0 },
      DrumHit::{ voice: HiHat, beat: 0.5 },
      DrumHit::{ voice: Kick, beat: 1.0 },
      DrumHit::{ voice: Snare, beat: 1.0 },
      DrumHit::{ voice: HiHat, beat: 1.0 },
      DrumHit::{ voice: HiHat, beat: 1.5 },
      DrumHit::{ voice: HiHat, beat: 2.0 },
      DrumHit::{ voice: Kick, beat: 2.5 },
      DrumHit::{ voice: HiHat, beat: 2.5 },
      DrumHit::{ voice: Snare, beat: 3.0 },
      DrumHit::{ voice: HiHat, beat: 3.0 },
      DrumHit::{ voice: HiHat, beat: 3.5 },
    ],
  }
}

///|
fn DrumPattern::for_time_signature(
  time_signature : TimeSignature,
  style : DrumPatternStyle,
) -> DrumPattern {
  match (time_signature.numerator, time_signature.denominator, style) {
    (3, 4, _) => DrumPattern::jazz_waltz()
    (_, _, SwingRide) => DrumPattern::swing_ride_4_4()
    (_, _, Brushes) => DrumPattern::brushes_4_4()
    (_, _, BossaNova) => DrumPattern::bossa_nova_4_4()
    _ => DrumPattern::jazz_4_4()
  }
}

///|
/// Generate drum sounds for the given number of measures
/// Returns ScheduledSound array using GM drum MIDI numbers
pub fn generate_drum_sounds(
  bpm : Int,
  measure_count : Int,
  time_signature~ : TimeSignature,
  swing? : SwingConfig = SwingConfig::straight(),
  pattern_style? : DrumPatternStyle = Basic,
) -> Array[ScheduledSound] {
  let beats_per_measure = time_signature.beats_per_measure()
  let beat_duration_ms = ms_per_beat(bpm)
  let measure_duration_ms = ms_per_measure(bpm, beats_per_measure~)
  let pattern = DrumPattern::for_time_signature(time_signature, pattern_style)
  let drum_note_duration = Duration::from_milliseconds(50.0)

  Array::makei(measure_count, fn(measure_index) {
    let measure_start_ms = measure_index.to_double() * measure_duration_ms
    pattern.hits.map(fn(hit) {
      let swing_delay = swing_offset(hit.beat, beat_duration_ms, swing)
      let start_ms = measure_start_ms +
        hit.beat * beat_duration_ms +
        swing_delay
      ScheduledSound::{
        sound_event: Note(
          midi=hit.voice.midi_number(),
          duration=NoteDuration::Eighth,
        ),
        duration: drum_note_duration,
        start_time: Duration::from_milliseconds(start_ms),
        tone_origin: None,
      }
    })
  }).flatten()
}
