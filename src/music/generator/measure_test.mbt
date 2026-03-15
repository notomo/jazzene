///|
test "create_chord_segments returns empty for empty input" {
  let result = create_chord_segments([], 4.0)
  assert_eq(result.length(), 0)
}

///|
test "create_chord_segments creates one segment for one chord" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let result = create_chord_segments([chord], 4.0)
  assert_eq(result.length(), 1)
  assert_eq(result[0].start_beat, 0.0)
  assert_eq(result[0].end_beat, 4.0)
}

///|
test "create_chord_segments splits evenly for two chords" {
  let c = @music.Chord::{ root: @music.C, quality: @music.Major7, bass: None }
  let f = @music.Chord::{ root: @music.F, quality: @music.Major7, bass: None }
  let result = create_chord_segments([c, f], 4.0)
  assert_eq(result.length(), 2)
  assert_eq(result[0].start_beat, 0.0)
  assert_eq(result[0].end_beat, 2.0)
  assert_eq(result[1].start_beat, 2.0)
  assert_eq(result[1].end_beat, 4.0)
}

///|
test "create_chord_segments assigns correct chords" {
  let c = @music.Chord::{ root: @music.C, quality: @music.Major7, bass: None }
  let f = @music.Chord::{ root: @music.F, quality: @music.Major7, bass: None }
  let result = create_chord_segments([c, f], 4.0)
  assert_eq(result[0].chord, c)
  assert_eq(result[1].chord, f)
}

///|
test "MeasureContext::chord_at returns chord containing beat" {
  let c = @music.Chord::{ root: @music.C, quality: @music.Major7, bass: None }
  let f = @music.Chord::{ root: @music.F, quality: @music.Major7, bass: None }
  let ctx = @generator.MeasureContext::{
    chords: create_chord_segments([c, f], 4.0),
    incoming_tie: None,
    key: @music.KeySignature::c_major(),
    time_signature: @music.TimeSignature::default(),
    beats_per_measure: 4.0,
    incoming_stamina: 50,
    incoming_last_midi: None,
    incoming_phrase: None,
  }
  assert_eq(ctx.chord_at(0.0), c)
  assert_eq(ctx.chord_at(1.5), c)
  assert_eq(ctx.chord_at(2.0), f)
  assert_eq(ctx.chord_at(3.9), f)
}

///|
test "MeasureContext::chord_at returns last chord when beat is at end" {
  let c = @music.Chord::{ root: @music.C, quality: @music.Major7, bass: None }
  let ctx = @generator.MeasureContext::{
    chords: create_chord_segments([c], 4.0),
    incoming_tie: None,
    key: @music.KeySignature::c_major(),
    time_signature: @music.TimeSignature::default(),
    beats_per_measure: 4.0,
    incoming_stamina: 50,
    incoming_last_midi: None,
    incoming_phrase: None,
  }
  assert_eq(ctx.chord_at(4.0), c)
}

///|
test "@generator.interval_cost is 0 for unison and minor second" {
  let c4 = @music.MidiNumber::new(60).unwrap()
  let db4 = @music.MidiNumber::new(61).unwrap()
  assert_eq(@generator.interval_cost(c4, c4), 0)
  assert_eq(@generator.interval_cost(c4, db4), 0)
}

///|
test "@generator.interval_cost is 10 for minor third" {
  let c4 = @music.MidiNumber::new(60).unwrap()
  let eb4 = @music.MidiNumber::new(63).unwrap()
  assert_eq(@generator.interval_cost(c4, eb4), 10)
}

///|
test "@generator.interval_cost is 30 for perfect fourth" {
  let c4 = @music.MidiNumber::new(60).unwrap()
  let f4 = @music.MidiNumber::new(65).unwrap()
  assert_eq(@generator.interval_cost(c4, f4), 30)
}

///|
test "@generator.interval_cost is 80 for minor sixth" {
  let c4 = @music.MidiNumber::new(60).unwrap()
  let ab4 = @music.MidiNumber::new(68).unwrap()
  assert_eq(@generator.interval_cost(c4, ab4), 80)
}

///|
test "@generator.interval_cost is symmetric" {
  let c4 = @music.MidiNumber::new(60).unwrap()
  let g4 = @music.MidiNumber::new(67).unwrap()
  assert_eq(@generator.interval_cost(c4, g4), @generator.interval_cost(g4, c4))
}

///|
test "@generator.effective_rest_probability returns base when stamina is 0" {
  // stamina_ratio=0, stamina_scale=1.0, consecutive_scale=1.0 → base
  let result = @generator.effective_rest_probability(50, 0, 100, false)
  assert_eq(result, 50)
}

///|
test "@generator.effective_rest_probability is low when stamina is max" {
  // stamina_ratio=1.0, stamina_scale=0.1, consecutive_scale=1.0 → base * 0.1
  let result = @generator.effective_rest_probability(50, 100, 100, false)
  assert_true(result < 10)
}

///|
test "@generator.effective_rest_probability is reduced after rest" {
  let without_rest = @generator.effective_rest_probability(50, 50, 100, false)
  let after_rest = @generator.effective_rest_probability(50, 50, 100, true)
  assert_true(after_rest < without_rest)
}

///|
test "@generator.effective_rest_probability returns base when stamina_max is 0" {
  let result = @generator.effective_rest_probability(40, 0, 0, false)
  assert_eq(result, 40)
}

///|
test "@generator.filter_by_interval keeps tones within max_interval" {
  let prev = @music.MidiNumber::new(60).unwrap() // C4
  let tones = [
    @music.MidiNumber::new(60).unwrap(), // dist=0
    @music.MidiNumber::new(62).unwrap(), // dist=2
    @music.MidiNumber::new(65).unwrap(), // dist=5
    @music.MidiNumber::new(72).unwrap(), // dist=12
  ]
  let result = @generator.filter_by_interval(tones, prev, 5)
  assert_eq(result.length(), 3)
  assert_true(result.iter().all(fn(t) { prev.distance(t) <= 5 }))
}

///|
test "@generator.filter_by_interval returns closest tone as fallback when all filtered" {
  let prev = @music.MidiNumber::new(60).unwrap() // C4
  let tones = [
    @music.MidiNumber::new(68).unwrap(), // dist=8
    @music.MidiNumber::new(72).unwrap(), // dist=12
  ]
  // max_interval=5 → all filtered → fallback to closest (dist=8)
  let result = @generator.filter_by_interval(tones, prev, 5)
  assert_eq(result.length(), 1)
  assert_eq(result[0].value, 68)
}

///|
test "@generator.filter_by_interval returns empty for empty input" {
  let prev = @music.MidiNumber::new(60).unwrap()
  let result = @generator.filter_by_interval([], prev, 7)
  assert_eq(result.length(), 0)
}
