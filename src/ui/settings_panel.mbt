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
  ("●", @theme.COLOR_MIDI_IMPORTED, "MIDI Imported"),
]

///|
/// Section header inside the settings panel.
fn settings_section(
  title : String,
  children : Array[@luna_dom.DomNode],
  aria_label? : String,
) -> @luna_dom.DomNode {
  let attrs : Array[(String, @luna_dom.Attr)] = match aria_label {
    Some(l) => [("aria-label", @luna_dom.Attr::AttrString(l))]
    None => []
  }
  @luna_dom.div(class="flex flex-col gap-1.5", attrs~, [
    @luna_dom.div(
      class="text-xs font-semibold text-slate-400 uppercase tracking-wide",
      [@luna_dom.text(title)],
    ),
    @luna_dom.div(class="flex flex-col gap-2", children),
  ])
}

///|
let presets : Array[(String, () -> @music.JazzStyle)] = [
  ("Straight", @music.JazzStyle::straight),
  ("Simple", @music.JazzStyle::simple),
  ("Default", @music.JazzStyle::default),
]

///|
let melody_mode_options : Array[(String, @music.MelodyMode)] = [
  ("Off", @music.Off),
  ("Silent", @music.Silent),
  ("On", @music.On),
]

///|
let swing_options : Array[(String, @music.SwingConfig)] = [
  ("Off", @music.SwingConfig::straight()),
  ("Triplet", @music.SwingConfig::triplet()),
  ("Hard", @music.SwingConfig::hard_swing()),
]

///|
let comping_mode_options : Array[(String, @music.CompingMode)] = [
  ("Off", @music.Off),
  ("Silent", @music.Silent),
  ("On", @music.On),
]

///|
let comping_style_options : Array[(String, @music.CompingStyle)] = [
  ("Guide", @music.GuideTones),
  ("Full", @music.FullVoicing),
  ("Tension", @music.WithTensions),
  ("MIDI", @music.Imported),
]

///|
let drum_pattern_options : Array[(String, @music.DrumPatternStyle)] = [
  ("Ride", @music.SwingRide),
  ("Brush", @music.Brushes),
  ("MIDI", @music.Imported),
]

