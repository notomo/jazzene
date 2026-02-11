///|
/// Duration type that stores time as seconds (Double)
pub struct Duration {
  seconds : Double
} derive(Eq, Show)

///|
/// Create a Duration from milliseconds (as Double)
pub fn Duration::from_milliseconds(milliseconds : Double) -> Duration {
  { seconds: milliseconds / 1000.0 }
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
/// Convert Duration to milliseconds (as Double)
pub fn Duration::to_milliseconds(self : Duration) -> Double {
  self.seconds * 1000.0
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

///|
/// Implement Sub trait for Duration
pub impl Sub for Duration with sub(self, other) {
  { seconds: self.seconds - other.seconds }
}

///|
/// Format Duration as "M:SS"
pub fn Duration::format(self : Duration) -> String {
  let total_seconds = self.seconds.to_int()
  let minutes = total_seconds / 60
  let secs = total_seconds % 60

  minutes.to_string() +
  ":" +
  (if secs < 10 { "0" } else { "" }) +
  secs.to_string()
}

///|
/// Parse "M:SS" format to Duration
/// Returns None if format is invalid
pub fn Duration::parse(input : String) -> Duration? {
  let parts = input.split(":").to_array()
  if parts.length() != 2 {
    return None
  }

  try {
    let minutes = @strconv.parse_int(parts[0])
    let seconds = @strconv.parse_int(parts[1])
    if minutes >= 0 && seconds >= 0 && seconds < 60 {
      let total_ms = (minutes * 60 + seconds).to_double() * 1000.0
      Some(Duration::from_milliseconds(total_ms))
    } else {
      None
    }
  } catch {
    _ => None
  }
}
