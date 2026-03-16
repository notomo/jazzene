///|
pub fn select_melody_sounds(
  melody_mode : @music.MelodyMode,
  imported_midi : ImportedMidi?,
  full_sounds : Array[@music.ScheduledSound],
  bpm : Int,
  key : @music.KeySignature,
) -> Array[@music.ScheduledSound] {
  match melody_mode {
    @music.Off => []
    @music.On | @music.Silent =>
      match imported_midi {
        Some(data) if not(data.melody_sounds.is_empty()) =>
          adapt_pitched(data, bpm, key, data.melody_sounds)
        _ => full_sounds
      }
  }
}

///|
pub fn select_measures(
  melody_mode : @music.MelodyMode,
  imported_midi : ImportedMidi?,
  full_measures : Array[@music.Measure],
  bpm : Int,
  time_signature : @music.TimeSignature,
  measure_count : Int,
  key : @music.KeySignature,
) -> Array[@music.Measure] {
  match melody_mode {
    @music.On | @music.Silent =>
      match imported_midi {
        Some(data) if not(data.melody_sounds.is_empty()) => {
          let adapted = adapt_pitched(data, bpm, key, data.melody_sounds)
          @music.sounds_to_measures(
            adapted, bpm, time_signature, measure_count, key,
          )
        }
        _ => full_measures
      }
    @music.Off =>
      full_measures.map(fn(m) {
        @music.Measure::{
          ..m,
          beats: m.beats.map(fn(b) { @music.Beat::{ ..b, notes: [] } }),
        }
      })
  }
}

///|
pub fn select_drum_sounds(
  js : @music.JazzStyle,
  imported_midi : ImportedMidi?,
  bpm : Int,
  measure_count : Int,
  time_signature : @music.TimeSignature,
) -> Array[@music.ScheduledSound] {
  if not(js.drums_enabled) {
    return []
  }
  match js.drum_pattern {
    @music.Imported =>
      match imported_midi {
        Some(data) =>
          @music.rescale_sounds(data.drum_sounds, data.bpm.unwrap_or(bpm), bpm)
        None => []
      }
    _ =>
      @music.generate_drum_sounds(
        bpm,
        measure_count,
        time_signature~,
        swing=js.swing,
        pattern_style=js.drum_pattern,
      )
  }
}

///|
pub fn select_comping_sounds(
  js : @music.JazzStyle,
  imported_midi : ImportedMidi?,
  full_measures : Array[@music.Measure],
  bpm : Int,
  full_sounds : Array[@music.ScheduledSound],
  key : @music.KeySignature,
  seed : Int,
) -> Array[@music.ScheduledSound] {
  if js.comping_mode == @music.Off {
    return []
  }
  match js.comping_style {
    @music.Imported =>
      match imported_midi {
        Some(data) => adapt_pitched(data, bpm, key, data.comping_sounds)
        None => []
      }
    _ =>
      @music.generate_comping_sounds(
        full_measures,
        bpm,
        full_sounds,
        key,
        seed~,
        voicing_style=js.comping_style,
      )
  }
}

///|
pub fn select_bass_sounds(
  js : @music.JazzStyle,
  imported_midi : ImportedMidi?,
  full_measures : Array[@music.Measure],
  bpm : Int,
  key : @music.KeySignature,
) -> Array[@music.ScheduledSound] {
  if not(js.bass_enabled) {
    return []
  }
  match js.bass_style {
    @music.Imported =>
      match imported_midi {
        Some(data) => adapt_pitched(data, bpm, key, data.bass_sounds)
        None => []
      }
    _ => @music.generate_walking_bass_sounds(full_measures, bpm, js.bass_style)
  }
}
