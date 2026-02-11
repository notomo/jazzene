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
/// Read the initial view mode from the URL query parameter
pub fn get_initial_view_mode() -> ViewMode {
  match get_query_param("view") {
    Some(value) =>
      ViewMode::from_query_string(value).unwrap_or(ViewMode::Sheet_PianoRoll)
    None => ViewMode::Sheet_PianoRoll
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
/// Read the initial chord progression from the URL query parameter
pub fn get_initial_chords() -> String {
  match get_query_param("chords") {
    Some(value) => value
    None => "IIm7 | V7 | Imaj7 | IVmaj7"
  }
}

///|
/// Read the initial time signature from the URL query parameter, defaulting to 4/4
pub fn get_initial_time_signature() -> @music.TimeSignature {
  match get_query_param("time") {
    Some(value) =>
      match @music.TimeSignature::from_string(value) {
        Ok(ts) => ts
        Err(_) => @music.TimeSignature::default()
      }
    None => @music.TimeSignature::default()
  }
}

///|
/// Read the initial loop A measure from the URL query parameter (1-based)
pub fn get_initial_loop_a_measure() -> Int {
  get_initial_int("loop_a", 1)
}

///|
/// Read the initial loop B measure from the URL query parameter (1-based)
pub fn get_initial_loop_b_measure() -> Int? {
  match get_query_param("loop_b") {
    Some(value) => @js_global.parseInt(value)
    None => None
  }
}
