///|
/// A recorded melodic pattern as a sequence of intervals between consecutive notes.
/// Intervals are in signed semitones (positive = ascending, negative = descending).
pub(all) struct Motif {
  intervals : Array[Int]
} derive(Eq, Show)

///|
/// Maximum number of stored motifs to keep in memory
let max_stored_motifs : Int = 4

///|
/// Minimum number of intervals required for a motif to be worth storing
let min_motif_intervals : Int = 2

///|
/// Memory of recorded motifs passed between measures during generation
pub(all) struct MotifMemory {
  stored : Array[Motif] // completed motifs (most recent last)
  recording : Array[Int] // intervals being recorded in current phrase
  replaying : (Motif, Int)? // (motif, next_interval_index) if currently replaying
} derive(Eq, Show)

///|
/// Create empty motif memory
pub fn MotifMemory::empty() -> MotifMemory {
  MotifMemory::{ stored: [], recording: [], replaying: None }
}

///|
/// Record an interval into the current motif being built
fn MotifMemory::record_interval(
  self : MotifMemory,
  interval : Int,
) -> MotifMemory {
  MotifMemory::{ ..self, recording: self.recording + [interval] }
}

///|
/// Finish recording the current phrase and store it as a motif if long enough.
/// Clears recording and replaying state.
fn MotifMemory::finish_recording(self : MotifMemory) -> MotifMemory {
  guard self.recording.length() >= min_motif_intervals else {
    return MotifMemory::{ ..self, recording: [], replaying: None }
  }
  let motif = Motif::{ intervals: self.recording }
  let stored = if self.stored.length() >= max_stored_motifs {
    self.stored[1:].to_array() + [motif]
  } else {
    self.stored + [motif]
  }
  MotifMemory::{ stored, recording: [], replaying: None }
}

///|
/// Start replaying a motif from the beginning
fn MotifMemory::start_replay(self : MotifMemory, motif : Motif) -> MotifMemory {
  MotifMemory::{ ..self, recording: [], replaying: Some((motif, 0)) }
}

///|
/// Get the next interval from the replaying motif and advance the index.
/// Returns None if not replaying or replay is finished.
fn MotifMemory::next_replay_interval(self : MotifMemory) -> (Int, MotifMemory)? {
  match self.replaying {
    Some((motif, index)) if index < motif.intervals.length() => {
      let interval = motif.intervals[index]
      let updated = MotifMemory::{ ..self, replaying: Some((motif, index + 1)) }
      Some((interval, updated))
    }
    _ => None
  }
}

///|
/// Apply melodic inversion to a motif (negate all intervals)
fn Motif::invert(self : Motif) -> Motif {
  Motif::{ intervals: self.intervals.map(fn(i) { -i }) }
}
