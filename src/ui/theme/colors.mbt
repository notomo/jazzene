///|
pub const COLOR_CHORD_TONE = "#60a5fa"

///|
pub const COLOR_TENSION = "#4ade80"

///|
pub const COLOR_APPROACH = "#fb923c"

///|
pub const PLAYING_COLOR_CHORD_TONE = "#3b82f6"

///|
pub const PLAYING_COLOR_TENSION = "#22c55e"

///|
pub const PLAYING_COLOR_APPROACH = "#f97316"

///|
pub const COLOR_ENCLOSURE = "#fbbf24"

///|
pub const PLAYING_COLOR_ENCLOSURE = "#f59e0b"

///|
pub const COLOR_PASSING_TONE = "#fb7185"

///|
pub const PLAYING_COLOR_PASSING_TONE = "#f43f5e"

///|
pub const COLOR_NEIGHBOR = "#c084fc"

///|
pub const PLAYING_COLOR_NEIGHBOR = "#a855f7"

///|
pub const COLOR_COMPING = "#9ca3af"

///|
pub const PLAYING_COLOR_COMPING = "#6b7280"

///|
pub fn tone_origin_color(origin : @music.ToneOrigin) -> String {
  match origin {
    ChordTone => COLOR_CHORD_TONE
    Tension(_) => COLOR_TENSION
    ChromaticApproach => COLOR_APPROACH
    PassingTone => COLOR_PASSING_TONE
    Enclosure => COLOR_ENCLOSURE
    NeighborTone => COLOR_NEIGHBOR
  }
}

///|
pub fn tone_origin_playing_color(origin : @music.ToneOrigin) -> String {
  match origin {
    ChordTone => PLAYING_COLOR_CHORD_TONE
    Tension(_) => PLAYING_COLOR_TENSION
    ChromaticApproach => PLAYING_COLOR_APPROACH
    PassingTone => PLAYING_COLOR_PASSING_TONE
    Enclosure => PLAYING_COLOR_ENCLOSURE
    NeighborTone => PLAYING_COLOR_NEIGHBOR
  }
}
