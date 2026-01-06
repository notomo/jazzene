///|
/// Duration type that stores time as seconds (Double)
pub struct Duration {
  seconds : Double
} derive(Eq, Show)

///|
/// Create a Duration from seconds (as Double)
pub fn Duration::from_seconds(seconds : Double) -> Duration {
  { seconds, }
}

///|
/// Convert Duration to seconds (as Double)
/// This is useful for Web Audio API which expects time in seconds
pub fn Duration::to_seconds(self : Duration) -> Double {
  self.seconds
}

///|
/// Add two durations
pub fn Duration::op_add(self : Duration, other : Duration) -> Duration {
  { seconds: self.seconds + other.seconds }
}

///|
/// Compare durations
pub fn Duration::op_equal(self : Duration, other : Duration) -> Bool {
  self.seconds == other.seconds
}
