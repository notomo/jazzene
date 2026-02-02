///|
/// Context passed to MeasureGenerator
pub struct MeasureContext {
  chord : @music.Chord
  incoming_tie : TieContext? // Tie from previous measure
  key : @music.KeySignature
  beats_per_measure : Double
}

///|
/// Tie information for cross-measure notes
pub struct TieContext {
  midi : @music.MidiNumber
  remaining_beats : Double
}

///|
/// Result from MeasureGenerator
pub struct MeasureResult {
  beats : Array[@music.Beat]
  outgoing_tie : TieContext? // Tie to next measure
}

///|
/// Generator function that produces notes for one measure
pub type MeasureGenerator = (MeasureContext) -> MeasureResult

///|
/// Settings for the measure generator
pub(all) struct Settings {
  seed : Int
  rest_probability : Int // 0-100
  note_duration_weights : DurationWeights
  rest_duration_weights : DurationWeights
} derive(Eq, Show)

///|
/// Create default settings with given seed
pub fn Settings::default(seed : Int) -> Settings {
  Settings::{
    seed,
    rest_probability: 25,
    note_duration_weights: DurationWeights::note_default(),
    rest_duration_weights: DurationWeights::rest_default(),
  }
}

///|
/// Create a measure generator from settings
/// Returns a function that generates notes for one measure
pub fn create_measure_generator(settings : Settings) -> MeasureGenerator {
  let random_int = create_random_int(settings.seed)
  fn(ctx : MeasureContext) -> MeasureResult {
    generate_measure_notes(
      ctx.chord,
      ctx.incoming_tie,
      ctx.key,
      ctx.beats_per_measure,
      settings.rest_probability,
      settings.note_duration_weights,
      settings.rest_duration_weights,
      random_int,
    )
  }
}

///|
/// Tie carry state between beats within a measure
priv struct BeatTieCarry {
  midi : @music.MidiNumber
  remaining_beats : Double
}

