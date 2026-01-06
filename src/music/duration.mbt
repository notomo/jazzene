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
/// Implement Compare trait for Duration
pub impl Compare for Duration with compare(self, other) {
  if self.seconds < other.seconds {
    -1
  } else if self.seconds > other.seconds {
    1
  } else {
    0
  }
}

///|
/// Implement Add trait for Duration
pub impl Add for Duration with add(self, other) {
  { seconds: self.seconds + other.seconds }
}
