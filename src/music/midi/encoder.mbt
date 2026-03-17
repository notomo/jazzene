///|
/// Convert seconds to MIDI ticks given BPM (480 ticks per quarter note)
fn seconds_to_ticks(seconds : Double, bpm : Int) -> Int {
  (seconds * bpm.to_double() * 480.0 / 60.0 + 0.5).to_int()
}

///|
/// Append variable-length quantity (VLQ) bytes to buffer.
/// Used for encoding MIDI delta times.
pub fn write_vlq(value : Int, buf : Array[Int]) -> Unit {
  if value < 128 {
    buf.push(value)
    return
  }
  let groups : Array[Int] = []
  for v = value; v > 0; {
    groups.push(v & 0x7F)
    continue v >> 7
  }
  let n = groups.length()
  for i in 0..<n {
    let idx = n - 1 - i
    buf.push(
      match idx > 0 {
        true => groups[idx] | 0x80
        false => groups[idx]
      },
    )
  }
}

///|
/// Map ToneOrigin to MIDI velocity for melody notes.
fn melody_velocity(tone_origin : @music.ToneOrigin?) -> Int {
  match tone_origin {
    Some(ChordTone) => 90
    Some(Tension(_)) => 80
    Some(ChromaticApproach) => 70
    Some(Enclosure) => 70
    Some(NeighborTone) => 65
    Some(PassingTone) => 65
    Some(Imported) => 80
    None => 80
  }
}

///|
/// Map drum MIDI note to velocity via DrumVoice.
fn drum_velocity(midi : @music.MidiNumber) -> Int {
  match @music.DrumVoice::from_midi(midi) {
    Some(Kick) => 85
    Some(Snare) => 80
    Some(HiHat) => 65
    Some(Ride) => 58
    Some(Brush) => 55
    None => 64
  }
}

///|
/// Write MTrk chunk (header + data) into buf.
fn write_track(buf : Array[Int], track_data : Array[Int]) -> Unit {
  buf.push(0x4D) // M
  buf.push(0x54) // T
  buf.push(0x72) // r
  buf.push(0x6B) // k
  let track_len = track_data.length()
  buf.push((track_len >> 24) & 0xFF)
  buf.push((track_len >> 16) & 0xFF)
  buf.push((track_len >> 8) & 0xFF)
  buf.push(track_len & 0xFF)
  for b in track_data {
    buf.push(b)
  }
}

///|
/// Build meta track (track 0) with tempo / time_signature / key_sig / text.
fn make_meta_track(
  bpm : Int,
  time_signature : @music.TimeSignature,
  key_signature : @music.KeySignature,
  text : String,
) -> Array[Int] {
  let track_data : Array[Int] = []

  // Tempo meta-event (delta=0): FF 51 03 + 3 bytes microseconds
  let microseconds = 60000000 / bpm
  track_data.push(0)
  track_data.push(0xFF)
  track_data.push(0x51)
  track_data.push(0x03)
  track_data.push((microseconds >> 16) & 0xFF)
  track_data.push((microseconds >> 8) & 0xFF)
  track_data.push(microseconds & 0xFF)

  // Time signature meta-event (delta=0): FF 58 04 nn dd cc bb
  let dd = match time_signature.denominator {
    2 => 1
    8 => 3
    16 => 4
    _ => 2
  }
  track_data.push(0)
  track_data.push(0xFF)
  track_data.push(0x58)
  track_data.push(0x04)
  track_data.push(time_signature.numerator)
  track_data.push(dd)
  track_data.push(24)
  track_data.push(8)

  // Key signature meta-event (delta=0): FF 59 02 sf mi
  let sf = match key_signature.accidental_type {
    Sharp => key_signature.altered_steps.length()
    Flat => 256 - key_signature.altered_steps.length()
    Natural => 0
  }
  track_data.push(0)
  track_data.push(0xFF)
  track_data.push(0x59)
  track_data.push(0x02)
  track_data.push(sf)
  track_data.push(0)

  // Text meta-event (delta=0): FF 01 len text
  if text != "" {
    track_data.push(0)
    track_data.push(0xFF)
    track_data.push(0x01)
    write_vlq(text.length(), track_data)
    for c in text {
      track_data.push(c.to_int())
    }
  }

  // End of Track
  track_data.push(0)
  track_data.push(0xFF)
  track_data.push(0x2F)
  track_data.push(0x00)

  track_data
}

