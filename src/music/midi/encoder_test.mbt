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
test "encode_to_midi: header bytes match SMF spec with 5 tracks" {
  let midi = encode_to_midi([], [], [], [], 120)
  // Header: MThd + length=6 + format=1 (Parallel) + 5 tracks + 480 ticks
  let header = midi.iter().take(14).collect()
  inspect(header, content="[77, 84, 104, 100, 0, 0, 0, 6, 0, 1, 0, 5, 1, 224]")
  // 0x4D=77, 0x54=84, 0x68=104, 0x64=100
  // format=1 (Parallel), 5 tracks, 0x01E0=480 ticks
}

///|
test "encode_to_midi: tempo event correct for 120 BPM" {
  let midi = encode_to_midi([], [], [], [], 120)
  // Meta track chunk starts at byte 14 (after MThd header)
  // MTrk header is 8 bytes (4 id + 4 length)
  // Tempo event starts at byte 22: delta=0, FF 51 03, then 3 bytes
  // microseconds = 60000000/120 = 500000 = 0x07A120
  let tempo_bytes = midi.iter().drop(22).take(7).collect()
  inspect(tempo_bytes, content="[0, 255, 81, 3, 7, 161, 32]")
  // 0x07=7, 0xA1=161, 0x20=32
}

///|
test "encode_to_midi: single note produces Note On and Note Off" {
  // 120 BPM: 1 beat = 0.5s, 480 ticks = 0.5s; tone_origin=None → velocity=80
  // Layout: header(14) + meta_chunk(33) + melody_MTrk_header(8) = 55
  // Meta data = tempo(7)+time_sig(8)+key_sig(6)+EOT(4) = 25; chunk = 8+25 = 33
  // Melody data: PC[0,192,0] + CC7[0,176,7,100] + NoteOn + NoteOff + EOT
  let sound = make_note_sound(60, 0.0, 0.5)
  let midi = encode_to_midi([sound], [], [], [], 120)
  let events = midi.iter().drop(55).take(20).collect()
  inspect(
    events,
    content="[0, 192, 0, 0, 176, 7, 100, 0, 144, 60, 80, 131, 96, 128, 60, 0, 0, 255, 47, 0]",
  )
  // PC: C0 00; CC7: B0 07 64=100; NoteOn: 90 3C 50=80; NoteOff: 80 3C 00 at 480 ticks VLQ=[131,96]
}

///|
test "encode_to_midi: rest sounds are excluded" {
  let rest = make_rest_sound(0.0, 0.5)
  let midi_with_rest = encode_to_midi([rest], [], [], [], 120)
  let midi_empty = encode_to_midi([], [], [], [], 120)
  // Both should have the same length (rest produces no note events)
  inspect(midi_with_rest.length() == midi_empty.length(), content="true")
}

///|
test "encode_to_midi: end of track marker present" {
  let midi = encode_to_midi([], [], [], [], 120)
  let n = midi.length()
  // Last 4 bytes: VLQ(0)=0x00, 0xFF, 0x2F, 0x00
  let eot = midi.iter().drop(n - 4).collect()
  inspect(eot, content="[0, 255, 47, 0]")
  // 0xFF=255, 0x2F=47
}

///|
test "encode_to_midi: multiple notes ordered by start time" {
  // Two notes: C4 at 0s, E4 at 0.5s (both 0.5s duration at 120 BPM)
  // tone_origin=None → velocity=80 for both
  let c4 = make_note_sound(60, 0.0, 0.5)
  let e4 = make_note_sound(64, 0.5, 0.5)
  let midi = encode_to_midi([c4, e4], [], [], [], 120)
  let events = midi.iter().drop(55).take(29).collect()
  inspect(
    events,
    content="[0, 192, 0, 0, 176, 7, 100, 0, 144, 60, 80, 131, 96, 128, 60, 0, 0, 144, 64, 80, 131, 96, 128, 64, 0, 0, 255, 47, 0]",
  )
}

///|
test "encode_to_midi: bass track has Program Change ch2 prog32 and CC7" {
  // Empty sounds; layout:
  // header(14) + meta_chunk(33) + melody_chunk(19) + comping_chunk(19) = 85
  // melody_chunk = 8 + PC(3)+CC7(4)+EOT(4) = 8+11 = 19
  // comping_chunk = 8+11 = 19
  // bass MTrk header at 85, data at 93
  // bass data: PC[0,194,32] + CC7[0,178,7,70] + EOT[0,255,47,0]
  let midi = encode_to_midi([], [], [], [], 120)
  let bass_data = midi.iter().drop(93).take(11).collect()
  inspect(bass_data, content="[0, 194, 32, 0, 178, 7, 70, 0, 255, 47, 0]")
  // 0xC2=194, 32=prog32; 0xB2=178, CC7=7, vol=70
}

///|
test "encode_to_midi: drum track uses channel 9 for Note On" {
  // Kick at midi=36, start=0s, dur=0.5s → velocity=85
  // Layout after empty melody/comping/bass chunks:
  // header(14)+meta(33)+melody(19)+comping(19)+bass(19) = 104
  // drum MTrk header at 104, data at 112
  // drum data: CC7[0,185,7,25] + NoteOn[0,153,36,85] + NoteOff[131,96,137,36,0] + EOT
  let kick = make_note_sound(36, 0.0, 0.5)
  let midi = encode_to_midi([], [], [], [kick], 120)
  let drum_data = midi.iter().drop(112).collect()
  inspect(
    drum_data,
    content="[0, 185, 7, 25, 0, 153, 36, 85, 131, 96, 137, 36, 0, 0, 255, 47, 0]",
  )
  // CC7: 0xB9=185, ch9; NoteOn: 0x99=153, ch9; NoteOff: 0x89=137, ch9
}
