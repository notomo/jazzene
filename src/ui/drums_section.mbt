///|
let drum_pattern_options : Array[(String, @music.DrumPatternStyle)] = [
  ("Ride", @music.SwingRide),
  ("Brush", @music.Brushes),
  ("MIDI", @music.Imported),
]

///|
fn drums_section(
  jazz_style : @signals.Signal[@music.JazzStyle],
  midi_imported : () -> Bool,
) -> @luna_dom.DomNode {
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
  )
}
