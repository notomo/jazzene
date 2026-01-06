///|
/// Duration type that stores time as seconds (Double)
pub struct Duration {
  seconds : Double
} derive(Eq, Show)

///|
/// Create a Duration from milliseconds (as Int)
pub fn Duration::from_milliseconds(milliseconds : Int) -> Duration {
  { seconds: milliseconds.to_double() / 1000.0 }
}

///|
/// Create a Duration from seconds (as Double)
/// This is useful for Web Audio API which provides time in seconds
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
/// Convert Duration to milliseconds (as Int)
pub fn Duration::to_milliseconds(self : Duration) -> Int {
  (self.seconds * 1000.0).to_int()
}

///|
/// Add two durations
pub fn Duration::op_add(self : Duration, other : Duration) -> Duration {
  { seconds: self.seconds + other.seconds }
}

///|
/// Compare durations for equality
pub fn Duration::op_equal(self : Duration, other : Duration) -> Bool {
  self.seconds == other.seconds
}

///|
/// Compare two durations
/// Returns: zero if equal, negative if self < other, positive if self > other
pub fn Duration::compare(self : Duration, other : Duration) -> Int {
  if self.seconds < other.seconds {
    -1
  } else if self.seconds > other.seconds {
    1
  } else {
    0
  }
}

///|
/// Implement Compare trait for Duration
pub impl Compare for Duration with compare(self, other) {
  self.compare(other)
}

///|
/// Implement Add trait for Duration
pub impl Add for Duration with add(self, other) {
  self.op_add(other)
}
