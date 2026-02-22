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

// ── JazzStyle URL serialization ────────────────────────────────────────────

///|
/// Serialize SwingConfig to a short query-string token.
fn swing_to_string(swing : @music.SwingConfig) -> String {
  match swing {
    s if s == @music.SwingConfig::straight() => "straight"
    s if s == @music.SwingConfig::light_swing() => "light"
    s if s == @music.SwingConfig::medium_swing() => "medium"
    s if s == @music.SwingConfig::triplet() => "triplet"
    s if s == @music.SwingConfig::hard_swing() => "hard"
    _ => "triplet"
  }
}

///|
/// Deserialize SwingConfig from a query-string token.
fn swing_from_string(s : String) -> @music.SwingConfig {
  match s {
    "straight" => @music.SwingConfig::straight()
    "light" => @music.SwingConfig::light_swing()
    "medium" => @music.SwingConfig::medium_swing()
    "hard" => @music.SwingConfig::hard_swing()
    _ => @music.SwingConfig::triplet()
  }
}

///|
/// Serialize Techniques to a comma-separated list of enabled technique names.
fn techniques_to_string(t : @generator.Techniques) -> String {
  let names : Array[String] = []
  if t.tension_tones {
    names.push("tension")
  }
  if t.scale_tones {
    names.push("scale")
  }
  if t.approach_tones {
    names.push("approach")
  }
  if t.enclosure_tones {
    names.push("enclosure")
  }
  if t.syncopation {
    names.push("syncopation")
  }
  if t.triplets {
    names.push("triplets")
  }
  if t.motif_reuse {
    names.push("motif")
  }
  if t.bebop_scales {
    names.push("bebop")
  }
  names.join(",")
}

///|
/// Deserialize Techniques from a comma-separated list of technique names.
fn techniques_from_string(s : String) -> @generator.Techniques {
  let parts = s.split(",").to_array()
  let has = fn(name : String) -> Bool { parts.contains(name) }
  @generator.Techniques::{
    tension_tones: has("tension"),
    scale_tones: has("scale"),
    approach_tones: has("approach"),
    enclosure_tones: has("enclosure"),
    syncopation: has("syncopation"),
    triplets: has("triplets"),
    motif_reuse: has("motif"),
    bebop_scales: has("bebop"),
  }
}

///|
/// Default techniques string (all enabled except bebop).
let default_techniques_str : String = "tension,scale,approach,enclosure,syncopation,triplets,motif"

///|
/// Serialize CompingStyle (with enabled flag) to a token.
/// "off" means disabled; otherwise the voicing style name.
fn comping_to_string(enabled : Bool, style : @music.CompingStyle) -> String {
  if not(enabled) {
    "off"
  } else {
    match style {
      @music.GuideTones => "guide"
      @music.FullVoicing => "full"
    }
  }
}

///|
/// Deserialize CompingStyle from a token. Returns (enabled, style).
fn comping_from_string(s : String) -> (Bool, @music.CompingStyle) {
  match s {
    "off" => (false, @music.GuideTones)
    "full" => (true, @music.FullVoicing)
    _ => (true, @music.GuideTones)
  }
}

///|
/// Serialize DrumPatternStyle (with enabled flag) to a token.
fn drums_to_string(enabled : Bool, style : @music.DrumPatternStyle) -> String {
  if not(enabled) {
    "off"
  } else {
    match style {
      @music.Basic => "basic"
      @music.SwingRide => "sride"
      @music.BossaNova => "bossa"
      @music.Brushes => "brush"
    }
  }
}

///|
/// Deserialize DrumPatternStyle from a token. Returns (enabled, style).
fn drums_from_string(s : String) -> (Bool, @music.DrumPatternStyle) {
  match s {
    "off" => (false, @music.Basic)
    "sride" => (true, @music.SwingRide)
    "bossa" => (true, @music.BossaNova)
    "brush" => (true, @music.Brushes)
    _ => (true, @music.Basic)
  }
}

///|
/// Serialize BassStyle (with enabled flag) to a token.
fn bass_to_string(enabled : Bool, style : @music.BassStyle) -> String {
  if not(enabled) {
    "off"
  } else {
    match style {
      @music.RootOnly => "root"
      @music.RootFifth => "root5"
      @music.WalkingBass => "walking"
    }
  }
}

///|
/// Deserialize BassStyle from a token. Returns (enabled, style).
fn bass_from_string(s : String) -> (Bool, @music.BassStyle) {
  match s {
    "off" => (false, @music.WalkingBass)
    "root" => (true, @music.RootOnly)
    "root5" => (true, @music.RootFifth)
    _ => (true, @music.WalkingBass)
  }
}

///|
/// Save JazzStyle to URL query parameters, omitting defaults.
pub fn save_jazz_style(js : JazzStyle) -> Unit {
  let default_js = JazzStyle::default()
  set_query_param(
    "swing",
    swing_to_string(js.swing),
    default=swing_to_string(default_js.swing),
  )
  set_query_param(
    "techniques",
    techniques_to_string(js.techniques),
    default=default_techniques_str,
  )
  set_query_param(
    "comping",
    comping_to_string(js.comping_enabled, js.comping_style),
    default=comping_to_string(
      default_js.comping_enabled,
      default_js.comping_style,
    ),
  )
  set_query_param(
    "drums",
    drums_to_string(js.drums_enabled, js.drum_pattern),
    default=drums_to_string(default_js.drums_enabled, default_js.drum_pattern),
  )
  set_query_param(
    "bass",
    bass_to_string(js.bass_enabled, js.bass_style),
    default=bass_to_string(default_js.bass_enabled, default_js.bass_style),
  )
}

///|
/// Load JazzStyle from URL query parameters, falling back to defaults.
pub fn get_initial_jazz_style() -> JazzStyle {
  let default_js = JazzStyle::default()
  let swing = match get_query_param("swing") {
    Some(s) => swing_from_string(s)
    None => default_js.swing
  }
  let techniques = match get_query_param("techniques") {
    Some(s) => techniques_from_string(s)
    None => default_js.techniques
  }
  let (comping_enabled, comping_style) = match get_query_param("comping") {
    Some(s) => comping_from_string(s)
    None => (default_js.comping_enabled, default_js.comping_style)
  }
  let (drums_enabled, drum_pattern) = match get_query_param("drums") {
    Some(s) => drums_from_string(s)
    None => (default_js.drums_enabled, default_js.drum_pattern)
  }
  let (bass_enabled, bass_style) = match get_query_param("bass") {
    Some(s) => bass_from_string(s)
    None => (default_js.bass_enabled, default_js.bass_style)
  }
  JazzStyle::{
    swing,
    techniques,
    comping_enabled,
    drums_enabled,
    bass_enabled,
    comping_style,
    drum_pattern,
    bass_style,
  }
}
