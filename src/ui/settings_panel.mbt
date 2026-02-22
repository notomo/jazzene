///|
/// Settings panel for jazz style configuration.
/// Contains controls for swing, melody techniques, comping, bass, and drums.

///|
/// Segmented button control: renders a row of option buttons where one is active.
fn[T : Eq] segmented_buttons(
  options : Array[(String, T)],
  current : () -> T,
  on_select : (T) -> Unit,
) -> @luna_dom.DomNode {
  let base = "px-2 py-0.5 text-xs border-y border-r first:border-l first:rounded-l last:rounded-r transition-colors"
  let active = "bg-blue-800 border-blue-500 text-white"
  let inactive = "bg-slate-900 border-slate-600 text-slate-300 hover:bg-slate-700"
  @luna_dom.div(
    class="flex",
    options.map(fn(pair) {
      let (label, value) = pair
      @luna_dom.button(
        dyn_class=fn() {
          cn([base, if current() == value { active } else { inactive }])
        },
        on=@luna_dom.events().click(fn(_) { on_select(value) }),
        [@luna_dom.text(label)],
      )
    }),
  )
}

///|
/// Toggle switch for a boolean setting.
fn toggle_switch(
  label~ : String,
  value~ : () -> Bool,
  on_toggle~ : () -> Unit,
) -> @luna_dom.DomNode {
  @luna_dom.label(class="flex items-center gap-1.5 cursor-pointer", [
    @luna_dom.div(
      dyn_class=fn() {
        cn([
          "relative w-7 h-4 rounded-full transition-colors shrink-0",
          if value() {
            "bg-blue-600"
          } else {
            "bg-slate-600"
          },
        ])
      },
      [
        @luna_dom.div(
          dyn_class=fn() {
            cn([
              "absolute top-0.5 w-3 h-3 rounded-full bg-white transition-transform",
              if value() {
                "translate-x-3.5"
              } else {
                "translate-x-0.5"
              },
            ])
          },
          [],
        ),
        @luna_dom.create_element(
          "input",
          [
            ("type", @luna_dom.AttrValue::Static("checkbox")),
            ("class", @luna_dom.AttrValue::Static("sr-only")),
            (
              "checked",
              @luna_dom.AttrValue::Dynamic(fn() { value().to_string() }),
            ),
            ("change", @luna_dom.AttrValue::Handler(fn(_) { on_toggle() })),
          ],
          [],
        ),
      ],
    ),
    @luna_dom.span(class="text-xs text-slate-300", [@luna_dom.text(label)]),
  ])
}

///|
/// Section header inside the settings panel.
fn settings_section(
  title : String,
  children : Array[@luna_dom.DomNode],
) -> @luna_dom.DomNode {
  @luna_dom.div(class="flex flex-col gap-1.5", [
    @luna_dom.div(
      class="text-xs font-semibold text-slate-400 uppercase tracking-wide",
      [@luna_dom.text(title)],
    ),
    @luna_dom.div(class="flex flex-col gap-1", children),
  ])
}

///|
let swing_options : Array[(String, @music.SwingConfig)] = [
  ("Off", @music.SwingConfig::straight()),
  ("Light", @music.SwingConfig::light_swing()),
  ("Med", @music.SwingConfig::medium_swing()),
  ("Triplet", @music.SwingConfig::triplet()),
  ("Hard", @music.SwingConfig::hard_swing()),
]

///|
let comping_style_options : Array[(String, @music.CompingStyle)] = [
  ("Guide Tones", @music.GuideTones),
  ("Full", @music.FullVoicing),
]

///|
let drum_pattern_options : Array[(String, @music.DrumPatternStyle)] = [
  ("Basic", @music.Basic),
  ("Swing Ride", @music.SwingRide),
  ("Bossa Nova", @music.BossaNova),
  ("Brushes", @music.Brushes),
]

///|
let bass_style_options : Array[(String, @music.BassStyle)] = [
  ("Root", @music.RootOnly),
  ("Root+5th", @music.RootFifth),
  ("Walking", @music.WalkingBass),
]

///|
fn technique_toggle(
  label : String,
  value~ : () -> Bool,
  on_toggle~ : () -> Unit,
) -> @luna_dom.DomNode {
  toggle_switch(label~, value~, on_toggle~)
}

