///|
/// Salamander Grand Piano sample bank
/// Loads MP3 samples from /samples/salamander/
/// and provides MIDI-to-sample mapping with pitch shifting

///|
/// Map from note name (e.g. "A0", "C1") to decoded AudioBuffer
type SampleBank = Map[String, @web_audio.AudioBuffer]

///|
/// Vite base URL for resolving sample paths
extern "js" fn ffi_base_url() -> String =
  #| () => import.meta.env.BASE_URL

///|
/// Fetch response body as ArrayBuffer (JS native)
extern "js" fn ffi_response_array_buffer(
  response : @http.Response,
) -> @js.Promise[@js.Any] =
  #| (r) => r.arrayBuffer()

///|
/// Sample info: which sample to use and how many cents to detune
priv struct SampleInfo {
  note_name : String
  detune_cents : Double
}

///|
/// Sampled MIDI numbers (minor thirds): A, C, Ds, Fs per octave
/// A0=21, C1=24, Ds1=27, Fs1=30, A1=33, C2=36, ... C8=108
let sampled_midis : Array[(Int, String)] = [
  (21, "A0"),
  (24, "C1"),
  (27, "Ds1"),
  (30, "Fs1"),
  (33, "A1"),
  (36, "C2"),
  (39, "Ds2"),
  (42, "Fs2"),
  (45, "A2"),
  (48, "C3"),
  (51, "Ds3"),
  (54, "Fs3"),
  (57, "A3"),
  (60, "C4"),
  (63, "Ds4"),
  (66, "Fs4"),
  (69, "A4"),
  (72, "C5"),
  (75, "Ds5"),
  (78, "Fs5"),
  (81, "A5"),
  (84, "C6"),
  (87, "Ds6"),
  (90, "Fs6"),
  (93, "A6"),
  (96, "C7"),
  (99, "Ds7"),
  (102, "Fs7"),
  (105, "A7"),
  (108, "C8"),
]

///|
/// Get all sample note names for loading
fn sample_note_names() -> Array[String] {
  sampled_midis.map(fn(pair) { pair.1 })
}

///|
/// Map a MIDI number to the nearest sample and detune in cents
fn midi_to_sample_info(midi_value : Int) -> SampleInfo {
  let mut best_name = "C4"
  let mut best_distance = 1000
  for pair in sampled_midis {
    let distance = (midi_value - pair.0).abs()
    if distance < best_distance {
      best_distance = distance
      best_name = pair.1
      if distance == 0 {
        break
      }
    }
  }

  // Find the MIDI number of the best match to calculate detune
  let mut best_midi = 60
  for pair in sampled_midis {
    if pair.1 == best_name {
      best_midi = pair.0
      break
    }
  }

  let detune_cents = (midi_value - best_midi).to_double() * 100.0
  { note_name: best_name, detune_cents }
}

///|
/// Fetch and decode a single sample, returning None on any error
async fn load_one_sample(
  ctx : @web_audio.AudioContext,
  note_name : String,
) -> @web_audio.AudioBuffer? {
  let url = ffi_base_url() + "samples/salamander/" + note_name + ".mp3"
  let response = @http.fetch(url, method_="GET") catch { _ => return None }
  let array_buf = ffi_response_array_buffer(response).wait() catch {
    _ => return None
  }
  let audio_buf = ctx.decode_audio_data(array_buf) catch { _ => return None }
  Some(audio_buf)
}

///|
/// Load all Salamander Grand Piano samples asynchronously.
/// All samples are fetched in parallel; failed samples are silently skipped.
async fn load_sample_bank(ctx : @web_audio.AudioContext) -> SampleBank {
  let bank : Map[String, @web_audio.AudioBuffer] = {}
  let promises = sample_note_names().map(fn(name) {
    @js.from_async(async fn() {
      let buf = load_one_sample(ctx, name)
      match buf {
        Some(b) => bank[name] = b
        None => ()
      }
    })
  })
  ignore(@js.Promise::all(promises).wait()) catch {
    _ => ()
  }
  bank
}
