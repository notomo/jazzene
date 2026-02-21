///|
/// Helper: check if two time ranges overlap
fn time_overlaps(
  a_start : Double,
  a_dur : Double,
  b_start : Double,
  b_dur : Double,
) -> Bool {
  a_start < b_start + b_dur && a_start + a_dur > b_start
}

///|
/// Collision info for diagnostics
struct Collision {
  seed : Int
  backing_midi : Int
  melody_midi : Int
  time_ms : Double
  is_anticipated : Bool // backing started before chord boundary
} derive(Show)

///|
/// Generate measures + melody + backing for a given seed, return any collisions.
fn collisions_for_seed(seed : Int) -> Array[Collision] {
  // Match the app's default settings
  let bpm = 200
  let measure_count = 8
  let beats_per_measure = @music.TimeSignature::default().beats_per_measure()
  let key = @music.KeySignature::c_major()
  let time_signature = @music.TimeSignature::default()

  // App default: "IIm7 | V7 | Imaj7 | IVmaj7" in C = Dm7 | G7 | Cmaj7 | Fmaj7
  let measure_defs = match
    @music.parse_measure_progression("IIm7 | V7 | Imaj7 | IVmaj7") {
    Ok(dm) => dm.map(fn(d) { d.resolve(key.root) })
    Err(_) => return []
  }

  let settings = Settings::default(seed)
  let gen = create_measure_generator(settings)
  let music_measures = improvisation(
    gen,
    measure_defs,
    bpm,
    measure_count - 2,
    key,
    settings,
    time_signature~,
    beats_per_measure~,
    start_offset=1,
  )
  let leading = leading_rest_measure(beats_per_measure~)
  let trailing_start = (measure_count - 1).to_double() *
    @music.ms_per_measure(bpm, beats_per_measure~)
  let trailing = trailing_rest_measure(
    start_time=@music.Duration::from_milliseconds(trailing_start),
    beats_per_measure~,
  )
  let all_measures = leading + music_measures + trailing

  // Use triplet swing matching the app default
  let swing = @music.SwingConfig::triplet()
  let melody_sounds = @music.convert_measures_to_sounds(
    all_measures,
    bpm,
    swing~,
  )
  let backing_sounds = @music.convert_measures_to_backing_sounds(
    all_measures,
    bpm,
    melody_sounds,
    seed~,
  )

  let beat_dur_ms = @music.ms_per_beat(bpm)
  let collisions : Array[Collision] = []
  for bs in backing_sounds {
    let b_midi = match bs.midi() {
      Some(m) => m.value
      None => continue
    }
    let b_start = bs.start_time.to_milliseconds()
    let b_dur = bs.duration.to_milliseconds()
    for ms in melody_sounds {
      let m_midi = match ms.midi() {
        Some(m) => m.value
        None => continue
      }
      let m_start = ms.start_time.to_milliseconds()
      let m_dur = ms.duration.to_milliseconds()
      // Crossing: gap < 5 semitones (backing within a major third of melody)
      if time_overlaps(b_start, b_dur, m_start, m_dur) && b_midi > m_midi - 5 {
        let beat_fraction = b_start / beat_dur_ms
        let is_anticipated = (beat_fraction - beat_fraction.to_int().to_double()).abs() >
          0.1
        collisions.push(Collision::{
          seed,
          backing_midi: b_midi,
          melody_midi: m_midi,
          time_ms: b_start,
          is_anticipated,
        })
      }
    }
  }
  collisions
}

///|
/// Print overlapping (melody, backing) note pairs for a given seed for diagnosis.
fn print_concurrent_pairs(seed : Int) -> Unit {
  let bpm = 200
  let measure_count = 8
  let beats_per_measure = @music.TimeSignature::default().beats_per_measure()
  let key = @music.KeySignature::c_major()
  let time_signature = @music.TimeSignature::default()
  let measure_defs = match
    @music.parse_measure_progression("IIm7 | V7 | Imaj7 | IVmaj7") {
    Ok(dm) => dm.map(fn(d) { d.resolve(key.root) })
    Err(_) => return
  }
  let settings = Settings::default(seed)
  let gen = create_measure_generator(settings)
  let music_measures = improvisation(
    gen,
    measure_defs,
    bpm,
    measure_count - 2,
    key,
    settings,
    time_signature~,
    beats_per_measure~,
    start_offset=1,
  )
  let leading = leading_rest_measure(beats_per_measure~)
  let trailing_start = (measure_count - 1).to_double() *
    @music.ms_per_measure(bpm, beats_per_measure~)
  let trailing = trailing_rest_measure(
    start_time=@music.Duration::from_milliseconds(trailing_start),
    beats_per_measure~,
  )
  let all_measures = leading + music_measures + trailing
  let swing = @music.SwingConfig::triplet()
  let melody_sounds = @music.convert_measures_to_sounds(
    all_measures,
    bpm,
    swing~,
  )
  let backing_sounds = @music.convert_measures_to_backing_sounds(
    all_measures,
    bpm,
    melody_sounds,
    seed~,
  )
  // Print all concurrent (backing, melody) pairs where backing >= melody - 12
  // to see near-crossings as well as strict crossings
  for bs in backing_sounds {
    let b_midi = match bs.midi() {
      Some(m) => m.value
      None => continue
    }
    let b_start = bs.start_time.to_milliseconds()
    let b_dur = bs.duration.to_milliseconds()
    for ms in melody_sounds {
      let m_midi = match ms.midi() {
        Some(m) => m.value
        None => continue
      }
      let m_start = ms.start_time.to_milliseconds()
      let m_dur = ms.duration.to_milliseconds()
      if time_overlaps(b_start, b_dur, m_start, m_dur) && b_midi >= m_midi - 12 {
        let gap = m_midi - b_midi
        println(
          "t=\{b_start}ms  backing=\{b_midi}  melody=\{m_midi}  gap=\{gap}",
        )
      }
    }
  }
}

///|
test "debug: seed=158 concurrent note pairs" {
  print_concurrent_pairs(158)
}

///|
test "backing vs melody: no pitch collisions for seeds 127 and 134 (reported cases)" {
  for seed in [127, 134] {
    let cs = collisions_for_seed(seed)
    if cs.length() > 0 {
      for c in cs {
        let s = if c.is_anticipated { " [anticipated]" } else { "" }
        println(
          "seed=\{c.seed}: backing=\{c.backing_midi} >= melody=\{c.melody_midi} at \{c.time_ms}ms\{s}",
        )
      }
    }
    assert_eq(cs.length(), 0)
  }
}

///|
test "backing vs melody: no pitch collisions across seeds 0-511" {
  let all_collisions : Array[Collision] = []
  for seed = 0; seed <= 511; seed = seed + 1 {
    all_collisions.append(collisions_for_seed(seed))
  }

  if all_collisions.length() > 0 {
    let limit = @cmp.minimum(all_collisions.length(), 20)
    for i = 0; i < limit; i = i + 1 {
      let c = all_collisions[i]
      let s = if c.is_anticipated { " [anticipated]" } else { "" }
      println(
        "seed=\{c.seed}: backing=\{c.backing_midi} >= melody=\{c.melody_midi} at \{c.time_ms}ms\{s}",
      )
    }
    let total = all_collisions.length()
    println("Total collisions: \{total}")
  }
  assert_eq(all_collisions.length(), 0)
}
