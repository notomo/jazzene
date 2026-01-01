///|
/// Render playback controls (play/pause, volume, tempo)
pub fn render_controls(
  on_play_pause : () -> Unit,
  is_playing : @signal.Signal[Bool],
  volume : @signal.Signal[Double],
  is_muted : @signal.Signal[Bool],
  tempo : @signal.Signal[Int],
) -> @dom.DomNode {
  // Volume popup state
  let show_volume_popup = @signal.signal(false)

  // Event handlers
  let on_volume_change : @dom.InputHandler = fn(e) {
    let target = e.target()
    let event_target = target.as_event_target()
    let value = event_target.as_any()._get("value").to_string()
    match @js_global.parseFloat(value) {
      Some(percent) => volume.set(percent / 100.0)
      None => ()
    }
  }
  let on_tempo_change : @dom.InputHandler = fn(e) {
    let target = e.target()
    let event_target = target.as_event_target()
    let value = event_target.as_any()._get("value").to_string()
    match @js_global.parseInt(value) {
      Some(bpm) => if bpm >= 30 && bpm <= 300 { tempo.set(bpm) }
      None => ()
    }
  }
  @dom.div(class="flex gap-4 items-center", [
    // Play/Pause button
    @dom.button(
      dyn_class=fn() {
        if is_playing.get() {
          "px-8 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
        } else {
          "px-8 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
        }
      },
      on=@dom.events().click(fn(_) { on_play_pause() }),
      [@dom.text_dyn(fn() { if is_playing.get() { "Stop" } else { "Play" } })],
    ),

    // Volume control with popup
    @dom.div(class="relative", [
      @dom.button(
        class="p-3 bg-slate-700 hover:bg-slate-600 rounded-lg transition-colors shadow-lg",
        on=@dom.events().click(fn(_) { show_volume_popup.update(fn(v) { !v }) }),
        attrs=[("aria-label", @dom.Attr::AttrString("Volume control"))],
        [@dom.text_dyn(fn() { if is_muted.get() { "🔇" } else { "🔊" } })],
      ),
      // Volume popup (vertical slider)
      @dom.div(
        dyn_class=fn() {
          if show_volume_popup.get() {
            "absolute bottom-full left-1/2 -translate-x-1/2 mb-2 bg-slate-800 p-3 rounded-lg shadow-xl border border-slate-600"
          } else {
            "hidden"
          }
        },
        [
          @dom.input(
            type_="range",
            class="h-32 w-12 accent-blue-500 cursor-pointer",
            attrs=[
              ("min", @dom.Attr::AttrInt(0)),
              ("max", @dom.Attr::AttrInt(100)),
              ("step", @dom.Attr::AttrInt(1)),
              ("orient", @dom.Attr::AttrString("vertical")),
              ("aria-label", @dom.Attr::AttrString("Volume")),
            ],
            dyn_value=fn() { (volume.get() * 100.0).to_int().to_string() },
            on=@dom.events().input(on_volume_change),
          ),
        ],
      ),
    ]),

    // Mute toggle button
    @dom.button(
      dyn_class=fn() {
        if is_muted.get() {
          "px-4 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-colors shadow-lg"
        } else {
          "px-4 py-3 bg-slate-700 hover:bg-slate-600 text-white rounded-lg font-semibold transition-colors shadow-lg"
        }
      },
      on=@dom.events().click(fn(_) { is_muted.update(fn(x) { !x }) }),
      [@dom.text_dyn(fn() { if is_muted.get() { "Unmute" } else { "Mute" } })],
    ),

    // Tempo input
    @dom.div(class="flex items-center gap-2", [
      @dom.label(class="text-sm text-slate-400", [@dom.text("BPM:")]),
      @dom.input(
        type_="number",
        class="w-20 px-3 py-2 bg-slate-900 text-white rounded-lg border border-slate-600 focus:border-blue-500 focus:outline-none text-center",
        attrs=[
          ("min", @dom.Attr::AttrInt(30)),
          ("max", @dom.Attr::AttrInt(300)),
        ],
        dyn_value=fn() { tempo.get().to_string() },
        on=@dom.events().input(on_tempo_change),
      ),
    ]),
  ])
}
