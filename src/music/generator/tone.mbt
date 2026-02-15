///|
/// Build weighted candidates from tones relative to a previous note.
/// Each tone is weighted by interval cost and stamina, scaled by weight_ratio.
/// Returns empty array when weight_ratio is 0 (technique disabled).
fn weighted_tone_candidates(
  tones : Array[@music.MidiNumber],
  prev : @music.MidiNumber,
  stamina : Int,
  max_interval : Int,
  weight_ratio : Int,
) -> Array[(Int, @music.MidiNumber)] {
  guard weight_ratio > 0 else { return [] }
  filter_by_interval(tones, prev, max_interval)
  .iter()
  .map(fn(tone) {
    let cost = interval_cost(prev, tone)
    let weight = note_selection_weight(stamina, cost) * weight_ratio / 100
    (@cmp.maximum(1, weight), tone)
  })
  .collect()
}
