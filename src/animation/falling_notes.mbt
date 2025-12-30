///|
/// Represents a single falling note in the animation
pub struct FallingNote {
  note : @core.Note
  x : Double // Horizontal position (0-100%)
  y : Double // Vertical position (0-100%, 0 = top)
  velocity : Double // Pixels per frame
  id : Int
  is_black : Bool // Whether this is a black key
  triggered : Bool // Whether this note has triggered sound
}

///|
/// Animation state containing all falling notes
pub struct AnimationState {
  notes : Array[FallingNote]
  next_id : Int
}

///|
/// Create initial empty animation state
pub fn create_initial_animation_state() -> AnimationState {
  AnimationState::{ notes: [], next_id: 0 }
}

///|
/// Check if a note is a black key (chromatic scale position)
fn is_black_key(note_in_octave : Int) -> Bool {
  match note_in_octave {
    1 | 3 | 6 | 8 | 10 => true // C#, D#, F#, G#, A#
    _ => false
  }
}

///|
/// Count white keys before a given MIDI note (starting from MIDI 36)
fn count_white_keys_before(midi : Int) -> Int {
  let mut count = 0
  for i = 36; i < midi; i = i + 1 {
    if not(is_black_key(i % 12)) {
      count = count + 1
    }
  }
  count
}

///|
/// Count total white keys in the keyboard range (36-96)
fn count_total_white_keys() -> Int {
  let mut count = 0
  for midi = 36; midi < 97; midi = midi + 1 {
    if not(is_black_key(midi % 12)) {
      count = count + 1
    }
  }
  count
}

///|
/// Add a new note to the animation
pub fn add_note(state : AnimationState, note : @core.Note) -> AnimationState {
  let midi = note.midi_number
  // Only handle notes in keyboard range (36-96, C2-C7)
  if midi < 36 || midi >= 97 {
    return state
  }
  let is_black = is_black_key(midi % 12)
  let total_white_keys = count_total_white_keys()

  // Calculate position same as piano keyboard
  let x = if is_black {
    // Black key - position on border between white keys
    let white_key_index = count_white_keys_before(midi)
    white_key_index.to_double() * 100.0 / total_white_keys.to_double()
  } else {
    // White key - calculate center position
    let white_key_index = count_white_keys_before(midi)
    (white_key_index.to_double() + 0.5) * 100.0 / total_white_keys.to_double()
  }
  let new_note = FallingNote::{
    note,
    x,
    y: 0.0, // Start at top
    velocity: 1.0, // Pixels per frame
    id: state.next_id,
    is_black,
    triggered: false,
  }
  let new_notes = state.notes.copy()
  new_notes.push(new_note)
  AnimationState::{ notes: new_notes, next_id: state.next_id + 1 }
}

///|
/// Update animation state (move notes down, remove off-screen, trigger sounds)
pub fn update_animation(
  state : AnimationState,
  on_trigger : (@core.Note) -> Unit,
) -> AnimationState {
  let updated_notes : Array[FallingNote] = []
  let trigger_threshold = 95.0 // Trigger sound when note reaches 95% (near bottom)
  for note in state.notes {
    let new_y = note.y + note.velocity

    // Check if note should trigger sound
    let should_trigger = new_y >= trigger_threshold && not(note.triggered)
    if should_trigger {
      on_trigger(note.note)
    }
    if new_y < 105.0 {
      // Keep notes slightly past bottom for smooth disappearance
      updated_notes.push(FallingNote::{
        ..note,
        y: new_y,
        triggered: note.triggered || should_trigger,
      })
    }
  }
  AnimationState::{ notes: updated_notes, next_id: state.next_id }
}
