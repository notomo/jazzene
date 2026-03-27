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
fn melody_section(
  jazz_style : @signals.Signal[@music.JazzStyle],
) -> @luna_dom.DomNode {
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
  )
}

///|
fn swing_section(
  jazz_style : @signals.Signal[@music.JazzStyle],
) -> @luna_dom.DomNode {
  settings_section(
    "Swing",
    [
      segmented_buttons(swing_options, fn() { jazz_style.get().swing }, fn(v) {
        jazz_style.update(fn(style) { @music.JazzStyle::{ ..style, swing: v } })
      }),
    ],
    aria_label="swing",
  )
}
