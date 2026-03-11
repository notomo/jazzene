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
/// Encode ScheduledSound array to MIDI file bytes (Standard MIDI File format 0).
/// Returns Array[Int] (0-255 values) representing the SMF binary.
/// Optional metadata: time_signature, key_signature, and text (e.g. chords/seed info).
pub fn encode_to_midi(
  sounds : Array[@music.ScheduledSound],
  bpm : Int,
  time_signature? : @music.TimeSignature = @music.TimeSignature::default(),
  key_signature? : @music.KeySignature = @music.KeySignature::c_major(),
  text? : String = "",
) -> Array[Int] {
  // Build events: (tick, kind, pitch) where kind 0=NoteOff, 1=NoteOn
  let events : Array[(Int, Int, Int)] = []
  for sound in sounds {
    match sound.sound_event {
      Note(midi~, ..) => {
        let start_tick = seconds_to_ticks(sound.start_time.to_seconds(), bpm)
        let end_tick = seconds_to_ticks(
          (sound.start_time + sound.duration).to_seconds(),
          bpm,
        )
        events.push((start_tick, 1, midi.value)) // Note On
        events.push((end_tick, 0, midi.value)) // Note Off
      }
      Rest(..) => ()
    }
  }

  // Sort by tick, then by kind (NoteOff=0 before NoteOn=1 at same tick)
  events.sort_by(fn(a, b) {
    let (at, ak, _) = a
    let (bt, bk, _) = b
    match at == bt {
      false => at - bt
      true => ak - bk
    }
  })

  // Build track data
  let track_data : Array[Int] = []

  // Tempo meta-event (delta=0): FF 51 03 + 3 bytes microseconds
  let microseconds = 60000000 / bpm
  track_data.push(0) // delta = 0
  track_data.push(0xFF)
  track_data.push(0x51)
  track_data.push(0x03)
  track_data.push((microseconds >> 16) & 0xFF)
  track_data.push((microseconds >> 8) & 0xFF)
  track_data.push(microseconds & 0xFF)

  // Time signature meta-event (delta=0): FF 58 04 nn dd cc bb
  // dd = denominator as power of 2 (4 -> 2, 8 -> 3)
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
  track_data.push(24) // MIDI clocks per metronome tick
  track_data.push(8) // 32nd notes per 24 MIDI clocks

  // Key signature meta-event (delta=0): FF 59 02 sf mi
  // sf: positive = sharps, negative (two's complement) = flats; mi: 0 = major
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
  track_data.push(0) // major

  // Text meta-event (delta=0): FF 01 len text (chords/seed info)
  if text != "" {
    track_data.push(0)
    track_data.push(0xFF)
    track_data.push(0x01)
    write_vlq(text.length(), track_data)
    for c in text {
      track_data.push(c.to_int())
    }
  }

  // Note events with delta-time encoding
  let mut prev_tick = 0
  for event in events {
    let (tick, kind, pitch) = event
    let delta = tick - prev_tick
    write_vlq(delta, track_data)
    match kind {
      1 => {
        track_data.push(0x90) // Note On channel 0
        track_data.push(pitch)
        track_data.push(64) // velocity
      }
      _ => {
        track_data.push(0x80) // Note Off channel 0
        track_data.push(pitch)
        track_data.push(0)
      }
    }
    prev_tick = tick
  }

  // End of Track meta-event
  track_data.push(0)
  track_data.push(0xFF)
  track_data.push(0x2F)
  track_data.push(0x00)

  // Build final MIDI file
  let buf : Array[Int] = []

  // Header chunk: MThd, length=6, format=0, 1 track, 480 ticks/quarter
  buf.push(0x4D) // M
  buf.push(0x54) // T
  buf.push(0x68) // h
  buf.push(0x64) // d
  buf.push(0)
  buf.push(0)
  buf.push(0)
  buf.push(6) // chunk length = 6
  buf.push(0)
  buf.push(1) // format = 1 (Parallel)
  buf.push(0)
  buf.push(1) // 1 track
  buf.push(1)
  buf.push(0xE0) // 480 ticks/quarter note (0x01E0)

  // Track chunk: MTrk + 4-byte big-endian length
  buf.push(0x4D) // M
  buf.push(0x54) // T
  buf.push(0x72) // r
  buf.push(0x6B) // k
  let track_len = track_data.length()
  buf.push((track_len >> 24) & 0xFF)
  buf.push((track_len >> 16) & 0xFF)
  buf.push((track_len >> 8) & 0xFF)
  buf.push(track_len & 0xFF)

  // Append track data
  for b in track_data {
    buf.push(b)
  }

  buf
}
