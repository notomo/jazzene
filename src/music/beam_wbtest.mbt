///|
fn make_note(midi : Int, duration : NoteDuration) -> MeasureNote {
  { midi: Some(midi), duration, accidental: None, tie: None }
}

///|
fn make_rest(duration : NoteDuration) -> MeasureNote {
  { midi: None, duration, accidental: None, tie: None }
}

///|
fn ts44() -> TimeSignature {
  TimeSignature::{ numerator: 4, denominator: 4 }
}

///|
test "consecutive eighth notes are grouped" {
  let positioned : Array[(Double, MeasureNote)] = [
    (0.0, make_note(60, Eighth)),
    (0.5, make_note(62, Eighth)),
    (1.0, make_note(64, Eighth)),
    (1.5, make_note(65, Eighth)),
  ]
  let groups = find_beam_groups(positioned, ts44())
  assert_eq(groups.length(), 1)
  assert_eq(groups[0], [0, 1, 2, 3])
}

///|
test "eighth rest in group keeps beam" {
  let positioned : Array[(Double, MeasureNote)] = [
    (0.0, make_note(60, Eighth)),
    (0.5, make_rest(Eighth)),
    (1.0, make_note(64, Eighth)),
  ]
  let groups = find_beam_groups(positioned, ts44())
  assert_eq(groups.length(), 1)
  assert_eq(groups[0], [0, 1, 2])
}

///|
test "beat group boundary splits beam in 4/4" {
  let positioned : Array[(Double, MeasureNote)] = [
    (0.0, make_note(60, Eighth)),
    (0.5, make_note(62, Eighth)),
    (1.0, make_note(64, Eighth)),
    (1.5, make_note(65, Eighth)),
    (2.0, make_note(67, Eighth)),
    (2.5, make_note(69, Eighth)),
  ]
  let groups = find_beam_groups(positioned, ts44())
  assert_eq(groups.length(), 2)
  assert_eq(groups[0], [0, 1, 2, 3])
  assert_eq(groups[1], [4, 5])
}

///|
test "single note is not grouped" {
  let positioned : Array[(Double, MeasureNote)] = [
    (0.0, make_note(60, Eighth)),
    (0.5, make_note(62, Quarter)),
  ]
  let groups = find_beam_groups(positioned, ts44())
  assert_eq(groups.length(), 0)
}

///|
test "quarter note splits beam group" {
  let positioned : Array[(Double, MeasureNote)] = [
    (0.0, make_note(60, Eighth)),
    (0.5, make_note(62, Eighth)),
    (1.0, make_note(64, Quarter)),
  ]
  let groups = find_beam_groups(positioned, ts44())
  assert_eq(groups.length(), 1)
  assert_eq(groups[0], [0, 1])
}

///|
test "triplets are separated from regular eighths" {
  // Eighth at 0.0, then 3 triplets starting at beat 1
  let positioned : Array[(Double, MeasureNote)] = [
    (0.0, make_note(60, Eighth)),
    (0.5, make_note(62, Eighth)),
    (1.0, make_note(64, EighthTriplet)),
    (1.333, make_note(65, EighthTriplet)),
    (1.666, make_note(67, EighthTriplet)),
    (2.0, make_note(69, Eighth)),
    (2.5, make_note(71, Eighth)),
  ]
  let groups = find_beam_groups(positioned, ts44())
  assert_eq(groups.length(), 3)
  assert_eq(groups[0], [0, 1])
  assert_eq(groups[1], [2, 3, 4])
  assert_eq(groups[2], [5, 6])
}

///|
test "consecutive triplet groups split at beat boundaries" {
  // Two triplet groups on beats 2 and 3 (same beat group in 4/4)
  let positioned : Array[(Double, MeasureNote)] = [
    (2.0, make_note(60, EighthTriplet)),
    (2.333, make_note(62, EighthTriplet)),
    (2.666, make_note(64, EighthTriplet)),
    (3.0, make_note(65, EighthTriplet)),
    (3.333, make_note(67, EighthTriplet)),
    (3.666, make_note(69, EighthTriplet)),
  ]
  let groups = find_beam_groups(positioned, ts44())
  assert_eq(groups.length(), 2)
  assert_eq(groups[0], [0, 1, 2])
  assert_eq(groups[1], [3, 4, 5])
}

///|
test "triplets between regular eighths form separate groups" {
  let positioned : Array[(Double, MeasureNote)] = [
    (0.0, make_note(60, Eighth)),
    (0.5, make_note(62, Eighth)),
    (1.0, make_note(64, EighthTriplet)),
    (1.333, make_note(65, EighthTriplet)),
    (1.666, make_note(67, EighthTriplet)),
  ]
  let groups = find_beam_groups(positioned, ts44())
  assert_eq(groups.length(), 2)
  assert_eq(groups[0], [0, 1])
  assert_eq(groups[1], [2, 3, 4])
}
