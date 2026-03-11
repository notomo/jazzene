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
pub fn encode_to_midi(
  sounds : Array[@music.ScheduledSound],
  bpm : Int,
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
