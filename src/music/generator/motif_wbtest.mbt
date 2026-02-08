///|
test "MotifMemory::empty creates empty state" {
  let mem = MotifMemory::empty()
  assert_eq(mem.stored.length(), 0)
  assert_eq(mem.recording.length(), 0)
  assert_true(mem.replaying is None)
}

///|
test "MotifMemory::record_interval accumulates intervals" {
  let mem = MotifMemory::empty()
    .record_interval(2)
    .record_interval(-3)
    .record_interval(5)
  inspect(mem.recording, content="[2, -3, 5]")
}

///|
test "MotifMemory::finish_recording stores motif when long enough" {
  // min_motif_intervals = 2, so 2 intervals should be stored
  let mem = MotifMemory::empty()
    .record_interval(2)
    .record_interval(-3)
    .finish_recording()
  assert_eq(mem.stored.length(), 1)
  inspect(mem.stored[0].intervals, content="[2, -3]")
  assert_eq(mem.recording.length(), 0)
  assert_true(mem.replaying is None)
}

///|
test "MotifMemory::finish_recording discards short motifs" {
  // Only 1 interval, below min_motif_intervals = 2
  let mem = MotifMemory::empty().record_interval(2).finish_recording()
  assert_eq(mem.stored.length(), 0)
  assert_eq(mem.recording.length(), 0)
}

///|
test "MotifMemory::finish_recording evicts oldest when full" {
  // max_stored_motifs = 4, add 5 motifs
  let mut mem = MotifMemory::empty()
  for i in 0..<5 {
    mem = mem.record_interval(i).record_interval(i + 10).finish_recording()
  }
  assert_eq(mem.stored.length(), 4)
  // First motif (intervals [0, 10]) should be evicted
  // Second motif (intervals [1, 11]) should now be first
  inspect(mem.stored[0].intervals, content="[1, 11]")
  inspect(mem.stored[3].intervals, content="[4, 14]")
}

///|
test "MotifMemory::start_replay and next_replay_interval" {
  let motif = Motif::{ intervals: [2, -3, 5] }
  let mem = MotifMemory::empty().start_replay(motif)
  // First interval
  let (i1, mem) = mem.next_replay_interval().unwrap()
  assert_eq(i1, 2)
  // Second interval
  let (i2, mem) = mem.next_replay_interval().unwrap()
  assert_eq(i2, -3)
  // Third interval
  let (i3, mem) = mem.next_replay_interval().unwrap()
  assert_eq(i3, 5)
  // No more intervals
  assert_true(mem.next_replay_interval() is None)
}

///|
test "Motif::invert negates all intervals" {
  let motif = Motif::{ intervals: [2, -3, 5, 0] }
  let inverted = motif.invert()
  inspect(inverted.intervals, content="[-2, 3, -5, 0]")
}

///|
test "select_motif_guided_note finds closest chord tone to target" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let key = @music.KeySignature::c_major()
  let last_midi = @music.MidiNumber::new(60).unwrap() // C4
  // Target: 62 (D4) - should snap to closest chord/scale tone
  let result = select_motif_guided_note(62, chord, key, last_midi, 7)
  // D4 (62) is a scale tone of C major, should be selected
  assert_eq(result.unwrap().value, 62)
}

///|
test "select_motif_guided_note returns None for out-of-range target" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let key = @music.KeySignature::c_major()
  let last_midi = @music.MidiNumber::new(60).unwrap()
  // Target: 200 (invalid MIDI)
  let result = select_motif_guided_note(200, chord, key, last_midi, 7)
  assert_true(result is None)
}

///|
test "record_motif_interval records when not first note and not replaying" {
  let mem = MotifMemory::empty()
  let prev = @music.MidiNumber::new(60).unwrap()
  let curr = @music.MidiNumber::new(64).unwrap()
  let result = record_motif_interval(mem, Some(prev), curr, false)
  inspect(result.recording, content="[4]")
}

///|
test "record_motif_interval skips on first note" {
  let mem = MotifMemory::empty()
  let prev = @music.MidiNumber::new(60).unwrap()
  let curr = @music.MidiNumber::new(64).unwrap()
  let result = record_motif_interval(mem, Some(prev), curr, true)
  assert_eq(result.recording.length(), 0)
}

///|
test "record_motif_interval skips when replaying" {
  let motif = Motif::{ intervals: [2, -3] }
  let mem = MotifMemory::empty().start_replay(motif)
  let prev = @music.MidiNumber::new(60).unwrap()
  let curr = @music.MidiNumber::new(64).unwrap()
  let result = record_motif_interval(mem, Some(prev), curr, false)
  assert_eq(result.recording.length(), 0)
}

///|
test "maybe_start_motif_replay starts replay when probability met" {
  let motif = Motif::{ intervals: [2, -3, 5] }
  let mem = MotifMemory::{ stored: [motif], recording: [], replaying: None }
  // random_int always returns 0, so probability check (0 < 30) passes
  let settings = Settings::{
    ..Settings::default(0),
    motif_reuse_probability: 30,
  }
  let result = maybe_start_motif_replay(mem, settings, fn(_n) { 0 })
  assert_true(result.replaying is Some(_))
}

///|
test "maybe_start_motif_replay skips when no stored motifs" {
  let mem = MotifMemory::empty()
  let settings = Settings::default(0)
  let result = maybe_start_motif_replay(mem, settings, fn(_n) { 0 })
  assert_true(result.replaying is None)
}

///|
test "maybe_start_motif_replay skips when probability not met" {
  let motif = Motif::{ intervals: [2, -3, 5] }
  let mem = MotifMemory::{ stored: [motif], recording: [], replaying: None }
  let settings = Settings::{
    ..Settings::default(0),
    motif_reuse_probability: 30,
  }
  // random_int returns 99, so probability check (99 < 30) fails
  let result = maybe_start_motif_replay(mem, settings, fn(_n) { 99 })
  assert_true(result.replaying is None)
}
