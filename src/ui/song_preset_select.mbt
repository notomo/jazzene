///|
priv struct SongPreset {
  name : String
  chords : String
  key : String?
  bpm : Int?
  measures : Int?
}

///|
/// Song presets (jazz standards and forms)
let song_presets : Array[SongPreset] = [
  SongPreset::{
    name: "Custom",
    chords: "",
    key: None,
    bpm: None,
    measures: None,
  },
  SongPreset::{
    name: "II-V-I",
    chords: "IIm7 | V7 | Imaj7 | Imaj7",
    key: Some("C"),
    bpm: Some(160),
    measures: Some(6),
  },
  SongPreset::{
    name: "Blues",
    chords: "I7 | IV7 | I7 | I7 | IV7 | IV7 | I7 | VIm7 IIm7 | V7 | V7 | I7 V7 | I7",
    key: Some("F"),
    bpm: Some(120),
    measures: Some(14),
  },
  SongPreset::{
    name: "Rhythm Changes A",
    chords: "Imaj7 VIm7 | IIm7 V7 | IIIm7 VIm7 | IIm7 V7",
    key: Some("Bb"),
    bpm: Some(220),
    measures: Some(10),
  },
  SongPreset::{
    name: "Autumn Leaves",
    chords: "IIm7 | V7 | Imaj7 | IVmaj7 | VIIm7b5 | III7 | VIm7 | VIm7",
    key: Some("Bb"),
    bpm: Some(140),
    measures: Some(10),
  },
]

///|
/// Render song preset dropdown that updates chord progression, key, BPM, and measure count
fn song_preset_select(
  raw_chord_progression : @signals.Signal[String],
  key : @signals.Signal[@music.KeySignature],
  bpm : @signals.Signal[Int],
  measure_count : @signals.Signal[Int],
  loop_b_measure : @signals.Signal[Int],
) -> @luna_dom.DomNode {
  let preset_options = song_presets.map(fn(p) { p.name })
  let on_preset_change : (String) -> Unit = fn(name) {
    let preset_opt = song_presets
      .iter()
      .filter_map(fn(p) {
        if p.name == name && p.chords != "" {
          Some(p)
        } else {
          None
        }
      })
      .next()
    match preset_opt {
      None => ()
      Some(preset) => {
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
      }
    }
  }
  @luna_dom.create_element(
    "select",
    [
      (
        "class",
        @luna_dom.AttrValue::Static(
          "shrink-0 px-1 lg:px-2 py-1 lg:py-2 bg-slate-900 text-white text-xs lg:text-sm rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none",
        ),
      ),
      ("aria-label", @luna_dom.AttrValue::Static("song preset")),
      (
        "change",
        @luna_dom.AttrValue::Handler(fn(e) {
          on_preset_change(get_event_target_value(e))
        }),
      ),
    ],
    preset_options.map(fn(name) {
      @luna_dom.create_element(
        "option",
        [("value", @luna_dom.AttrValue::Static(name))],
        [@luna_dom.text(name)],
      )
    }),
  )
}
