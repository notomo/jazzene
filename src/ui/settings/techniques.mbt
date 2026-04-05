///|
fn technique_toggle(
  label : String,
  value~ : () -> Bool,
  on_toggle~ : () -> Unit,
) -> @luna_dom.DomNode {
  toggle_switch(label~, value~, on_toggle~)
}

///|
fn melody_techniques_section(
  jazz_style : @signals.Signal[@music.JazzStyle],
) -> @luna_dom.DomNode {
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
              tension_tones: !t.tension_tones,
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
              chromatic_approach: !t.chromatic_approach,
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
            techniques: @music.Techniques::{ ..t, enclosure: !t.enclosure },
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
            techniques: @music.Techniques::{ ..t, syncopation: !t.syncopation },
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
            techniques: @music.Techniques::{ ..t, triplets: !t.triplets },
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
              bebop_scales: !t.bebop_scales,
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
              neighbor_tones: !t.neighbor_tones,
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
              sixteenth_runs: !t.sixteenth_runs,
            },
          }
        })
      },
    ),
  ])
}
