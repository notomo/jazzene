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
fn comping_section(
  jazz_style : @signals.Signal[@music.JazzStyle],
  midi_imported : () -> Bool,
) -> @luna_dom.DomNode {
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
      ) <| [
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
    ],
    aria_label="comping",
  )
}
