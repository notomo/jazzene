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
  let mut current_is_triplet = false
  let mut current_beat_index = -1
  for i, pair in positioned {
    let (start_beat, note) = pair
    let is_beamable_duration = note.duration.is_beamable()
    let beat_group = time_signature.beat_group_index(start_beat)
    let is_triplet = note.duration is EighthTriplet
    let same_triplet_kind = is_triplet == current_is_triplet
    // Triplets use per-beat grouping (split at integer beat boundaries)
    // Regular eighths use beat-group grouping (e.g. 2-beat groups in 4/4)
    let beat_index = start_beat.to_int()
    let same_group = if current_group.is_empty() {
      true
    } else if not(same_triplet_kind) {
      false
    } else if is_triplet {
      beat_index == current_beat_index
    } else {
      beat_group == current_beat_group
    }
    if is_beamable_duration && same_group {
      current_group.push(i)
      current_beat_group = beat_group
      current_is_triplet = is_triplet
      current_beat_index = beat_index
    } else if is_beamable_duration {
      flush_beam_group(groups, current_group, positioned)
      current_group.push(i)
      current_beat_group = beat_group
      current_is_triplet = is_triplet
      current_beat_index = beat_index
    } else {
      flush_beam_group(groups, current_group, positioned)
      current_beat_group = -1
      current_beat_index = -1
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
