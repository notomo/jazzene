///|
/// Measure representation for lead sheet visualization
/// Converts NoteValueSound arrays into measure-organized data structures

///|
/// Accidental types for note display
pub enum Accidental {
  Sharp
  Flat
  Natural
} derive(Eq, Show)

///|
/// Tie state for notes that span measure boundaries
pub enum TieState {
  None // No tie
  TieStart // Ties to next measure
  TieEnd // Tied from previous measure
  TieBoth // Spans 3+ measures (both in and out)
} derive(Eq, Show)

///|
/// Pitch state within a measure for accidental tracking
enum PitchState {
  Natural
  Sharpened
  Flattened
} derive(Eq)

///|
/// Represents one measure with its chord and notes
pub struct Measure {
  chord : Chord
  notes : Array[MeasureNote]
  start_time : Duration
  duration : Duration
  measure_index : Int
}

///|
/// A note positioned within a measure
pub struct MeasureNote {
  midi : Int? // None for rests
  duration : NoteDuration
  start_beat : Double // 0.0 to 4.0 for 4/4 time
  accidental : Accidental? // Sharp, Flat, or Natural symbol to display
  tie_state : TieState // Tie connection state for cross-measure notes
}

///|
/// Determine the required pitch state for a MIDI number
/// Based on C major key (no sharps/flats), so black keys need accidentals
fn midi_to_required_state(midi : Int) -> PitchState {
  let pitch_class = midi % 12
  match pitch_class {
    1 => Sharpened // C#
    3 => Flattened // Eb (prefer flat per ChordRoot convention)
    6 => Sharpened // F#
    8 => Flattened // Ab (prefer flat per ChordRoot convention)
    10 => Flattened // Bb (prefer flat per ChordRoot convention)
    _ => PitchState::Natural // White keys
  }
}

///|
/// Calculate the accidental to display based on current pitch states
/// Returns None if no accidental change is needed
fn calculate_accidental(
  midi : Int,
  pitch_states : Map[Int, PitchState],
) -> Accidental? {
  let pitch_class = midi % 12
  let required_state = midi_to_required_state(midi)
  let current_state = pitch_states
    .get(pitch_class)
    .unwrap_or(PitchState::Natural)
  if required_state == current_state {
    None // No change needed
  } else {
    // State change needed, return appropriate accidental
    match required_state {
      PitchState::Natural => Some(Accidental::Natural)
      Sharpened => Some(Sharp)
      Flattened => Some(Flat)
    }
  }
}

///|
/// Convert MIDI pitch class to diatonic steps from C
fn pitch_class_to_diatonic_step(pitch_class : Int) -> Int {
  match pitch_class {
    0 | 1 => 0 // C, C#
    2 | 3 => 1 // D, D#
    4 => 2 // E
    5 | 6 => 3 // F, F#
    7 | 8 => 4 // G, G#
    9 | 10 => 5 // A, A#
    11 => 6 // B
    _ => 0
  }
}

///|
/// Convert MIDI number to Y position on staff
/// E4 (MIDI 64) is the bottom line of treble clef
pub fn midi_to_staff_y(midi : Int, staff_y : Double) -> Double {
  let staff_line_spacing = 15.0

  // Calculate pitch class and octave
  let pitch_class = midi % 12
  let octave = midi / 12 - 1

  // Calculate diatonic steps from E4
  // E4 = pitch_class 4, octave 4
  let e4_pitch_class = 4
  let e4_octave = 4
  let note_diatonic_step = pitch_class_to_diatonic_step(pitch_class)
  let e4_diatonic_step = pitch_class_to_diatonic_step(e4_pitch_class)
  let total_diatonic_steps = (octave - e4_octave) * 7 +
    (note_diatonic_step - e4_diatonic_step)

  // E4 is on the bottom line (staff_y + 4 * staff_line_spacing)
  // Each diatonic step = half a line spacing
  let offset = total_diatonic_steps.to_double() * -(staff_line_spacing / 2.0)
  staff_y + staff_line_spacing * 4.0 + offset
}

