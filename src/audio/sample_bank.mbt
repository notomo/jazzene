///|
/// Salamander Grand Piano sample bank
/// Loads MP3 samples from /samples/salamander/
/// and provides MIDI-to-sample mapping with pitch shifting

///|
/// Opaque JS Map<string, AudioBuffer> holding decoded samples
#external
type SampleBank

///|
/// Look up a decoded sample by note name (e.g. "A0", "C1", "Ds1", "Fs1")
fn SampleBank::lookup(
  self : SampleBank,
  note_name : String,
) -> @web_audio.AudioBuffer? {
  let result = ffi_sample_bank_get(self, note_name)
  if is_undefined(result) {
    None
  } else {
    Some(result)
  }
}

///|
extern "js" fn ffi_sample_bank_get(
  bank : SampleBank,
  note_name : String,
) -> @web_audio.AudioBuffer =
  #| (bank, name) => bank.get(name)

///|
extern "js" fn is_undefined(buf : @web_audio.AudioBuffer) -> Bool =
  #| (buf) => buf === undefined

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
/// Load all Salamander Grand Piano samples asynchronously.
/// Calls callback with the SampleBank when all samples are loaded.
fn load_sample_bank(
  ctx : @web_audio.AudioContext,
  callback : (SampleBank) -> Unit,
) -> Unit {
  ffi_load_sample_bank(ctx, sample_note_names(), callback)
}

///|
extern "js" fn ffi_load_sample_bank(
  ctx : @web_audio.AudioContext,
  note_names : Array[String],
  callback : (SampleBank) -> Unit,
) -> Unit =
  #| (ctx, noteNames, callback) => {
  #|   const baseUrl = import.meta.env.BASE_URL + "samples/salamander/";
  #|   const bank = new Map();
  #|   let loaded = 0;
  #|   const total = noteNames.length;
  #|   for (const name of noteNames) {
  #|     fetch(baseUrl + name + ".mp3")
  #|       .then(r => r.arrayBuffer())
  #|       .then(buf => ctx.decodeAudioData(buf))
  #|       .then(audioBuffer => {
  #|         bank.set(name, audioBuffer);
  #|         loaded++;
  #|         if (loaded === total) {
  #|           callback(bank);
  #|         }
  #|       })
  #|       .catch(err => {
  #|         console.warn("Failed to load sample: " + name, err);
  #|         loaded++;
  #|         if (loaded === total) {
  #|           callback(bank);
  #|         }
  #|       });
  #|   }
  #| }
