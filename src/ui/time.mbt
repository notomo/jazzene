///|
/// Format milliseconds as "M:SS"
fn format_time(ms : Double) -> String {
  let total_seconds = (ms / 1000.0).to_int()
  let minutes = total_seconds / 60
  let seconds = total_seconds % 60
  minutes.to_string() +
  ":" +
  (if seconds < 10 { "0" } else { "" }) +
  seconds.to_string()
}

///|
/// Parse "M:SS" format to Duration
/// Returns None if format is invalid
fn parse_time(input : String) -> @music.Duration? {
  let parts = input.split(":").to_array()
  if parts.length() != 2 {
    return None
  }
  match
    (
      @js_global.parseInt(parts[0].to_string()),
      @js_global.parseInt(parts[1].to_string()),
    ) {
    (Some(minutes), Some(seconds)) => {
      if seconds < 0 || seconds >= 60 || minutes < 0 {
        return None
      }
      let total_ms = (minutes * 60 + seconds).to_double() * 1000.0
      Some(@music.Duration::from_milliseconds(total_ms))
    }
    _ => None
  }
}