///|
/// Intermediate representation of a note with position info (Step 1 output)
/// Tracks split information for later tie state calculation
priv struct PositionedNote {
  midi : Int?
  duration : NoteDuration
  start_beat : Double
  measure_index : Int
  split_piece : Int // Which piece of the split (0 = first)
  total_pieces : Int // Total number of pieces (1 = no split)
}

///|
/// Note with tie state calculated (Step 2 output)
priv struct TiedNote {
  midi : Int?
  duration : NoteDuration
  start_beat : Double
  measure_index : Int
  tie_state : TieState
}

///|
/// Step 1: Split sounds into positioned notes at measure boundaries
/// Does not calculate tie states - only records split information
fn split_to_positioned_notes(
  sounds : Array[NoteValueSound],
  measure_duration_ms : Double,
  measure_count : Int,
) -> Array[PositionedNote] {
  let result : Array[PositionedNote] = []
  let beat_duration_ms = measure_duration_ms / 4.0
  for sound in sounds {
    let sound_start_ms = sound.start_time.to_milliseconds()

    // Calculate which measure this sound starts in
    let start_measure_index = (sound_start_ms / measure_duration_ms).to_int()

    // If sound starts beyond our measures, skip it
    if start_measure_index >= measure_count {
      continue
    }

    // Calculate start beat within the measure
    let measure_start_ms = start_measure_index.to_double() * measure_duration_ms
    let start_beat = (sound_start_ms - measure_start_ms) / beat_duration_ms

    // Get MIDI and duration
    let midi = sound.note_value.midi().map(fn(m) { m.value })
    let total_beats = sound.note_value.note_duration().to_beats()

    // Rests cannot be tied - don't split them
    match midi {
      None => {
        result.push(PositionedNote::{
          midi: None,
          duration: sound.note_value.note_duration(),
          start_beat,
          measure_index: start_measure_index,
          split_piece: 0,
          total_pieces: 1,
        })
        continue
      }
      Some(_) => ()
    }

    // Check if note spans across measure boundaries
    let beats_until_measure_end = 4.0 - start_beat
    if total_beats <= beats_until_measure_end {
      // Note fits in this measure
      result.push(PositionedNote::{
        midi,
        duration: sound.note_value.note_duration(),
        start_beat,
        measure_index: start_measure_index,
        split_piece: 0,
        total_pieces: 1,
      })
    } else {
      // Note spans measures - split it and count pieces first
      let pieces : Array[(Int, Double, Double)] = [] // (measure_index, start_beat, beats)
      let mut remaining_beats = total_beats
      let mut current_measure = start_measure_index
      let mut current_beat = start_beat
      while remaining_beats > 0.0 && current_measure < measure_count {
        let beats_until_end = 4.0 - current_beat
        if remaining_beats <= beats_until_end {
          pieces.push((current_measure, current_beat, remaining_beats))
          remaining_beats = 0.0
        } else {
          pieces.push((current_measure, current_beat, beats_until_end))
          remaining_beats = remaining_beats - beats_until_end
          current_measure = current_measure + 1
          current_beat = 0.0
        }
      }

      // Create positioned notes with split info
      let total_pieces = pieces.length()
      for split_piece, piece in pieces {
        let (measure_idx, beat, beats) = piece
        result.push(PositionedNote::{
          midi,
          duration: NoteDuration::from_beats(beats),
          start_beat: beat,
          measure_index: measure_idx,
          split_piece,
          total_pieces,
        })
      }
    }
  }
  result
}

///|
/// Step 2: Calculate tie states from split information
fn calculate_tie_states(notes : Array[PositionedNote]) -> Array[TiedNote] {
  notes.map(fn(note) {
    let tie_state : TieState = if note.total_pieces == 1 {
      TieState::None
    } else if note.split_piece == 0 {
      TieStart
    } else if note.split_piece == note.total_pieces - 1 {
      TieEnd
    } else {
      TieBoth
    }
    TiedNote::{
      midi: note.midi,
      duration: note.duration,
      start_beat: note.start_beat,
      measure_index: note.measure_index,
      tie_state,
    }
  })
}

