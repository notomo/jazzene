///|
/// Toggle flags for jazz improvisation techniques.
/// Each flag controls whether the corresponding technique is enabled.
/// When disabled, the technique's weight/probability in ImprovisationConfig is zeroed out.
pub(all) struct Techniques {
  tension_tones : Bool // Tension notes (9th, 11th, 13th)
  chromatic_approach : Bool // Approach tones (chromatic half-steps)
  enclosure : Bool // Enclosure tones (2 semitones from chord tones)
  syncopation : Bool // Syncopation (off-beat phrase starts)
  triplets : Bool // Eighth-note triplets
  bebop_scales : Bool // Bebop passing tones (major 7th for dom7, #5 for maj7)
  neighbor_tones : Bool // Neighbor tone ornaments (CT→N→CT pattern)
  sixteenth_runs : Bool // Sixteenth-note run ornaments (P1 P2 P3 CT pattern)
} derive(Eq, Show)

///|
/// Default techniques: all enabled
pub fn Techniques::default() -> Techniques {
  Techniques::{
    tension_tones: true,
    chromatic_approach: true,
    enclosure: true,
    syncopation: true,
    triplets: true,
    bebop_scales: true,
    neighbor_tones: true,
    sixteenth_runs: true,
  }
}
