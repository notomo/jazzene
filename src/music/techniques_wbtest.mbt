///|
test "Techniques::default enables standard techniques, bebop disabled by default" {
  let t = Techniques::default()
  assert_true(t.tension_tones)
  assert_true(t.chromatic_approach)
  assert_true(t.enclosure)
  assert_true(t.syncopation)
  assert_true(t.triplets)
  // bebop_scales is enabled by default
  assert_true(t.bebop_scales)
  // neighbor_tones enabled by default
  assert_true(t.neighbor_tones)
}