///|
/// Build an instrument track with optional Program Change, CC7, and note events.
/// channel: MIDI channel (0-15); program: None skips Program Change (use for ch9 drums)
fn make_instrument_track(
  channel : Int,
  program : Int?,
  cc7_volume : Int,
  sounds : Array[@music.ScheduledSound],
  bpm : Int,
  velocity_fn : (@music.ScheduledSound) -> Int,
) -> Array[Int] {
  let track_data : Array[Int] = []

  // Program Change (skip for drum channel)
  match program {
    Some(prog) => {
      track_data.push(0)
      track_data.push(0xC0 | channel)
      track_data.push(prog)
    }
    None => ()
  }

  // CC7 Channel Volume
  track_data.push(0)
  track_data.push(0xB0 | channel)
  track_data.push(0x07)
  track_data.push(cc7_volume)

  // Build note events: (tick, kind, pitch, velocity)
  let events : Array[(Int, Int, Int, Int)] = []
  for sound in sounds {
    match sound.sound_event {
      Note(midi~, ..) => {
        let start_tick = seconds_to_ticks(sound.start_time.to_seconds(), bpm)
        let end_tick = seconds_to_ticks(
          (sound.start_time + sound.duration).to_seconds(),
          bpm,
        )
        let vel = velocity_fn(sound)
        events.push((start_tick, 1, midi.value, vel))
        events.push((end_tick, 0, midi.value, 0))
      }
      Rest(..) => ()
    }
  }

  // Sort by tick, then NoteOff before NoteOn at same tick
  events.sort_by(fn(a, b) {
    let (at, ak, _, _) = a
    let (bt, bk, _, _) = b
    match at == bt {
      false => at - bt
      true => ak - bk
    }
  })

  // Encode events with delta-time
  let mut prev_tick = 0
  for event in events {
    let (tick, kind, pitch, vel) = event
    let delta = tick - prev_tick
    write_vlq(delta, track_data)
    match kind {
      1 => {
        track_data.push(0x90 | channel)
        track_data.push(pitch)
        track_data.push(vel)
      }
      _ => {
        track_data.push(0x80 | channel)
        track_data.push(pitch)
        track_data.push(0)
      }
    }
    prev_tick = tick
  }

  // End of Track
  track_data.push(0)
  track_data.push(0xFF)
  track_data.push(0x2F)
  track_data.push(0x00)

  track_data
}

///|
/// Encode ScheduledSound arrays to MIDI file bytes (Standard MIDI File format 1).
/// Returns Array[Int] (0-255 values) representing the SMF binary.
/// Produces 5 tracks: meta (track 0), melody ch0, comping ch1, bass ch2, drum ch9.
pub fn encode_to_midi(
  melody_sounds : Array[@music.ScheduledSound],
  comping_sounds : Array[@music.ScheduledSound],
  bass_sounds : Array[@music.ScheduledSound],
  drum_sounds : Array[@music.ScheduledSound],
  bpm : Int,
  time_signature? : @music.TimeSignature = @music.TimeSignature::default(),
  key_signature? : @music.KeySignature = @music.KeySignature::c_major(),
  text? : String = "",
) -> Array[Int] {
  let meta_track = make_meta_track(bpm, time_signature, key_signature, text)
  let melody_track = make_instrument_track(
    0,
    Some(0),
    100,
    melody_sounds,
    bpm,
    fn(s) { melody_velocity(s.tone_origin) },
  )
  let comping_track = make_instrument_track(
    1,
    Some(0),
    50,
    comping_sounds,
    bpm,
    fn(_) { 64 },
  )
  let bass_track = make_instrument_track(2, Some(32), 70, bass_sounds, bpm, fn(
    _,
  ) {
    70
  })
  let drum_track = make_instrument_track(9, None, 25, drum_sounds, bpm, fn(s) {
    match s.sound_event {
      Note(midi~, ..) => drum_velocity(midi)
      _ => 64
    }
  })

  let buf : Array[Int] = []

  // Header chunk: MThd, length=6, format=1, 5 tracks, 480 ticks/quarter
  buf.push(0x4D) // M
  buf.push(0x54) // T
  buf.push(0x68) // h
  buf.push(0x64) // d
  buf.push(0)
  buf.push(0)
  buf.push(0)
  buf.push(6)
  buf.push(0)
  buf.push(1) // format = 1 (Parallel)
  buf.push(0)
  buf.push(5) // 5 tracks
  buf.push(1)
  buf.push(0xE0) // 480 ticks/quarter note (0x01E0)

  write_track(buf, meta_track)
  write_track(buf, melody_track)
  write_track(buf, comping_track)
  write_track(buf, bass_track)
  write_track(buf, drum_track)

  buf
}
