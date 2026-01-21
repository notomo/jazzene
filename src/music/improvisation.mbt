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
    match trim_to_fit(remaining, note_value) {
      Some(trimmed) => note_values.push(trimmed)
      None => ()
    }
    break
  }
  note_values
}

///|
/// Trim a note value to fit within remaining beats
fn trim_to_fit(remaining_beats : Double, note_value : NoteValue) -> NoteValue? {
  [Whole, DottedHalf, Half, DottedQuarter, Quarter, DottedEighth, Eighth]
  .iter()
  .find_first(fn(d) { d.to_beats() <= remaining_beats + 0.001 })
  .map(fn(duration) {
    match note_value {
      Note(midi~, ..) => NoteValue::Note(midi~, duration~)
      Rest(..) => NoteValue::Rest(duration~)
    }
  })
}
