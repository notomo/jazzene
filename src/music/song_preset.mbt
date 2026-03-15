///|
/// Song preset with typed music fields
pub struct SongPreset {
  name : String
  chords : String
  key : ChordRoot?
  bpm : Int?
  measures : Int?
  time_signature : TimeSignature?
}

///|
/// Song presets (jazz standards and forms)
pub let song_presets : Array[SongPreset] = [
  SongPreset::{
    name: "II-V-I",
    chords: "IIm7 | V7 | Imaj7 | Imaj7",
    key: Some(C),
    bpm: Some(160),
    measures: Some(6),
    time_signature: Some(TimeSignature::{ numerator: 4, denominator: 4 }),
  },
  SongPreset::{
    name: "Blues",
    chords: "I7 | IV7 | I7 | I7 | IV7 | IV7 | I7 | VIm7 IIm7 | V7 | V7 | I7 V7 | I7",
    key: Some(F),
    bpm: Some(120),
    measures: Some(14),
    time_signature: Some(TimeSignature::{ numerator: 4, denominator: 4 }),
  },
  SongPreset::{
    name: "Rhythm Changes A",
    chords: "Imaj7 VIm7 | IIm7 V7 | IIIm7 VIm7 | IIm7 V7",
    key: Some(ASharp),
    bpm: Some(220),
    measures: Some(10),
    time_signature: Some(TimeSignature::{ numerator: 4, denominator: 4 }),
  },
  SongPreset::{
    name: "Autumn Leaves",
    chords: "IIm7 | V7 | Imaj7 | IVmaj7 | VIIm7b5 | III7 | VIm7 | VIm7",
    key: Some(ASharp),
    bpm: Some(140),
    measures: Some(18),
    time_signature: Some(TimeSignature::{ numerator: 4, denominator: 4 }),
  },
  SongPreset::{
    name: "Someday My Prince Will Come",
    chords: "Imaj7 | III7 | IVmaj7 | bVI7 | IIm7 | V7 | Imaj7 | V7",
    key: Some(ASharp),
    bpm: Some(180),
    measures: Some(18),
    time_signature: Some(TimeSignature::{ numerator: 3, denominator: 4 }),
  },
]
