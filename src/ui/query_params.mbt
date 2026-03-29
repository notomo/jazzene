///|
/// Read a query parameter from the URL
fn get_query_param(name : String) -> String? {
  (try! @js_url.URL::new(@js_location.location().href)).searchParams().get(name)
}

///|
/// Set a query parameter in the URL without reloading
fn raw_set_query_param(name : String, value : String) -> Unit {
  let params = (try! @js_url.URL::new(@js_location.location().href)).searchParams()
  params.set(name, value)
  @js_history.history().replace_state(
    @js.null(),
    "",
    url="?" + params.to_string(),
  )
}

///|
/// Push current URL state to browser history (allows going back)
fn push_current_state() -> Unit {
  @js_history.history().push_state(
    @js.null(),
    "",
    url=@js_location.location().href,
  )
}

///|
/// Delete a query parameter from the URL without reloading
fn delete_query_param(name : String) -> Unit {
  let params = (try! @js_url.URL::new(@js_location.location().href)).searchParams()
  params.delete(name)
  let qs = params.to_string()
  let url = if qs == "" { @js_location.location().pathname } else { "?" + qs }
  @js_history.history().replace_state(@js.null(), "", url~)
}

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
/// Apply a single param change to an existing URLSearchParams object (no replace_state)
fn apply_param(
  params : @js_url.URLSearchParams,
  name : String,
  value : String,
  default~ : String,
) -> Unit {
  if value == default {
    params.delete(name)
  } else {
    params.set(name, value)
  }
}

///|
/// Commit all URL params with a single replace_state call
fn commit_params(params : @js_url.URLSearchParams) -> Unit {
  let qs = params.to_string()
  let url = if qs == "" { @js_location.location().pathname } else { "?" + qs }
  @js_history.history().replace_state(@js.null(), "", url~)
}