///|
let bass_style_options : Array[(String, @music.BassStyle)] = [
  ("Root", @music.RootOnly),
  ("R+5th", @music.RootFifth),
  ("Walk", @music.WalkingBass),
  ("MIDI", @music.Imported),
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
  jazz_style : @signals.Signal[@music.JazzStyle],
  show_technique_hints : @signals.Signal[Bool],
  midi_active_notes : @signals.Signal[Array[@music.MidiNumber]],
  get_midi_bytes : () -> Array[Int],
  on_import : (Array[Int]) -> Unit,
  imported_midi : @signals.Signal[@midi.ImportedMidi?],
  is_recording : @signals.Signal[Bool],
  recorded_lines : @signals.Signal[Array[RecordedLine]],
  on_note_on : (@music.MidiNumber) -> Unit,
  on_note_off : (@music.MidiNumber) -> Unit,
) -> @luna_dom.DomNode {
  let midi_imported = fn() { imported_midi.get() is Some(_) }
  @luna_dom.div(
    class="bg-slate-800 border-l border-slate-600 p-3 overflow-y-auto flex flex-col gap-3 w-64 shrink-0",
    attrs=[
      ("id", @luna_dom.Attr::AttrString("settings-panel")),
      ("aria-label", @luna_dom.Attr::AttrString("jazz settings panel")),
    ],
    [
      settings_section("MIDI", [
        midi_device_select(midi_active_notes, on_note_on~, on_note_off~),
        @luna_dom.div(class="flex gap-1", [
          midi_import_button(on_import),
          midi_export_button(get_midi_bytes),
        ]),
        midi_recording(is_recording, recorded_lines),
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
                        color == @theme.COLOR_MIDI_ACTIVE ||
                        color == @theme.COLOR_MIDI_IMPORTED {
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
      settings_section(
        "Melody",
        [
          segmented_buttons(
            melody_mode_options,
            fn() { jazz_style.get().melody_mode },
            fn(v) {
              jazz_style.update(fn(style) {
                @music.JazzStyle::{ ..style, melody_mode: v }
              })
            },
          ),
        ],
        aria_label="melody",
      ),
      // Pitch Range
      settings_section("Pitch Range", [pitch_range_slider(jazz_style)]),
      // Swing
      settings_section(
        "Swing",
        [
          segmented_buttons(swing_options, fn() { jazz_style.get().swing }, fn(
            v,
          ) {
            jazz_style.update(fn(style) {
              @music.JazzStyle::{ ..style, swing: v }
            })
          }),
        ],
        aria_label="swing",
      ),
      // Melody Techniques
      settings_section("Melody Techniques", [
        technique_toggle(
          "Tension Tones",
          value=fn() { jazz_style.get().techniques.tension_tones },
          on_toggle=fn() {
            jazz_style.update(fn(style) {
              let t = style.techniques
              @music.JazzStyle::{
                ..style,
                techniques: @music.Techniques::{
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
            jazz_style.update(fn(style) {
              let t = style.techniques
              @music.JazzStyle::{
                ..style,
                techniques: @music.Techniques::{
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
            jazz_style.update(fn(style) {
              let t = style.techniques
              @music.JazzStyle::{
                ..style,
                techniques: @music.Techniques::{
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
            jazz_style.update(fn(style) {
              let t = style.techniques
              @music.JazzStyle::{
                ..style,
                techniques: @music.Techniques::{
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
            jazz_style.update(fn(style) {
              let t = style.techniques
              @music.JazzStyle::{
                ..style,
                techniques: @music.Techniques::{
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
            jazz_style.update(fn(style) {
              let t = style.techniques
              @music.JazzStyle::{
                ..style,
                techniques: @music.Techniques::{
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
            jazz_style.update(fn(style) {
              let t = style.techniques
              @music.JazzStyle::{
                ..style,
                techniques: @music.Techniques::{
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
            jazz_style.update(fn(style) {
              let t = style.techniques
              @music.JazzStyle::{
                ..style,
                techniques: @music.Techniques::{
                  ..t,
                  sixteenth_runs: not(t.sixteenth_runs),
                },
              }
            })
          },
        ),
      ]),
      // Comping
      settings_section(
        "Comping",
        [
          segmented_buttons(
            comping_mode_options,
            fn() { jazz_style.get().comping_mode },
            fn(v) {
              jazz_style.update(fn(style) {
                @music.JazzStyle::{ ..style, comping_mode: v }
              })
            },
          ),
          @luna_dom.div(
            dyn_class=fn() {
              cn([
                "transition-opacity",
                match jazz_style.get().comping_mode {
                  @music.Off => "opacity-40 pointer-events-none"
                  _ => ""
                },
              ])
            },
            [
              segmented_buttons(
                comping_style_options,
                fn() { jazz_style.get().comping_style },
                fn(v) {
                  jazz_style.update(fn(style) {
                    @music.JazzStyle::{ ..style, comping_style: v }
                  })
                },
                is_disabled=fn(v) {
                  if midi_imported() {
                    v != @music.CompingStyle::Imported
                  } else {
                    v == @music.CompingStyle::Imported
                  }
                },
              ),
            ],
          ),
        ],
        aria_label="comping",
      ),
      // Bass
      settings_section(
        "Bass",
        [
          toggle_switch(
            label="Enabled",
            value=fn() { jazz_style.get().bass_enabled },
            on_toggle=fn() {
              jazz_style.update(fn(style) {
                @music.JazzStyle::{
                  ..style,
                  bass_enabled: not(style.bass_enabled),
                }
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
                  jazz_style.update(fn(style) {
                    @music.JazzStyle::{ ..style, bass_style: v }
                  })
                },
                is_disabled=fn(v) {
                  if midi_imported() {
                    v != @music.BassStyle::Imported
                  } else {
                    v == @music.BassStyle::Imported
                  }
                },
              ),
            ],
          ),
        ],
        aria_label="bass",
      ),
      // Drums
      settings_section(
        "Drums",
        [
          toggle_switch(
            label="Enabled",
            value=fn() { jazz_style.get().drums_enabled },
            on_toggle=fn() {
              jazz_style.update(fn(style) {
                @music.JazzStyle::{
                  ..style,
                  drums_enabled: not(style.drums_enabled),
                }
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
                  jazz_style.update(fn(style) {
                    @music.JazzStyle::{ ..style, drum_pattern: v }
                  })
                },
                is_disabled=fn(v) {
                  if midi_imported() {
                    v != @music.DrumPatternStyle::Imported
                  } else {
                    v == @music.DrumPatternStyle::Imported
                  }
                },
              ),
            ],
          ),
        ],
        aria_label="drums",
      ),
    ],
  )
}
