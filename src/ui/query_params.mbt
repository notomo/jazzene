///|
/// Read a query parameter from the URL
extern "js" fn get_query_param(name : String) -> String? =
  #|(name) => new URLSearchParams(window.location.search).get(name) ?? undefined

///|
/// Set a query parameter in the URL without reloading
extern "js" fn raw_set_query_param(name : String, value : String) -> Unit =
  #|(name, value) => {
  #|  const params = new URLSearchParams(window.location.search)
  #|  params.set(name, value)
  #|  history.replaceState(null, "", "?" + params.toString())
  #|}

///|
/// Delete a query parameter from the URL without reloading
extern "js" fn delete_query_param(name : String) -> Unit =
  #|(name) => {
  #|  const params = new URLSearchParams(window.location.search)
  #|  params.delete(name)
  #|  const qs = params.toString()
  #|  history.replaceState(null, "", qs ? "?" + qs : window.location.pathname)
  #|}

///|
/// Set a query parameter, or delete it if the value matches the default
fn set_query_param(name : String, value : String, default~ : String) -> Unit {
  if value == default {
    delete_query_param(name)
  } else {
    raw_set_query_param(name, value)
  }
}

///|
fn get_initial_int(name : String, default : Int) -> Int {
  match get_query_param(name) {
    Some(value) =>
      match @js_global.parseInt(value) {
        Some(n) => n
        None => default
      }
    None => default
  }
}

// Default values for query parameters

///|
pub let default_bpm : Int = 200

///|
pub let default_seed : Int = 0

///|
pub let default_measures : Int = 8

///|
pub let default_volume : Int = 50

///|
pub let default_loop_a : Int = 1

///|
pub let default_chords : String = "IIm7 | V7 | Imaj7 | IVmaj7"

///|
pub fn get_initial_bpm() -> Int {
  get_initial_int("bpm", default_bpm)
}

///|
pub fn get_initial_seed() -> Int {
  get_initial_int("seed", default_seed)
}

///|
pub fn get_initial_measures() -> Int {
  get_initial_int("measures", default_measures)
}

///|
pub fn get_initial_volume() -> Int {
  get_initial_int("volume", default_volume)
}

///|
pub fn get_initial_view_mode() -> ViewMode {
  match get_query_param("view") {
    Some(value) =>
      ViewMode::from_query_string(value).unwrap_or(ViewMode::Sheet_PianoRoll)
    None => ViewMode::Sheet_PianoRoll
  }
}

///|
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
pub fn get_initial_chords() -> String {
  match get_query_param("chords") {
    Some(value) => value
    None => default_chords
  }
}

///|
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
pub fn get_initial_loop_a_measure() -> Int {
  get_initial_int("loop_a", default_loop_a)
}

///|
pub fn get_initial_loop_b_measure(measure_count : Int) -> Int {
  match get_query_param("loop_b") {
    Some(value) => @js_global.parseInt(value).unwrap_or(measure_count)
    None => measure_count
  }
}
