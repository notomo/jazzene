///|
/// Read a query parameter from the URL
extern "js" fn get_query_param(name : String) -> String? =
  #|(name) => new URLSearchParams(window.location.search).get(name) ?? undefined

///|
/// Set a query parameter in the URL without reloading
extern "js" fn set_query_param(name : String, value : String) -> Unit =
  #|(name, value) => {
  #|  const params = new URLSearchParams(window.location.search)
  #|  params.set(name, value)
  #|  history.replaceState(null, "", "?" + params.toString())
  #|}

///|
/// Read an integer query parameter, returning default if absent or invalid
pub fn get_initial_int(name : String, default : Int) -> Int {
  match get_query_param(name) {
    Some(value) =>
      match @js_global.parseInt(value) {
        Some(n) => n
        None => default
      }
    None => default
  }
}

///|
/// Read the initial display mode from the URL query parameter
pub fn get_initial_display_mode() -> DisplayMode {
  match get_query_param("view") {
    Some(value) =>
      DisplayMode::from_query_string(value).unwrap_or(
        DisplayMode::Sheet_PianoRoll,
      )
    None => DisplayMode::Sheet_PianoRoll
  }
}

///|
/// Read the initial key from the URL query parameter, defaulting to C major
pub fn get_initial_key() -> @music.KeySignature {
  match get_query_param("key") {
    Some(value) =>
      match @music.ChordRoot::from_string(value) {
        Ok(root) => @music.KeySignature::from_root(root)
        Err(_) => @music.KeySignature::c_major()
      }
    None => @music.KeySignature::c_major()
  }
}

///|
/// Read the initial loop enabled state from the URL query parameter
pub fn get_initial_loop_enabled() -> Bool {
  match get_query_param("loop") {
    Some("false") => false
    _ => true
  }
}

///|
/// Read the initial loop A time from the URL query parameter
pub fn get_initial_loop_a_time() -> @music.Duration {
  match get_query_param("loop_a") {
    Some(value) =>
      @music.Duration::parse(value).unwrap_or(
        @music.Duration::from_milliseconds(0.0),
      )
    None => @music.Duration::from_milliseconds(0.0)
  }
}

///|
/// Read the initial loop B time from the URL query parameter
pub fn get_initial_loop_b_time() -> @music.Duration? {
  match get_query_param("loop_b") {
    Some(value) => @music.Duration::parse(value)
    None => None
  }
}
