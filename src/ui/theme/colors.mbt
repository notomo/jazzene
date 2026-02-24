///|
pub const COLOR_CHORD_TONE = "#60a5fa"

///|
pub const COLOR_TENSION = "#4ade80"

///|
pub const COLOR_APPROACH = "#fb923c"

///|
pub const COLOR_SCALE_TONE = "#f472b6"

///|
pub const PLAYING_COLOR_CHORD_TONE = "#3b82f6"

///|
pub const PLAYING_COLOR_TENSION = "#22c55e"

///|
pub const PLAYING_COLOR_APPROACH = "#f97316"

///|
pub const PLAYING_COLOR_SCALE_TONE = "#ec4899"

///|
pub fn tone_origin_color(origin : @music.ToneOrigin) -> String {
  match origin {
    ChordTone => COLOR_CHORD_TONE
    Tension(_) => COLOR_TENSION
    ApproachTone | Enclosure | PassingTone => COLOR_APPROACH
    ScaleTone => COLOR_SCALE_TONE
  }
}

///|
pub fn tone_origin_playing_color(origin : @music.ToneOrigin) -> String {
  match origin {
    ChordTone => PLAYING_COLOR_CHORD_TONE
    Tension(_) => PLAYING_COLOR_TENSION
    ApproachTone | Enclosure | PassingTone => PLAYING_COLOR_APPROACH
    ScaleTone => PLAYING_COLOR_SCALE_TONE
  }
}
