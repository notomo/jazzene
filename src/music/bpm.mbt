///|
/// Calculate milliseconds per beat for a given BPM
pub fn ms_per_beat(bpm : Int) -> Double {
  60000.0 / bpm.to_double()
}

///|
/// Calculate milliseconds per measure for a given BPM (assumes 4/4 time)
pub fn ms_per_measure(bpm : Int) -> Double {
  ms_per_beat(bpm) * 4.0
}