///|
/// Render the settings panel with jazz style controls.
pub fn settings_panel(
  jazz_style : @signals.Signal[JazzStyle],
) -> @luna_dom.DomNode {
  let panel_visible = @signals.signal(false)

  @luna_dom.div(class="relative", [
    @luna_dom.button(
      dyn_class=fn() {
        cn([
          "px-2 py-1 text-xs rounded border transition-colors",
          if panel_visible.get() {
            "bg-blue-900 border-blue-500 text-white"
          } else {
            "bg-slate-800 border-slate-600 text-slate-300 hover:border-slate-400"
          },
        ])
      },
      attrs=[("title", @luna_dom.Attr::AttrString("Jazz Settings"))],
      on=@luna_dom.events().click(fn(_) {
        panel_visible.update(fn(v) { not(v) })
      }),
      [@luna_dom.text("Jazz")],
    ),
    @luna_dom.show(fn() { panel_visible.get() }, fn() {
      @luna_dom.fragment([
        @luna_dom.div(
          class="fixed inset-0 z-[9]",
          on=@luna_dom.events().click(fn(_) { panel_visible.set(false) }),
          [],
        ),
        @luna_dom.div(
          class="absolute bottom-full right-0 mb-1 bg-slate-800 border border-slate-600 rounded-lg p-3 z-10 shadow-xl w-64 max-h-[80vh] overflow-y-auto flex flex-col gap-3",
          attrs=[
            ("aria-label", @luna_dom.Attr::AttrString("jazz settings panel")),
          ],
          [
            // Presets
            settings_section("Preset", [
              @luna_dom.div(
                class="flex flex-wrap gap-1",
                presets.map(fn(pair) {
                  let (label, make_preset) = pair
                  @luna_dom.button(
                    class="px-2 py-0.5 text-xs rounded border bg-slate-900 border-slate-600 text-slate-300 hover:bg-slate-700 hover:border-slate-400 transition-colors",
                    on=@luna_dom.events().click(fn(_) {
                      jazz_style.set(make_preset())
                    }),
                    [@luna_dom.text(label)],
                  )
                }),
              ),
            ]),
            // Swing
            settings_section("Swing", [
              segmented_buttons(
                swing_options,
                fn() { jazz_style.get().swing },
                fn(v) {
                  jazz_style.update(fn(js) { JazzStyle::{ ..js, swing: v } })
                },
              ),
            ]),
            // Melody Techniques
            settings_section("Melody Techniques", [
              technique_toggle(
                "Tension Tones",
                value=fn() { jazz_style.get().techniques.tension_tones },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    let t = js.techniques
                    JazzStyle::{
                      ..js,
                      techniques: @generator.Techniques::{
                        ..t,
                        tension_tones: not(t.tension_tones),
                      },
                    }
                  })
                },
              ),
              technique_toggle(
                "Scale Tones",
                value=fn() { jazz_style.get().techniques.scale_tones },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    let t = js.techniques
                    JazzStyle::{
                      ..js,
                      techniques: @generator.Techniques::{
                        ..t,
                        scale_tones: not(t.scale_tones),
                      },
                    }
                  })
                },
              ),
              technique_toggle(
                "Approach Tones",
                value=fn() { jazz_style.get().techniques.approach_tones },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    let t = js.techniques
                    JazzStyle::{
                      ..js,
                      techniques: @generator.Techniques::{
                        ..t,
                        approach_tones: not(t.approach_tones),
                      },
                    }
                  })
                },
              ),
              technique_toggle(
                "Enclosure Tones",
                value=fn() { jazz_style.get().techniques.enclosure_tones },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    let t = js.techniques
                    JazzStyle::{
                      ..js,
                      techniques: @generator.Techniques::{
                        ..t,
                        enclosure_tones: not(t.enclosure_tones),
                      },
                    }
                  })
                },
              ),
              technique_toggle(
                "Syncopation",
                value=fn() { jazz_style.get().techniques.syncopation },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    let t = js.techniques
                    JazzStyle::{
                      ..js,
                      techniques: @generator.Techniques::{
                        ..t,
                        syncopation: not(t.syncopation),
                      },
                    }
                  })
                },
              ),
              technique_toggle(
                "Triplets",
                value=fn() { jazz_style.get().techniques.triplets },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    let t = js.techniques
                    JazzStyle::{
                      ..js,
                      techniques: @generator.Techniques::{
                        ..t,
                        triplets: not(t.triplets),
                      },
                    }
                  })
                },
              ),
              technique_toggle(
                "Motif Reuse",
                value=fn() { jazz_style.get().techniques.motif_reuse },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    let t = js.techniques
                    JazzStyle::{
                      ..js,
                      techniques: @generator.Techniques::{
                        ..t,
                        motif_reuse: not(t.motif_reuse),
                      },
                    }
                  })
                },
              ),
              technique_toggle(
                "Bebop Scales",
                value=fn() { jazz_style.get().techniques.bebop_scales },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    let t = js.techniques
                    JazzStyle::{
                      ..js,
                      techniques: @generator.Techniques::{
                        ..t,
                        bebop_scales: not(t.bebop_scales),
                      },
                    }
                  })
                },
              ),
            ]),
            // Comping
            settings_section("Comping", [
              toggle_switch(
                label="Enabled",
                value=fn() { jazz_style.get().comping_enabled },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    JazzStyle::{
                      ..js,
                      comping_enabled: not(js.comping_enabled),
                    }
                  })
                },
              ),
              @luna_dom.show(fn() { jazz_style.get().comping_enabled }, fn() {
                segmented_buttons(
                  comping_style_options,
                  fn() { jazz_style.get().comping_style },
                  fn(v) {
                    jazz_style.update(fn(js) {
                      JazzStyle::{ ..js, comping_style: v }
                    })
                  },
                )
              }),
            ]),
            // Bass
            settings_section("Bass", [
              toggle_switch(
                label="Enabled",
                value=fn() { jazz_style.get().bass_enabled },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    JazzStyle::{ ..js, bass_enabled: not(js.bass_enabled) }
                  })
                },
              ),
              @luna_dom.show(fn() { jazz_style.get().bass_enabled }, fn() {
                segmented_buttons(
                  bass_style_options,
                  fn() { jazz_style.get().bass_style },
                  fn(v) {
                    jazz_style.update(fn(js) {
                      JazzStyle::{ ..js, bass_style: v }
                    })
                  },
                )
              }),
            ]),
            // Drums
            settings_section("Drums", [
              toggle_switch(
                label="Enabled",
                value=fn() { jazz_style.get().drums_enabled },
                on_toggle=fn() {
                  jazz_style.update(fn(js) {
                    JazzStyle::{ ..js, drums_enabled: not(js.drums_enabled) }
                  })
                },
              ),
              @luna_dom.show(fn() { jazz_style.get().drums_enabled }, fn() {
                segmented_buttons(
                  drum_pattern_options,
                  fn() { jazz_style.get().drum_pattern },
                  fn(v) {
                    jazz_style.update(fn(js) {
                      JazzStyle::{ ..js, drum_pattern: v }
                    })
                  },
                )
              }),
            ]),
          ],
        ),
      ])
    }),
  ])
}
