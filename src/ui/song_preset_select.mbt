///|
priv struct SongPreset {
  name : String
  chords : String
  key : String?
  bpm : Int?
  measures : Int?
  time_signature : String?
}

///|
/// Song presets (jazz standards and forms)
let song_presets : Array[SongPreset] = [
  SongPreset::{
    name: "II-V-I",
    chords: "IIm7 | V7 | Imaj7 | Imaj7",
    key: Some("C"),
    bpm: Some(160),
    measures: Some(6),
    time_signature: Some("4/4"),
  },
  SongPreset::{
    name: "Blues",
    chords: "I7 | IV7 | I7 | I7 | IV7 | IV7 | I7 | VIm7 IIm7 | V7 | V7 | I7 V7 | I7",
    key: Some("F"),
    bpm: Some(120),
    measures: Some(14),
    time_signature: Some("4/4"),
  },
  SongPreset::{
    name: "Rhythm Changes A",
    chords: "Imaj7 VIm7 | IIm7 V7 | IIIm7 VIm7 | IIm7 V7",
    key: Some("Bb"),
    bpm: Some(220),
    measures: Some(10),
    time_signature: Some("4/4"),
  },
  SongPreset::{
    name: "Autumn Leaves",
    chords: "IIm7 | V7 | Imaj7 | IVmaj7 | VIIm7b5 | III7 | VIm7 | VIm7",
    key: Some("Bb"),
    bpm: Some(140),
    measures: Some(18),
    time_signature: Some("4/4"),
  },
  SongPreset::{
    name: "Someday My Prince Will Come",
    chords: "Imaj7 | III7 | IVmaj7 | bVI7 | IIm7 | V7 | Imaj7 | V7",
    key: Some("Bb"),
    bpm: Some(180),
    measures: Some(18),
    time_signature: Some("3/4"),
  },
]

///|
extern "js" fn add_click_outside_listener(
  container : @js_dom.Element,
  callback : () -> Unit,
) -> Unit =
  #|(container, callback) => {
  #|  document.addEventListener('click', (e) => {
  #|    if (!container.contains(e.target)) {
  #|      callback();
  #|    }
  #|  });
  #|}

///|
/// Render song preset popup button that updates chord progression, key, BPM, measure count, and time signature
fn song_preset_select(
  raw_chord_progression : @signals.Signal[String],
  key : @signals.Signal[@music.KeySignature],
  bpm : @signals.Signal[Int],
  measure_count : @signals.Signal[Int],
  loop_b_measure : @signals.Signal[Int],
  time_signature : @signals.Signal[@music.TimeSignature],
) -> @luna_dom.DomNode {
  let is_open = @signals.signal(false)
  let on_preset_select : (SongPreset) -> Unit = fn(preset) {
    push_current_state()
    raw_chord_progression.set(preset.chords)
    set_query_param("chords", preset.chords, default=default_chords)
    match preset.key {
      None => ()
      Some(key_str) =>
        @music.ChordRoot::from_string(key_str)
        |> Result::map(fn(root) {
          key.set(@music.KeySignature::from_root(root))
          set_query_param(
            "key",
            root.to_string(),
            default=@music.KeySignature::c_major().root.to_string(),
          )
        })
        |> ignore
    }
    match preset.bpm {
      None => ()
      Some(new_bpm) => {
        bpm.set(new_bpm)
        set_query_param(
          "bpm",
          new_bpm.to_string(),
          default=default_bpm.to_string(),
        )
      }
    }
    match preset.measures {
      None => ()
      Some(new_measures) => {
        let old_measures = measure_count.get()
        measure_count.set(new_measures)
        set_query_param(
          "measures",
          new_measures.to_string(),
          default=default_measures.to_string(),
        )
        if loop_b_measure.get() == old_measures {
          loop_b_measure.set(new_measures)
          set_query_param(
            "loop_b",
            new_measures.to_string(),
            default=new_measures.to_string(),
          )
        }
      }
    }
    match preset.time_signature {
      None => ()
      Some(ts_str) =>
        @music.TimeSignature::from_string(ts_str)
        |> Result::map(fn(ts) {
          time_signature.set(ts)
          set_query_param(
            "time",
            ts.to_string(),
            default=@music.TimeSignature::default().to_string(),
          )
        })
        |> ignore
    }
    is_open.set(false)
  }
  @luna_dom.div(
    class="relative shrink-0",
    ref_=fn(el) { add_click_outside_listener(el, fn() { is_open.set(false) }) },
    [
      @luna_dom.button(
        class="px-2 py-1 bg-slate-700 hover:bg-slate-600 text-white text-xs lg:text-sm rounded-lg border border-slate-600 transition-colors",
        on=@luna_dom.events().click(fn(_) { is_open.update(fn(v) { not(v) }) }),
        [@luna_dom.text("Preset")],
      ),
      @luna_dom.show(fn() { is_open.get() }, fn() {
        @luna_dom.div(
          class="absolute top-full left-0 mt-1 z-50 bg-slate-800 border border-slate-600 rounded-xl p-2 flex flex-wrap gap-2 shadow-xl min-w-max",
          song_presets.map(fn(preset) {
            @luna_dom.button(
              class="px-3 py-1 bg-slate-700 hover:bg-slate-500 text-white text-xs lg:text-sm rounded-full border border-slate-500 transition-colors whitespace-nowrap",
              on=@luna_dom.events().click(fn(_) { on_preset_select(preset) }),
              [@luna_dom.text(preset.name)],
            )
          }),
        )
      }),
    ],
  )
}
