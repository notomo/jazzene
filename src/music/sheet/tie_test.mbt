///|
test "compute_tie_arcs - None returns empty" {
  let key = @music.KeySignature::from_root(@music.C)
  let arcs = compute_tie_arcs(None, 100.0, 60, 50.0, 0.0, key, None, None)
  inspect(arcs.length(), content="0")
}

///|
test "compute_tie_arcs - TieStart with next_note_x" {
  let key = @music.KeySignature::from_root(@music.C)
  let arcs = compute_tie_arcs(
    Some(TieStart),
    100.0,
    60,
    50.0,
    0.0,
    key,
    None,
    Some(200.0),
  )
  inspect(arcs.length(), content="1")
  inspect(arcs[0].start_x, content="100")
  inspect(arcs[0].end_x, content="200")
}

///|
test "compute_tie_arcs - TieStart without next_note_x falls back to measure end" {
  let key = @music.KeySignature::from_root(@music.C)
  let measure_x = 80.0
  let arcs = compute_tie_arcs(
    Some(TieStart),
    100.0,
    60,
    50.0,
    measure_x,
    key,
    None,
    None,
  )
  inspect(arcs.length(), content="1")
  inspect(arcs[0].start_x, content="100")
  inspect(arcs[0].end_x, content="400") // measure_x + MIN_MEASURE_WIDTH
}

///|
test "compute_tie_arcs - TieEnd with prev_note_x" {
  let key = @music.KeySignature::from_root(@music.C)
  let arcs = compute_tie_arcs(
    Some(TieEnd),
    200.0,
    60,
    50.0,
    0.0,
    key,
    Some(50.0),
    None,
  )
  inspect(arcs.length(), content="1")
  inspect(arcs[0].start_x, content="50")
  inspect(arcs[0].end_x, content="200")
}

///|
test "compute_tie_arcs - TieEnd without prev_note_x falls back to measure start" {
  let key = @music.KeySignature::from_root(@music.C)
  let measure_x = 80.0
  let arcs = compute_tie_arcs(
    Some(TieEnd),
    200.0,
    60,
    50.0,
    measure_x,
    key,
    None,
    None,
  )
  inspect(arcs.length(), content="1")
  inspect(arcs[0].start_x, content="80") // measure_x
  inspect(arcs[0].end_x, content="200")
}

///|
test "compute_tie_arcs - TieBoth produces two arcs" {
  let key = @music.KeySignature::from_root(@music.C)
  let arcs = compute_tie_arcs(
    Some(TieBoth),
    150.0,
    60,
    50.0,
    0.0,
    key,
    Some(50.0),
    Some(250.0),
  )
  inspect(arcs.length(), content="2")
  // First arc: prev -> current
  inspect(arcs[0].start_x, content="50")
  inspect(arcs[0].end_x, content="150")
  // Second arc: current -> next
  inspect(arcs[1].start_x, content="150")
  inspect(arcs[1].end_x, content="250")
}

///|
test "compute_tie_arcs - TieBoth without neighbors falls back to measure bounds" {
  let key = @music.KeySignature::from_root(@music.C)
  let measure_x = 80.0
  let arcs = compute_tie_arcs(
    Some(TieBoth),
    150.0,
    60,
    50.0,
    measure_x,
    key,
    None,
    None,
  )
  inspect(arcs.length(), content="2")
  inspect(arcs[0].start_x, content="80") // measure_x
  inspect(arcs[0].end_x, content="150")
  inspect(arcs[1].start_x, content="150")
  inspect(arcs[1].end_x, content="400") // measure_x + MIN_MEASURE_WIDTH
}

///|
test "compute_tie_arcs - stem_up for low midi" {
  let key = @music.KeySignature::from_root(@music.C)
  let arcs = compute_tie_arcs(
    Some(TieStart),
    100.0,
    60,
    50.0,
    0.0,
    key,
    None,
    Some(200.0),
  )
  inspect(arcs[0].stem_up, content="true") // midi 60 < 71
}

///|
test "compute_tie_arcs - stem_down for high midi" {
  let key = @music.KeySignature::from_root(@music.C)
  let arcs = compute_tie_arcs(
    Some(TieStart),
    100.0,
    80,
    50.0,
    0.0,
    key,
    None,
    Some(200.0),
  )
  inspect(arcs[0].stem_up, content="false") // midi 80 >= 71
}
