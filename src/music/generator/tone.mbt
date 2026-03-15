///|
/// Build weighted candidates tagged with ToneOrigin.
/// Each candidate is (weight, midi, origin).
/// Returns empty array when weight_ratio is 0 (technique disabled).
fn weighted_tone_candidates_tagged(
  tones : Array[@music.MidiNumber],
  prev : @music.MidiNumber,
  stamina : Int,
  max_interval : Int,
  weight_ratio : Int,
  origin : @music.ToneOrigin,
) -> Array[(Int, @music.MidiNumber, @music.ToneOrigin)] {
  guard weight_ratio > 0 else { return [] }
  filter_by_interval(tones, prev, max_interval)
  .iter()
  .map(fn(tone) {
    let cost = interval_cost(prev, tone)
    let weight = note_selection_weight(stamina, cost) * weight_ratio / 100
    (@cmp.maximum(1, weight), tone, origin)
  })
  .collect()
}

///|
/// Select a random element from tagged weighted candidates, returning (midi, origin).
fn weighted_random_select_tagged(
  weighted : Array[(Int, @music.MidiNumber, @music.ToneOrigin)],
  random_int : (Int) -> Int,
) -> (@music.MidiNumber, @music.ToneOrigin)? {
  guard not(weighted.is_empty()) else { return None }
  let total = weighted.iter().fold(init=0, fn(acc, tuple) { acc + tuple.0 })
  let r = random_int(total)
  let mut cumulative = 0
  for tuple in weighted {
    cumulative = cumulative + tuple.0
    if r < cumulative {
      return Some((tuple.1, tuple.2))
    }
  }
  let last = weighted[weighted.length() - 1]
  Some((last.1, last.2))
}

///|
/// Compute the jazz tension degree (9, 11, 13 etc.) for a tension tone
/// given the chord root MIDI pitch class.
fn tension_degree(root_midi : Int, tone : @music.MidiNumber) -> Int {
  let interval = (tone.value - root_midi + 120) % 12
  match interval {
    2 => 9
    5 => 11
    6 => 11 // #11
    8 => 13 // b13
    9 => 13
    _ => 9 // fallback
  }
}