///|
fn get_initial_int(name : String, default : Int) -> Int {
  match get_query_param(name) {
    Some(value) => (try? @strconv.parse_int(value)).unwrap_or(default)
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
pub let default_pitch_min : Int = 48

///|
pub let default_pitch_max : Int = 84

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
pub fn get_initial_view_state() -> ViewState {
  match get_query_param("view") {
    Some(value) => ViewState::from_query_string(value)
    None => ViewState::default()
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
    Some(value) => (try? @strconv.parse_int(value)).unwrap_or(measure_count)
    None => measure_count
  }
}

// ── JazzStyle URL serialization ────────────────────────────────────────────

///|
/// Serialize SwingConfig to a short query-string token.
fn swing_to_string(swing : @music.SwingConfig) -> String {
  match swing {
    s if s == @music.SwingConfig::straight() => "straight"
    s if s == @music.SwingConfig::hard_swing() => "hard"
    _ => "triplet"
  }
}

///|
/// Deserialize SwingConfig from a query-string token.
fn swing_from_string(s : String) -> @music.SwingConfig {
  match s {
    "straight" => @music.SwingConfig::straight()
    "hard" => @music.SwingConfig::hard_swing()
    _ => @music.SwingConfig::triplet()
  }
}

///|
/// Serialize Techniques to a comma-separated list of enabled technique names.
fn techniques_to_string(t : @music.Techniques) -> String {
  let names : Array[String] = []
  if t.tension_tones {
    names.push("tension")
  }
  if t.chromatic_approach {
    names.push("chromatic")
  }
  if t.enclosure {
    names.push("enclosure")
  }
  if t.syncopation {
    names.push("syncopation")
  }
  if t.triplets {
    names.push("triplets")
  }
  if t.bebop_scales {
    names.push("bebop")
  }
  if t.neighbor_tones {
    names.push("neighbor")
  }
  if t.sixteenth_runs {
    names.push("sixteenth_runs")
  }
  names.join(",")
}

///|
/// Deserialize Techniques from a comma-separated list of technique names.
fn techniques_from_string(s : String) -> @music.Techniques {
  let parts = s.split(",").to_array()
  let has = fn(name : String) -> Bool { parts.contains(name) }
  @music.Techniques::{
    tension_tones: has("tension"),
    chromatic_approach: has("chromatic"),
    enclosure: has("enclosure"),
    syncopation: has("syncopation"),
    triplets: has("triplets"),
    bebop_scales: has("bebop"),
    neighbor_tones: has("neighbor"),
    sixteenth_runs: has("sixteenth_runs"),
  }
}

///|
/// Serialize MelodyMode to a query-string token.
fn melody_mode_to_string(mode : @music.MelodyMode) -> String {
  match mode {
    @music.On => "on"
    @music.Silent => "silent"
    @music.Off => "off"
  }
}

///|
/// Deserialize MelodyMode from a query-string token.
fn melody_mode_from_string(s : String) -> @music.MelodyMode {
  match s {
    "silent" => @music.Silent
    "off" => @music.Off
    _ => @music.On
  }
}

///|
fn comping_mode_to_string(mode : @music.CompingMode) -> String {
  match mode {
    @music.Off => "off"
    @music.Silent => "silent"
    @music.On => "on"
  }
}

///|
fn comping_mode_from_string(s : String) -> @music.CompingMode {
  match s {
    "off" => @music.Off
    "silent" => @music.Silent
    _ => @music.On
  }
}

///|
fn comping_style_to_string(style : @music.CompingStyle) -> String {
  match style {
    @music.GuideTones => "guide"
    @music.FullVoicing => "full"
    @music.WithTensions => "tensions"
    @music.Imported => "guide" // not URL-persisted; fall back to default
  }
}

///|
fn comping_style_from_string(s : String) -> @music.CompingStyle {
  match s {
    "full" => @music.FullVoicing
    "tensions" => @music.WithTensions
    _ => @music.GuideTones
  }
}

///|
/// Serialize DrumPatternStyle (with enabled flag) to a token.
fn drums_to_string(enabled : Bool, style : @music.DrumPatternStyle) -> String {
  if not(enabled) {
    "off"
  } else {
    match style {
      @music.SwingRide => "sride"
      @music.Brushes => "brush"
      @music.Imported => "sride" // not URL-persisted; fall back to default
    }
  }
}

///|
/// Deserialize DrumPatternStyle from a token. Returns (enabled, style).
fn drums_from_string(s : String) -> (Bool, @music.DrumPatternStyle) {
  match s {
    "off" => (false, @music.SwingRide)
    "brush" => (true, @music.Brushes)
    _ => (true, @music.SwingRide)
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
      @music.Imported => "walking" // not URL-persisted; fall back to default
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
pub fn save_jazz_style(style : @music.JazzStyle) -> Unit {
  let default_style = @music.JazzStyle::default()
  set_query_param(
    "swing",
    swing_to_string(style.swing),
    default=swing_to_string(default_style.swing),
  )
  set_query_param(
    "techniques",
    techniques_to_string(style.techniques),
    default=techniques_to_string(@music.Techniques::default()),
  )
  set_query_param(
    "comping",
    comping_mode_to_string(style.comping_mode),
    default=comping_mode_to_string(default_style.comping_mode),
  )
  set_query_param(
    "comping_style",
    comping_style_to_string(style.comping_style),
    default=comping_style_to_string(default_style.comping_style),
  )
  set_query_param(
    "drums",
    drums_to_string(style.drums_enabled, style.drum_pattern),
    default=drums_to_string(
      default_style.drums_enabled,
      default_style.drum_pattern,
    ),
  )
  set_query_param(
    "bass",
    bass_to_string(style.bass_enabled, style.bass_style),
    default=bass_to_string(default_style.bass_enabled, default_style.bass_style),
  )
  set_query_param(
    "melody",
    melody_mode_to_string(style.melody_mode),
    default=melody_mode_to_string(default_style.melody_mode),
  )
  set_query_param(
    "pitch_min",
    style.pitch_min.to_string(),
    default=default_pitch_min.to_string(),
  )
  set_query_param(
    "pitch_max",
    style.pitch_max.to_string(),
    default=default_pitch_max.to_string(),
  )
}

///|
pub fn get_initial_show_technique_hints() -> Bool {
  match get_query_param("hint") {
    Some("off") => false
    _ => true
  }
}

///|
pub fn save_show_technique_hints(show : Bool) -> Unit {
  set_query_param("hint", if show { "" } else { "off" }, default="")
}

///|
pub fn save_bpm(bpm : Int) -> Unit {
  set_query_param("bpm", bpm.to_string(), default=default_bpm.to_string())
}

///|
pub fn save_seed(seed : Int) -> Unit {
  set_query_param("seed", seed.to_string(), default=default_seed.to_string())
}

///|
pub fn save_measure_count(measures : Int) -> Unit {
  set_query_param(
    "measures",
    measures.to_string(),
    default=default_measures.to_string(),
  )
}

///|
pub fn save_loop_a(value : Int) -> Unit {
  set_query_param(
    "loop_a",
    value.to_string(),
    default=default_loop_a.to_string(),
  )
}

///|
pub fn save_loop_b(value : Int, measure_count : Int) -> Unit {
  set_query_param(
    "loop_b",
    value.to_string(),
    default=measure_count.to_string(),
  )
}

///|
pub fn save_volume(volume : Int) -> Unit {
  set_query_param(
    "volume",
    volume.to_string(),
    default=default_volume.to_string(),
  )
}

///|
pub fn save_key(key : @music.KeySignature) -> Unit {
  set_query_param(
    "key",
    key.root.to_string(),
    default=@music.KeySignature::c_major().root.to_string(),
  )
}

///|
pub fn save_time_signature(ts : @music.TimeSignature) -> Unit {
  set_query_param(
    "time",
    ts.to_string(),
    default=@music.TimeSignature::default().to_string(),
  )
}

///|
pub fn save_chords(chords : String) -> Unit {
  set_query_param("chords", chords, default=default_chords)
}

///|
pub fn save_view_state(vs : ViewState) -> Unit {
  set_query_param("view", vs.to_view_query_string(), default="sheet,pianoroll")
}

///|
/// Save all application state to URL in a single replace_state call.
/// Use this instead of calling individual save_* functions to avoid exceeding
/// the browser's history.replaceState rate limit (100 calls / 10 seconds).
pub fn save_all_state(
  bpm : Int,
  seed : Int,
  measure_count : Int,
  loop_a : Int,
  loop_b : Int,
  volume : Int,
  key : @music.KeySignature,
  ts : @music.TimeSignature,
  chords : String,
  view : ViewState,
  jazz : @music.JazzStyle,
  hints : Bool,
) -> Unit {
  let params = (try! @js_url.URL::new(@js_location.location().href)).searchParams()
  let default_jazz = @music.JazzStyle::default()
  apply_param(params, "bpm", bpm.to_string(), default=default_bpm.to_string())
  apply_param(
    params,
    "seed",
    seed.to_string(),
    default=default_seed.to_string(),
  )
  apply_param(
    params,
    "measures",
    measure_count.to_string(),
    default=default_measures.to_string(),
  )
  apply_param(
    params,
    "loop_a",
    loop_a.to_string(),
    default=default_loop_a.to_string(),
  )
  apply_param(
    params,
    "loop_b",
    loop_b.to_string(),
    default=measure_count.to_string(),
  )
  apply_param(
    params,
    "volume",
    volume.to_string(),
    default=default_volume.to_string(),
  )
  apply_param(
    params,
    "key",
    key.root.to_string(),
    default=@music.KeySignature::c_major().root.to_string(),
  )
  apply_param(
    params,
    "time",
    ts.to_string(),
    default=@music.TimeSignature::default().to_string(),
  )
  apply_param(params, "chords", chords, default=default_chords)
  apply_param(
    params,
    "view",
    view.to_view_query_string(),
    default="sheet,pianoroll",
  )
  apply_param(
    params,
    "swing",
    swing_to_string(jazz.swing),
    default=swing_to_string(default_jazz.swing),
  )
  apply_param(
    params,
    "techniques",
    techniques_to_string(jazz.techniques),
    default=techniques_to_string(@music.Techniques::default()),
  )
  apply_param(
    params,
    "comping",
    comping_mode_to_string(jazz.comping_mode),
    default=comping_mode_to_string(default_jazz.comping_mode),
  )
  apply_param(
    params,
    "comping_style",
    comping_style_to_string(jazz.comping_style),
    default=comping_style_to_string(default_jazz.comping_style),
  )
  apply_param(
    params,
    "drums",
    drums_to_string(jazz.drums_enabled, jazz.drum_pattern),
    default=drums_to_string(
      default_jazz.drums_enabled,
      default_jazz.drum_pattern,
    ),
  )
  apply_param(
    params,
    "bass",
    bass_to_string(jazz.bass_enabled, jazz.bass_style),
    default=bass_to_string(default_jazz.bass_enabled, default_jazz.bass_style),
  )
  apply_param(
    params,
    "melody",
    melody_mode_to_string(jazz.melody_mode),
    default=melody_mode_to_string(default_jazz.melody_mode),
  )
  apply_param(
    params,
    "pitch_min",
    jazz.pitch_min.to_string(),
    default=default_pitch_min.to_string(),
  )
  apply_param(
    params,
    "pitch_max",
    jazz.pitch_max.to_string(),
    default=default_pitch_max.to_string(),
  )
  apply_param(params, "hint", if hints { "" } else { "off" }, default="")
  commit_params(params)
}

///|
/// Load JazzStyle from URL query parameters, falling back to defaults.
pub fn get_initial_jazz_style() -> @music.JazzStyle {
  let default_js = @music.JazzStyle::default()
  let swing = match get_query_param("swing") {
    Some(s) => swing_from_string(s)
    None => default_js.swing
  }
  let techniques = match get_query_param("techniques") {
    Some(s) => techniques_from_string(s)
    None => default_js.techniques
  }
  let comping_mode = match get_query_param("comping") {
    Some(s) => comping_mode_from_string(s)
    None => default_js.comping_mode
  }
  let comping_style = match get_query_param("comping_style") {
    Some(s) => comping_style_from_string(s)
    None => default_js.comping_style
  }
  let (drums_enabled, drum_pattern) = match get_query_param("drums") {
    Some(s) => drums_from_string(s)
    None => (default_js.drums_enabled, default_js.drum_pattern)
  }
  let (bass_enabled, bass_style) = match get_query_param("bass") {
    Some(s) => bass_from_string(s)
    None => (default_js.bass_enabled, default_js.bass_style)
  }
  let melody_mode = match get_query_param("melody") {
    Some(s) => melody_mode_from_string(s)
    None => default_js.melody_mode
  }
  let pitch_min = get_initial_int("pitch_min", default_pitch_min)
  let pitch_max = get_initial_int("pitch_max", default_pitch_max)
  @music.JazzStyle::{
    swing,
    techniques,
    melody_mode,
    comping_mode,
    drums_enabled,
    bass_enabled,
    comping_style,
    drum_pattern,
    bass_style,
    pitch_min,
    pitch_max,
  }
}
