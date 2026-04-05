///|
fn add_click_outside_listener(
  container : @js_dom.Element,
  callback : () -> Unit,
) -> Unit {
  @js_dom.document()
  .as_event_target()
  .addEventListener("click", fn(e) {
    if !container.as_any()._call("contains", [e._get("target")]).cast() {
      callback()
    }
  })
}

///|
/// Render song preset popup button that updates chord progression, key, BPM, measure count, time signature, and resets jazz style to default
fn song_preset_select(
  degree_measures : @signals.Signal[Array[@music.DegreeMeasure]],
  key : @signals.Signal[@music.KeySignature],
  bpm : @signals.Signal[Int],
  measure_count : @signals.Signal[Int],
  loop_b_measure : @signals.Signal[Int],
  time_signature : @signals.Signal[@music.TimeSignature],
  jazz_style : @signals.Signal[@music.JazzStyle],
) -> @luna_dom.DomNode {
  let is_open = @signals.signal(false)
  let on_preset_select : (@music.SongPreset) -> Unit = fn(preset) {
    push_current_state()
    jazz_style.set(@music.JazzStyle::default())
    degree_measures.set(
      @music.parse_measure_progression(preset.chords).unwrap_or([]),
    )
    match preset.key {
      None => ()
      Some(root) => key.set(@music.KeySignature::from_root(root))
    }
    match preset.bpm {
      None => ()
      Some(new_bpm) => bpm.set(new_bpm)
    }
    match preset.measures {
      None => ()
      Some(new_measures) => {
        let old_measures = measure_count.get()
        measure_count.set(new_measures)
        if loop_b_measure.get() == old_measures {
          loop_b_measure.set(new_measures)
        }
      }
    }
    match preset.time_signature {
      None => ()
      Some(ts) => time_signature.set(ts)
    }
    is_open.set(false)
  }
  @luna_dom.div(
    class="relative shrink-0",
    ref_=fn(el) { add_click_outside_listener(el, fn() { is_open.set(false) }) },
    [
      @luna_dom.button(
        class="px-2 py-1 bg-slate-700 hover:bg-slate-600 text-white text-xs lg:text-sm rounded-lg border border-slate-600 transition-colors",
        on=@luna_dom.events().click(fn(_) { is_open.update(fn(v) { !v }) }),
        [@luna_dom.text("Preset")],
      ),
      @luna_dom.show(fn() { is_open.get() }, fn() {
        @luna_dom.div(
          class="absolute top-full left-0 mt-1 z-50 bg-slate-800 border border-slate-600 rounded-xl p-2 flex flex-wrap gap-2 shadow-xl min-w-max",
          @music.song_presets.map(fn(preset) {
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
