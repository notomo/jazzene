///|
/// Calculate milliseconds per beat for a given BPM
pub fn ms_per_beat(bpm : Int) -> Double {
  60000.0 / bpm.to_double()
}

///|
/// Calculate milliseconds per measure for a given BPM and beats per measure
pub fn ms_per_measure(bpm : Int, beats_per_measure~ : Double) -> Double {
  ms_per_beat(bpm) * beats_per_measure
}

///|
/// Calculate total duration based on BPM, measure count, and beats per measure
pub fn calculate_total_duration(
  bpm~ : Int,
  measure_count~ : Int,
  beats_per_measure~ : Double,
) -> Duration {
  Duration::from_milliseconds(
    measure_count.to_double() * ms_per_measure(bpm, beats_per_measure~),
  )
}
