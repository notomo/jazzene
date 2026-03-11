///|
/// Settings panel for jazz style configuration.
/// Contains controls for legend, swing, melody techniques, comping, bass, and drums.

///|
/// Technique color legend entry: (label, color, description)
let legend_entries : Array[(String, String, String)] = [
  ("●", @theme.COLOR_CHORD_TONE, "Chord Tone (1, 3, 5, 7)"),
  ("●", @theme.COLOR_TENSION, "Tension (9, 11, 13)"),
  ("●", @theme.COLOR_APPROACH, "Chromatic Approach"),
  ("●", @theme.COLOR_PASSING_TONE, "Bebop Passing Tone"),
  ("●", @theme.COLOR_ENCLOSURE, "Enclosure"),
  ("●", @theme.COLOR_NEIGHBOR, "Neighbor Tone"),
  ("●", @theme.COLOR_COMPING, "Comping"),
  ("●", @theme.COLOR_MIDI_ACTIVE, "MIDI Input"),
]

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
    class="flex w-full",
    options.map(fn(pair) {
      let (label, value) = pair
      @luna_dom.button(
        dyn_class=fn() {
          cn([
            base,
            "flex-1 text-center",
            if current() == value {
              active
            } else {
              inactive
            },
          ])
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
    @luna_dom.div(class="flex flex-col gap-2", children),
  ])
}

///|
let melody_mode_options : Array[(String, MelodyMode)] = [
  ("Off", Off),
  ("Silent", Silent),
  ("On", On),
]

///|
let swing_options : Array[(String, @music.SwingConfig)] = [
  ("Off", @music.SwingConfig::straight()),
  ("Triplet", @music.SwingConfig::triplet()),
  ("Hard", @music.SwingConfig::hard_swing()),
]

///|
let comping_mode_options : Array[(String, CompingMode)] = [
  ("Off", Off),
  ("Silent", Silent),
  ("On", On),
]

///|
let comping_style_options : Array[(String, @music.CompingStyle)] = [
  ("Guide Tones", @music.GuideTones),
  ("Full", @music.FullVoicing),
  ("Tensions", @music.WithTensions),
]

///|
let drum_pattern_options : Array[(String, @music.DrumPatternStyle)] = [
  ("Ride", @music.SwingRide),
  ("Brush", @music.Brushes),
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
  show_technique_hints : @signals.Signal[Bool],
  midi_active_notes : @signals.Signal[Array[@music.MidiNumber]],
  sounds : () -> Array[@music.ScheduledSound],
  bpm : () -> Int,
  time_signature : () -> @music.TimeSignature,
  key_signature : () -> @music.KeySignature,
  raw_chord_progression : () -> String,
  seed : () -> Int,
) -> @luna_dom.DomNode {
  @luna_dom.div(
    class="bg-slate-800 border-l border-slate-600 p-3 overflow-y-auto flex flex-col gap-3 w-64 shrink-0",
    attrs=[
      ("id", @luna_dom.Attr::AttrString("settings-panel")),
      ("aria-label", @luna_dom.Attr::AttrString("jazz settings panel")),
    ],
    [
      // MIDI Input
      settings_section("MIDI Input", [
        midi_device_select(midi_active_notes),
        midi_export_button(
          sounds, bpm, time_signature, key_signature, raw_chord_progression, seed,
        ),
      ]),
      // Legend
      settings_section("Legend", [
        toggle_switch(
          label="Technique Hints",
          value=fn() { show_technique_hints.get() },
          on_toggle=fn() { show_technique_hints.update(not) },
        ),
        @luna_dom.div(
          class="flex flex-col gap-1",
          legend_entries.map(fn(entry) {
            let (dot, color, label) = entry
            @luna_dom.div(class="flex items-center gap-1.5", [
              @luna_dom.span(
                dyn_class=fn() { "text-xs leading-none" },
                dyn_attrs=[
                  (
                    "style",
                    @luna_dom.AttrValue::Dynamic(fn() {
                      let c = if show_technique_hints.get() ||
                        color == @theme.COLOR_COMPING ||
                        color == @theme.COLOR_MIDI_ACTIVE {
                        color
                      } else {
                        @theme.COLOR_CHORD_TONE
                      }
                      "color: " + c
                    }),
                  ),
                ],
                [@luna_dom.text(dot)],
              ),
              @luna_dom.span(class="text-xs text-slate-200", [
                @luna_dom.text(label),
              ]),
            ])
          }),
        ),
      ]),
      // Presets
      settings_section("Preset", [
        @luna_dom.div(
          class="flex flex-wrap gap-1 w-full",
          presets.map(fn(pair) {
            let (label, make_preset) = pair
            @luna_dom.button(
              class="flex-1 text-center px-2 py-0.5 text-xs rounded border bg-slate-900 border-slate-600 text-slate-300 hover:bg-slate-700 hover:border-slate-400 transition-colors",
              on=@luna_dom.events().click(fn(_) {
                jazz_style.set(make_preset())
              }),
              [@luna_dom.text(label)],
            )
          }),
        ),
      ]),
      // Melody
      settings_section("Melody", [
        segmented_buttons(
          melody_mode_options,
          fn() { jazz_style.get().melody_mode },
          fn(v) {
            jazz_style.update(fn(js) { JazzStyle::{ ..js, melody_mode: v } })
          },
        ),
      ]),
      // Pitch Range
      settings_section("Pitch Range", [pitch_range_slider(jazz_style)]),
      // Swing
      settings_section("Swing", [
        segmented_buttons(swing_options, fn() { jazz_style.get().swing }, fn(
          v,
        ) {
          jazz_style.update(fn(js) { JazzStyle::{ ..js, swing: v } })
        }),
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
          "Chromatic Approach",
          value=fn() { jazz_style.get().techniques.chromatic_approach },
          on_toggle=fn() {
            jazz_style.update(fn(js) {
              let t = js.techniques
              JazzStyle::{
                ..js,
                techniques: @generator.Techniques::{
                  ..t,
                  chromatic_approach: not(t.chromatic_approach),
                },
              }
            })
          },
        ),
        technique_toggle(
          "Enclosures",
          value=fn() { jazz_style.get().techniques.enclosure },
          on_toggle=fn() {
            jazz_style.update(fn(js) {
              let t = js.techniques
              JazzStyle::{
                ..js,
                techniques: @generator.Techniques::{
                  ..t,
                  enclosure: not(t.enclosure),
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
        technique_toggle(
          "Neighbor Tones",
          value=fn() { jazz_style.get().techniques.neighbor_tones },
          on_toggle=fn() {
            jazz_style.update(fn(js) {
              let t = js.techniques
              JazzStyle::{
                ..js,
                techniques: @generator.Techniques::{
                  ..t,
                  neighbor_tones: not(t.neighbor_tones),
                },
              }
            })
          },
        ),
        technique_toggle(
          "16th Runs",
          value=fn() { jazz_style.get().techniques.sixteenth_runs },
          on_toggle=fn() {
            jazz_style.update(fn(js) {
              let t = js.techniques
              JazzStyle::{
                ..js,
                techniques: @generator.Techniques::{
                  ..t,
                  sixteenth_runs: not(t.sixteenth_runs),
                },
              }
            })
          },
        ),
      ]),
      // Comping
      settings_section("Comping", [
        segmented_buttons(
          comping_mode_options,
          fn() { jazz_style.get().comping_mode },
          fn(v) {
            jazz_style.update(fn(js) { JazzStyle::{ ..js, comping_mode: v } })
          },
        ),
        @luna_dom.div(
          dyn_class=fn() {
            cn([
              "transition-opacity",
              match jazz_style.get().comping_mode {
                Off => "opacity-40 pointer-events-none"
                _ => ""
              },
            ])
          },
          [
            segmented_buttons(
              comping_style_options,
              fn() { jazz_style.get().comping_style },
              fn(v) {
                jazz_style.update(fn(js) {
                  JazzStyle::{ ..js, comping_style: v }
                })
              },
            ),
          ],
        ),
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
        @luna_dom.div(
          dyn_class=fn() {
            cn([
              "transition-opacity",
              if jazz_style.get().bass_enabled {
                ""
              } else {
                "opacity-40 pointer-events-none"
              },
            ])
          },
          [
            segmented_buttons(
              bass_style_options,
              fn() { jazz_style.get().bass_style },
              fn(v) {
                jazz_style.update(fn(js) { JazzStyle::{ ..js, bass_style: v } })
              },
            ),
          ],
        ),
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
        @luna_dom.div(
          dyn_class=fn() {
            cn([
              "transition-opacity",
              if jazz_style.get().drums_enabled {
                ""
              } else {
                "opacity-40 pointer-events-none"
              },
            ])
          },
          [
            segmented_buttons(
              drum_pattern_options,
              fn() { jazz_style.get().drum_pattern },
              fn(v) {
                jazz_style.update(fn(js) {
                  JazzStyle::{ ..js, drum_pattern: v }
                })
              },
            ),
          ],
        ),
      ]),
    ],
  )
}
