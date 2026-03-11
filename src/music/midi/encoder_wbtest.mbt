///|
fn make_note_sound(
  midi_val : Int,
  start_seconds : Double,
  duration_seconds : Double,
) -> @music.ScheduledSound {
  guard @music.MidiNumber::new(midi_val) is Some(midi) else {
    abort("invalid midi value in test")
  }
  @music.ScheduledSound::{
    sound_event: @music.Note(midi~, duration=@music.Quarter),
    duration: @music.Duration::from_seconds(duration_seconds),
    start_time: @music.Duration::from_seconds(start_seconds),
    tone_origin: None,
  }
}

///|
fn make_rest_sound(
  start_seconds : Double,
  duration_seconds : Double,
) -> @music.ScheduledSound {
  @music.ScheduledSound::{
    sound_event: @music.Rest(duration=@music.Quarter),
    duration: @music.Duration::from_seconds(duration_seconds),
    start_time: @music.Duration::from_seconds(start_seconds),
    tone_origin: None,
  }
}

///|
test "write_vlq: values 0 and 127 encode as single byte" {
  let buf : Array[Int] = []
  write_vlq(0, buf)
  inspect(buf, content="[0]")
  let buf2 : Array[Int] = []
  write_vlq(127, buf2)
  inspect(buf2, content="[127]")
}

///|
test "write_vlq: values 128 and 255 encode as two bytes" {
  let buf : Array[Int] = []
  write_vlq(128, buf)
  inspect(buf, content="[129, 0]") // 0x81, 0x00
  let buf2 : Array[Int] = []
  write_vlq(255, buf2)
  inspect(buf2, content="[129, 127]") // 0x81, 0x7F
}

///|
test "write_vlq: values 16383 and 16384" {
  let buf : Array[Int] = []
  write_vlq(16383, buf)
  inspect(buf, content="[255, 127]") // 0xFF, 0x7F
  let buf2 : Array[Int] = []
  write_vlq(16384, buf2)
  inspect(buf2, content="[129, 128, 0]") // 0x81, 0x80, 0x00
}

///|
test "encode_to_midi: header bytes match SMF spec" {
  let midi = encode_to_midi([], 120)
  // Header: MThd + length=6 + format=0 + 1 track + 480 ticks
  let header = midi.iter().take(14).collect()
  inspect(header, content="[77, 84, 104, 100, 0, 0, 0, 6, 0, 0, 0, 1, 1, 224]")
  // 0x4D=77, 0x54=84, 0x68=104, 0x64=100
  // 0x01=1, 0xE0=224 => 480 ticks
}

///|
test "encode_to_midi: tempo event correct for 120 BPM" {
  let midi = encode_to_midi([], 120)
  // Track chunk starts at byte 14 (after MThd header)
  // MTrk header is 8 bytes (4 id + 4 length)
  // Tempo event starts at byte 22: delta=0, FF 51 03, then 3 bytes
  // microseconds = 60000000/120 = 500000 = 0x07A120
  let tempo_bytes = midi.iter().drop(22).take(7).collect()
  inspect(tempo_bytes, content="[0, 255, 81, 3, 7, 161, 32]")
  // 0x07=7, 0xA1=161, 0x20=32
}

///|
test "encode_to_midi: single note produces Note On and Note Off" {
  // 120 BPM: 1 beat = 0.5s, 480 ticks = 0.5s
  // start=0s => tick=0, duration=0.5s => end_tick=480
  let sound = make_note_sound(60, 0.0, 0.5)
  let midi = encode_to_midi([sound], 120)
  // After header(14) + MTrk header(8) + tempo event(7) = byte 29
  // Note On: delta=0 (VLQ=0x00), 0x90, pitch=60, vel=64
  // Note Off: delta=480 ticks (VLQ=0x83,0x60), 0x80, pitch=60, 0x00
  let events = midi.iter().drop(29).collect()
  inspect(
    events,
    content="[0, 144, 60, 64, 131, 96, 128, 60, 0, 0, 255, 47, 0]",
  )
  // 0x90=144, 0x80=128, 480 as VLQ = 0x83 0x60 = [131, 96]
  // trailing: EOT = [0, 0xFF, 0x2F, 0x00]
}

///|
test "encode_to_midi: rest sounds are excluded" {
  let rest = make_rest_sound(0.0, 0.5)
  let midi_with_rest = encode_to_midi([rest], 120)
  let midi_empty = encode_to_midi([], 120)
  // Both should have the same length (rest produces no note events)
  inspect(midi_with_rest.length() == midi_empty.length(), content="true")
}

///|
test "encode_to_midi: end of track marker present" {
  let midi = encode_to_midi([], 120)
  let n = midi.length()
  // Last 4 bytes: VLQ(0)=0x00, 0xFF, 0x2F, 0x00
  let eot = midi.iter().drop(n - 4).collect()
  inspect(eot, content="[0, 255, 47, 0]")
  // 0xFF=255, 0x2F=47
}

///|
test "encode_to_midi: multiple notes ordered by start time" {
  // Two notes: C4 at 0s, E4 at 0.5s (both 0.5s duration at 120 BPM)
  let c4 = make_note_sound(60, 0.0, 0.5)
  let e4 = make_note_sound(64, 0.5, 0.5)
  let midi = encode_to_midi([c4, e4], 120)
  // After header(14) + MTrk header(8) + tempo(7) = byte 29
  // C4 Note On:  delta=0,   0x90, 60, 64
  // C4 Note Off: delta=480, 0x80, 60, 0   (480 ticks VLQ = 0x83 0x60)
  // E4 Note On:  delta=0,   0x90, 64, 64
  // E4 Note Off: delta=480, 0x80, 64, 0
  let events = midi.iter().drop(29).collect()
  inspect(
    events,
    content="[0, 144, 60, 64, 131, 96, 128, 60, 0, 0, 144, 64, 64, 131, 96, 128, 64, 0, 0, 255, 47, 0]",
  )
}
