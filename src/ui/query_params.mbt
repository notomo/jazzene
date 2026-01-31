///|
/// Read a query parameter from the URL
extern "js" fn get_query_param(name : String) -> String? =
  #|(name) => new URLSearchParams(window.location.search).get(name)

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
