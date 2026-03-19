///|
test "ImprovisationConfig::default preserves values when all enabled" {
  let result = ImprovisationConfig::default(
    42,
    techniques=@music.Techniques::default(),
  )
  assert_eq(result.tension_weight_ratio, 25)
  assert_eq(result.chromatic_approach_ornament_probability, 20)
  assert_eq(result.enclosure_ornament_probability, 20)
  assert_eq(result.syncopation_probability, 40)
  assert_eq(result.triplet_probability, 8)
  assert_eq(result.bebop_ornament_probability, 30)
}

///|
test "ImprovisationConfig::default preserves bebop when flag is true" {
  let result = ImprovisationConfig::default(42, techniques={
    ..@music.Techniques::default(),
    bebop_scales: true,
  })
  assert_eq(result.bebop_ornament_probability, 30)
}

///|
test "ImprovisationConfig::default zeros bebop when flag is false" {
  let result = ImprovisationConfig::default(42, techniques={
    ..@music.Techniques::default(),
    bebop_scales: false,
  })
  assert_eq(result.bebop_ornament_probability, 0)
}

///|
test "ImprovisationConfig::default preserves neighbor_ornament_probability when enabled" {
  let result = ImprovisationConfig::default(42, techniques={
    ..@music.Techniques::default(),
    neighbor_tones: true,
  })
  assert_eq(result.neighbor_ornament_probability, 20)
}

///|
test "ImprovisationConfig::default zeros neighbor_ornament_probability when disabled" {
  let result = ImprovisationConfig::default(42, techniques={
    ..@music.Techniques::default(),
    neighbor_tones: false,
  })
  assert_eq(result.neighbor_ornament_probability, 0)
}

///|
test "ImprovisationConfig::default zeros tension when disabled" {
  let result = ImprovisationConfig::default(42, techniques={
    ..@music.Techniques::default(),
    tension_tones: false,
  })
  assert_eq(result.tension_weight_ratio, 0)
}

///|
test "ImprovisationConfig::default zeros approach tones when disabled" {
  let result = ImprovisationConfig::default(42, techniques={
    ..@music.Techniques::default(),
    chromatic_approach: false,
  })
  assert_eq(result.chromatic_approach_ornament_probability, 0)
}

///|
test "ImprovisationConfig::default zeros syncopation when disabled" {
  let result = ImprovisationConfig::default(42, techniques={
    ..@music.Techniques::default(),
    syncopation: false,
  })
  assert_eq(result.syncopation_probability, 0)
}

///|
test "ImprovisationConfig::default zeros triplets when disabled" {
  let result = ImprovisationConfig::default(42, techniques={
    ..@music.Techniques::default(),
    triplets: false,
  })
  assert_eq(result.triplet_probability, 0)
}

///|
test "ImprovisationConfig::default zeros multiple techniques" {
  let result = ImprovisationConfig::default(42, techniques={
    tension_tones: false,
    chromatic_approach: false,
    enclosure: false,
    syncopation: true,
    triplets: true,
    bebop_scales: false,
    neighbor_tones: true,
    sixteenth_runs: false,
  })
  assert_eq(result.tension_weight_ratio, 0)
  assert_eq(result.chromatic_approach_ornament_probability, 0)
  assert_eq(result.enclosure_ornament_probability, 0)
  assert_eq(result.syncopation_probability, 40)
  assert_eq(result.triplet_probability, 8)
}
