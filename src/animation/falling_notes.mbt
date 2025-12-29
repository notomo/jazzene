///|
/// Represents a single falling note in the animation
pub struct FallingNote {
  note : @core.Note
  x : Double // Horizontal position (0-100%)
  y : Double // Vertical position (0-100%, 0 = top)
  velocity : Double // Pixels per frame
  id : Int
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
/// Add a new note to the animation
pub fn add_note(state : AnimationState, note : @core.Note) -> AnimationState {
  // Map MIDI number to horizontal position (88 piano keys, C0=21 to C8=108)
  let piano_key_index = note.midi_number - 21
  let x = if piano_key_index >= 0 && piano_key_index < 88 {
    piano_key_index.to_double() / 88.0 * 100.0
  } else {
    50.0
  } // Center if out of range
  let new_note = FallingNote::{
    note,
    x,
    y: 0.0, // Start at top
    velocity: 1.0, // Pixels per frame
    id: state.next_id,
  }
  let new_notes = state.notes.copy()
  new_notes.push(new_note)
  AnimationState::{ notes: new_notes, next_id: state.next_id + 1 }
}

///|
/// Update animation state (move notes down, remove off-screen)
pub fn update_animation(state : AnimationState) -> AnimationState {
  let updated_notes : Array[FallingNote] = []
  for note in state.notes {
    let new_y = note.y + note.velocity
    if new_y < 100.0 { // Keep notes that are still visible
      updated_notes.push(FallingNote::{ ..note, y: new_y })
    }
  }
  AnimationState::{ notes: updated_notes, next_id: state.next_id }
}