///|
/// Generate notes for one measure, beat by beat
fn generate_measure_notes(
  chord : @music.Chord,
  incoming_tie : TieContext?,
  key : @music.KeySignature,
  beats_per_measure : Double,
  rest_probability : Int,
  note_duration_weights : DurationWeights,
  rest_duration_weights : DurationWeights,
  random_int : (Int) -> Int,
) -> MeasureResult {
  let update_accidental = @music.create_accidental_calculator(key)
  let num_beats = beats_per_measure.to_int()
  let beats : Array[@music.Beat] = []

  // Convert incoming cross-measure tie to beat carry
  let initial_carry : BeatTieCarry? = match incoming_tie {
    Some(tie_ctx) =>
      Some(BeatTieCarry::{
        midi: tie_ctx.midi,
        remaining_beats: tie_ctx.remaining_beats,
      })
    None => None
  }
  let mut carry : BeatTieCarry? = initial_carry
  for beat_index = 0; beat_index < num_beats; beat_index = beat_index + 1 {
    let notes : Array[@music.MeasureNote] = []
    let mut current_pos = 0.0
    let beat_capacity = 1.0

    // Handle incoming carry (from cross-measure tie or previous beat's within-measure tie)
    match carry {
      Some(c) => {
        let remaining_in_measure = beats_per_measure - beat_index.to_double()
        if c.remaining_beats > remaining_in_measure {
          // Tie extends beyond this entire measure
          let fitted = @music.NoteDuration::fit(beat_capacity).unwrap_or(
            @music.Eighth,
          )
          let tie = if beat_index == 0 {
            match incoming_tie {
              Some(_) => Some(@music.TieBoth)
              None => Some(@music.TieStart) // shouldn't happen but be safe
            }
          } else {
            Some(@music.TieBoth)
          }
          notes.push(@music.MeasureNote::{
            midi: Some(c.midi.value),
            duration: fitted,
            accidental: None,
            tie,
          })
          beats.push(@music.Beat::{ count: beat_index, notes })
          carry = Some(BeatTieCarry::{
            midi: c.midi,
            remaining_beats: c.remaining_beats - beat_capacity,
          })
          continue
        }
        if c.remaining_beats > beat_capacity {
          // Carry spans beyond this beat but not beyond the measure
          let fitted = @music.NoteDuration::fit(beat_capacity).unwrap_or(
            @music.Eighth,
          )
          let tie = if beat_index == 0 {
            match incoming_tie {
              Some(_) => Some(@music.TieBoth)
              None => Some(@music.TieStart)
            }
          } else {
            Some(@music.TieBoth)
          }
          notes.push(@music.MeasureNote::{
            midi: Some(c.midi.value),
            duration: fitted,
            accidental: None,
            tie,
          })
          beats.push(@music.Beat::{ count: beat_index, notes })
          carry = Some(BeatTieCarry::{
            midi: c.midi,
            remaining_beats: c.remaining_beats - beat_capacity,
          })
          continue
        }
        // Carry fits within this beat
        let fitted = @music.NoteDuration::fit(c.remaining_beats).unwrap_or(
          @music.Eighth,
        )
        let tie = if beat_index == 0 {
          match incoming_tie {
            Some(_) => Some(@music.TieEnd)
            None => Some(@music.TieEnd)
          }
        } else {
          Some(@music.TieEnd)
        }
        notes.push(@music.MeasureNote::{
          midi: Some(c.midi.value),
          duration: fitted,
          accidental: None,
          tie,
        })
        current_pos = current_pos + fitted.to_beats()
        carry = None
      }
      None => ()
    }

    // Fill remaining capacity in this beat
    while current_pos < beat_capacity {
      let remaining_in_beat = beat_capacity - current_pos
      match decide_midi_number(chord, rest_probability, random_int) {
        Some(midi) => {
          let duration = random_duration(note_duration_weights, random_int)
          let beats_needed = duration.to_beats()
          if beats_needed <= remaining_in_beat {
            // Note fits within this beat
            notes.push(@music.MeasureNote::{
              midi: Some(midi.value),
              duration,
              accidental: update_accidental(midi),
              tie: None,
            })
            current_pos = current_pos + beats_needed
          } else {
            // Note exceeds beat boundary
            let remaining_in_measure = beats_per_measure -
              beat_index.to_double() -
              current_pos
            if beats_needed > remaining_in_measure {
              // Note extends beyond the measure - cross-measure tie
              let fitted = @music.NoteDuration::fit(remaining_in_beat).unwrap_or(
                @music.Eighth,
              )
              notes.push(@music.MeasureNote::{
                midi: Some(midi.value),
                duration: fitted,
                accidental: update_accidental(midi),
                tie: Some(@music.TieStart),
              })
              // Fill remaining beats in this measure with tied notes
              let mut cross_remaining = beats_needed - remaining_in_beat
              for b = beat_index + 1; b < num_beats; b = b + 1 {
                let beat_notes : Array[@music.MeasureNote] = []
                if cross_remaining > beat_capacity {
                  let bf = @music.NoteDuration::fit(beat_capacity).unwrap_or(
                    @music.Eighth,
                  )
                  beat_notes.push(@music.MeasureNote::{
                    midi: Some(midi.value),
                    duration: bf,
                    accidental: None,
                    tie: Some(@music.TieBoth),
                  })
                  cross_remaining = cross_remaining - beat_capacity
                } else {
                  let bf = @music.NoteDuration::fit(cross_remaining).unwrap_or(
                    @music.Eighth,
                  )
                  beat_notes.push(@music.MeasureNote::{
                    midi: Some(midi.value),
                    duration: bf,
                    accidental: None,
                    tie: Some(@music.TieBoth),
                  })
                  cross_remaining = cross_remaining - bf.to_beats()
                }
                beats.push(@music.Beat::{ count: b, notes: beat_notes })
              }
              beats.push(@music.Beat::{ count: beat_index, notes })
              // Sort beats by count since we added out of order
              beats.sort_by(fn(a, b) { a.count.compare(b.count) })
              return MeasureResult::{
                beats,
                outgoing_tie: Some(TieContext::{
                  midi,
                  remaining_beats: beats_needed - remaining_in_measure,
                }),
              }
            } else {
              // Note exceeds beat but fits in measure - within-measure tie
              let fitted = @music.NoteDuration::fit(remaining_in_beat).unwrap_or(
                @music.Eighth,
              )
              notes.push(@music.MeasureNote::{
                midi: Some(midi.value),
                duration: fitted,
                accidental: update_accidental(midi),
                tie: Some(@music.TieStart),
              })
              current_pos = current_pos + fitted.to_beats()
              carry = Some(BeatTieCarry::{
                midi,
                remaining_beats: beats_needed - remaining_in_beat,
              })
              break // Move to next beat
            }
          }
        }
        None => {
          // Rest - truncate to beat boundary (rests don't tie)
          let duration = random_duration(rest_duration_weights, random_int)
          let rest_beats = @cmp.minimum(duration.to_beats(), remaining_in_beat)
          let rest_duration = @music.NoteDuration::fit(rest_beats).unwrap_or(
            @music.Eighth,
          )
          notes.push(@music.MeasureNote::{
            midi: None,
            duration: rest_duration,
            accidental: None,
            tie: None,
          })
          current_pos = current_pos + rest_duration.to_beats()
        }
      }
    }
    beats.push(@music.Beat::{ count: beat_index, notes })
  }

  // If carry remains after all beats, it means the carried note extends beyond the measure
  match carry {
    Some(c) =>
      MeasureResult::{
        beats,
        outgoing_tie: Some(TieContext::{
          midi: c.midi,
          remaining_beats: c.remaining_beats,
        }),
      }
    None => MeasureResult::{ beats, outgoing_tie: None }
  }
}

///|
/// Decide whether to generate a note or rest, and if note, which MIDI number
/// Uses chord tones across multiple octaves
fn decide_midi_number(
  chord : @music.Chord,
  rest_probability : Int,
  random_int : (Int) -> Int,
) -> @music.MidiNumber? {
  guard random_int(100) >= rest_probability else { return None }
  let base_tones = chord.tones()
  let extended_tones = [-1, 0, 1]
    .iter()
    .flat_map(fn(octave_offset) {
      base_tones
      .iter()
      .filter_map(fn(tone) { tone.shift_octave(octave_offset) })
    })
    .collect()
  let index = random_int(extended_tones.length())
  Some(extended_tones[index])
}
