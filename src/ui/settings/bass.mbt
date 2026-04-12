///|
let bass_style_options : Array[(String, @music.BassStyle)] = [
  ("Root", @music.RootOnly),
  ("R+5th", @music.RootFifth),
  ("Walk", @music.WalkingBass),
  ("MIDI", @music.Imported),
]

///|
fn bass_section(
  jazz_style : @signals.Signal[@music.JazzStyle],
  midi_imported : () -> Bool,
) -> @luna_dom.DomNode {
  settings_section(
    "Bass",
    [
      toggle_switch(
        label="Enabled",
        value=fn() { jazz_style.get().bass_enabled },
        on_toggle=fn() {
          jazz_style.update(fn(style) {
            @music.JazzStyle::{ ..style, bass_enabled: !style.bass_enabled }
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
      ) <| [
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
    ],
    aria_label="bass",
  )
}
