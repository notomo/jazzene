///|
/// Beam grouping logic for connecting eighth notes

///|
/// Find groups of consecutive beamable notes within the same beat group.
/// Returns arrays of indices into the positioned notes array.
/// Eighth rests are included in groups (beam spans over them).
/// A group is only returned if it contains 2+ actual notes (non-rests).
pub fn find_beam_groups(
  positioned : Array[(Double, MeasureNote)],
  time_signature : TimeSignature,
) -> Array[Array[Int]] {
  let groups : Array[Array[Int]] = []
  let current_group : Array[Int] = []
  let mut current_beat_group = -1
  for i, pair in positioned {
    let (start_beat, note) = pair
    let is_beamable_duration = note.duration.is_beamable()
    let beat_group = time_signature.beat_group_index(start_beat)
    let same_beat_group = beat_group == current_beat_group
    if is_beamable_duration && (current_group.is_empty() || same_beat_group) {
      current_group.push(i)
      current_beat_group = beat_group
    } else if is_beamable_duration && not(same_beat_group) {
      flush_beam_group(groups, current_group, positioned)
      current_group.push(i)
      current_beat_group = beat_group
    } else {
      flush_beam_group(groups, current_group, positioned)
      current_beat_group = -1
    }
    //
  } else {
    flush_beam_group(groups, current_group, positioned)
  }
  groups
}

///|
fn flush_beam_group(
  groups : Array[Array[Int]],
  current : Array[Int],
  positioned : Array[(Double, MeasureNote)],
) -> Unit {
  let note_count = current
    .iter()
    .fold(init=0, fn(acc, i) {
      match positioned[i].1.midi {
        Some(_) => acc + 1
        None => acc
      }
    })
  if note_count >= 2 {
    groups.push(current.copy())
  }
  current.clear()
}
