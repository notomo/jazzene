///|
/// Type alias for a generator function that produces NoteValues
pub type NoteValueGenerator = () -> NoteValue

///|
/// Generate improvisation from a note value generator
/// Returns note values (notes and rests) that fit within the specified measures
/// measure_count specifies the total number of measures (including leading rest)
pub fn generate_improvisation(
  generator : NoteValueGenerator,
  measure_count : Int,
) -> Array[NoteValue] {
  let total_beats = measure_count.to_double() * 4.0
  // Start with 1 measure of rest (4 beats)
  let note_values = [NoteValue::Rest(duration=Whole)]
  for current_beats = 4.0; current_beats < total_beats; {
    let note_value = generator()
    let beats = note_value.note_duration().to_beats()
    let remaining = total_beats - current_beats
    if beats <= remaining {
      note_values.push(note_value)
      continue current_beats + beats
    }
    match NoteDuration::fit(remaining) {
      Some(fitted) => {
        let trimmed = match note_value {
          Note(midi~, ..) => NoteValue::Note(midi~, duration=fitted)
          Rest(..) => NoteValue::Rest(duration=fitted)
        }
        note_values.push(trimmed)
      }
      None => ()
    }
    break
  }
  note_values
}
