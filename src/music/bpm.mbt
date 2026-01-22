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

///|
/// Calculate total duration based on BPM and measure count (4/4 time signature)
pub fn calculate_total_duration(bpm~ : Int, measure_count~ : Int) -> Duration {
  Duration::from_milliseconds(measure_count.to_double() * ms_per_measure(bpm))
}
