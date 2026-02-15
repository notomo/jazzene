///|
/// Syncopation check: on downbeats, probabilistically return an eighth rest
/// to shift the phrase start to the upbeat.
/// Returns Some(Eighth) if syncopation fires, None otherwise.
fn syncopation_rest(
  measure_pos : Double,
  remaining : Double,
  probability : Int,
  random_int : (Int) -> Int,
) -> @music.NoteDuration? {
  guard probability > 0 else { return None }
  let is_on_downbeat = (measure_pos - measure_pos.to_int().to_double()).abs() <
    0.01
  guard is_on_downbeat && random_int(100) < probability else { return None }
  if remaining >= @music.Eighth.to_beats() {
    Some(@music.Eighth)
  } else {
    None
  }
}