///|
/// Step 3: Group notes by measure index
fn group_by_measure(notes : Array[TiedNote]) -> Map[Int, Array[TiedNote]] {
  let grouped : Map[Int, Array[TiedNote]] = {}
  for note in notes {
    match grouped.get(note.measure_index) {
      Some(arr) => arr.push(note)
      None => grouped[note.measure_index] = [note]
    }
  }
  grouped
}

///|
/// Step 4: Apply accidentals to grouped notes
fn apply_accidentals(
  grouped : Map[Int, Array[TiedNote]],
) -> Map[Int, Array[MeasureNote]] {
  let result : Map[Int, Array[MeasureNote]] = {}
  for measure_index, tied_notes in grouped {
    result[measure_index] = apply_accidentals_to_tied_notes(tied_notes)
  }
  result
}

///|
/// Step 5: Assemble final Measure objects
fn assemble_measures(
  notes_by_measure : Map[Int, Array[MeasureNote]],
  chords : Array[Chord],
  measure_duration_ms : Double,
  measure_count : Int,
) -> Array[Measure] {
  let measures : Array[Measure] = []

  // Add leading rest measure with dummy chord (always C major to avoid confusion)
  let dummy_chord = Chord::{ root: ChordRoot::C, quality: Major }
  let leading_rest_notes = notes_by_measure.get(0).unwrap_or([])
  measures.push(Measure::{
    chord: dummy_chord,
    notes: leading_rest_notes,
    start_time: Duration::from_milliseconds(0.0),
    duration: Duration::from_milliseconds(measure_duration_ms),
    measure_index: 0,
  })

  // Calculate number of chord measures needed (total - 1 for leading rest)
  let chord_measures_needed = measure_count - 1

  // If no chords or no measures needed, return just the leading rest
  if chords.length() == 0 || chord_measures_needed <= 0 {
    return measures
  }

  // Create chord measures
  for i = 0; i < chord_measures_needed; i = i + 1 {
    let chord = chords[i % chords.length()]
    let measure_index = i + 1
    let measure_start = measure_index.to_double() * measure_duration_ms
    let measure_notes = notes_by_measure.get(measure_index).unwrap_or([])
    measures.push(Measure::{
      chord,
      notes: measure_notes,
      start_time: Duration::from_milliseconds(measure_start),
      duration: Duration::from_milliseconds(measure_duration_ms),
      measure_index,
    })
  }
  measures
}

///|
/// Calculate accidentals for a list of tied notes in a single measure
/// TieEnd notes don't get accidentals (pitch already established)
fn apply_accidentals_to_tied_notes(
  tied_notes : Array[TiedNote],
) -> Array[MeasureNote] {
  // Sort by start_beat to ensure correct accidental calculation order
  tied_notes.sort_by(fn(a, b) { a.start_beat.compare(b.start_beat) })
  let pitch_states : Map[Int, PitchState] = {}
  let measure_notes : Array[MeasureNote] = []
  for note in tied_notes {
    let accidental : Accidental? = match note.midi {
      Some(midi) => {
        // TieEnd notes don't show accidentals (pitch established in previous measure)
        let acc : Accidental? = match note.tie_state {
          TieEnd | TieBoth => None
          _ => calculate_accidental(midi, pitch_states)
        }
        // Update pitch state after calculating accidental
        let pitch_class = midi % 12
        pitch_states[pitch_class] = midi_to_required_state(midi)
        acc
      }
      None => None
    }
    measure_notes.push(MeasureNote::{
      midi: note.midi,
      duration: note.duration,
      start_beat: note.start_beat,
      accidental,
      tie_state: note.tie_state,
    })
  }
  measure_notes
}

///|
/// Convert sounds array to measures array
/// measure_count specifies the total number of measures (including leading rest)
/// Notes that span across measure boundaries are split with appropriate tie states
pub fn convert_sounds_to_measures(
  sounds : Array[NoteValueSound],
  chords : Array[Chord],
  bpm : Int,
  measure_count : Int,
) -> Array[Measure] {
  let measure_duration_ms = ms_per_measure(bpm)
  sounds
  |> split_to_positioned_notes(measure_duration_ms, measure_count)
  |> calculate_tie_states
  |> group_by_measure
  |> apply_accidentals
  |> assemble_measures(chords, measure_duration_ms, measure_count)
}
