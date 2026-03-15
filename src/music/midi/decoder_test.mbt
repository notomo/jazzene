///|
/// Build a minimal SMF format-0 byte array with one track of given data.
fn smf0(tpq : Int, track_data : Array[Int]) -> Array[Int] {
  let len = track_data.length()
  [
    77,
    84,
    104,
    100, // MThd magic
    0,
    0,
    0,
    6, // header length = 6
    0,
    0, // format 0
    0,
    1, // 1 track
    (tpq >> 8) & 0xFF,
    tpq & 0xFF, // ticks per quarter
    77,
    84,
    114,
    107, // MTrk magic
    (len >> 24) & 0xFF,
    (len >> 16) & 0xFF,
    (len >> 8) & 0xFF,
    len & 0xFF,
  ] +
  track_data
}

///|
test "decode_midi: returns None for too-short input" {
  inspect(decode_midi([]).map(fn(m) { m.bpm }), content="None")
  inspect(
    decode_midi([77, 84, 104, 100, 0, 0, 0, 6, 0, 0, 0, 1]).map(fn(m) { m.bpm }),
    content="None",
  )
}

///|
test "decode_midi: returns None for wrong magic bytes" {
  let bytes = [
    0, 84, 104, 100, 0, 0, 0, 6, 0, 0, 0, 1, 1, 224, // wrong first magic byte
     77, 84, 114, 107, 0, 0, 0, 4, 0, 255, 47, 0,
  ]
  inspect(decode_midi(bytes).map(fn(m) { m.bpm }), content="None")
}

///|
test "decode_midi: returns None for SMPTE timecode division" {
  let bytes = [
    77, 84, 104, 100, 0, 0, 0, 6, 0, 0, 0, 1, 128, 0, // division=0x8000
     77, 84, 114, 107, 0, 0, 0, 4, 0, 255, 47, 0,
  ]
  inspect(decode_midi(bytes).map(fn(m) { m.bpm }), content="None")
}

///|
test "decode_midi: returns None for format 2" {
  let bytes = [
    77, 84, 104, 100, 0, 0, 0, 6, 0, 2, 0, 1, 1, 224, // format=2
     77, 84, 114, 107, 0, 0, 0, 4, 0, 255, 47, 0,
  ]
  inspect(decode_midi(bytes).map(fn(m) { m.bpm }), content="None")
}

///|
test "decode_midi: minimal valid SMF returns empty sounds and default BPM" {
  let result = decode_midi(smf0(480, [0, 255, 47, 0]))
  inspect(result.map(fn(m) { m.melody_sounds.length() }), content="Some(0)")
  inspect(result.map(fn(m) { m.comping_sounds.length() }), content="Some(0)")
  inspect(result.map(fn(m) { m.bass_sounds.length() }), content="Some(0)")
  inspect(result.map(fn(m) { m.drum_sounds.length() }), content="Some(0)")
  inspect(result.map(fn(m) { m.bpm }), content="Some(Some(120))")
  inspect(
    result.map(fn(m) { m.key.map(fn(k) { k.root }) }),
    content="Some(None)",
  )
  inspect(
    result.map(fn(m) { m.time_sig.map(fn(ts) { ts.numerator }) }),
    content="Some(None)",
  )
  inspect(result.map(fn(m) { m.measure_count }), content="Some(None)")
}

///|
test "decode_midi: note on channel 0 appears in melody with correct timing" {
  // 120 BPM default (500000 us/beat), 480 TPQ → 480 ticks = 500 ms
  let track_data = [
    0, 144, 60, 80, // delta=0, NoteOn ch0, C4, vel=80
     131, 96, 128, 60, 0, // delta=480, NoteOff ch0, C4, vel=0
     0, 255, 47, 0,
  ] // EOT
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.melody_sounds.length() }), content="Some(1)")
  inspect(result.map(fn(m) { m.comping_sounds.length() }), content="Some(0)")
  inspect(
    result.map(fn(m) { m.melody_sounds[0].start_time.to_milliseconds() }),
    content="Some(0)",
  )
  inspect(
    result.map(fn(m) { m.melody_sounds[0].duration.to_milliseconds() }),
    content="Some(500)",
  )
  inspect(
    result.map(fn(m) { m.melody_sounds[0].midi().map(fn(n) { n.value }) }),
    content="Some(Some(60))",
  )
}

///|
test "decode_midi: note on channel 1 appears in comping" {
  let track_data = [
    0, 145, 64, 80, // NoteOn ch1, E4
     131, 96, 129, 64, 0, // NoteOff ch1, E4
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.comping_sounds.length() }), content="Some(1)")
  inspect(result.map(fn(m) { m.melody_sounds.length() }), content="Some(0)")
  inspect(
    result.map(fn(m) { m.comping_sounds[0].midi().map(fn(n) { n.value }) }),
    content="Some(Some(64))",
  )
}

///|
test "decode_midi: note on channel 2 appears in bass" {
  let track_data = [
    0, 146, 36, 80, // NoteOn ch2, C2
     131, 96, 130, 36, 0, // NoteOff ch2
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.bass_sounds.length() }), content="Some(1)")
  inspect(
    result.map(fn(m) { m.bass_sounds[0].midi().map(fn(n) { n.value }) }),
    content="Some(Some(36))",
  )
}

///|
test "decode_midi: note on channel 9 appears in drums" {
  let track_data = [
    0, 153, 36, 85, // NoteOn ch9, kick drum
     131, 96, 137, 36, 0, // NoteOff ch9
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.drum_sounds.length() }), content="Some(1)")
  inspect(result.map(fn(m) { m.melody_sounds.length() }), content="Some(0)")
  inspect(
    result.map(fn(m) { m.drum_sounds[0].midi().map(fn(n) { n.value }) }),
    content="Some(Some(36))",
  )
}

///|
test "decode_midi: notes on other channels are ignored" {
  let track_data = [
    0, 147, 60, 80, // NoteOn ch3 (not melody/comping/bass/drums)
     131, 96, 131, 60, 0, // NoteOff ch3
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.melody_sounds.length() }), content="Some(0)")
  inspect(result.map(fn(m) { m.comping_sounds.length() }), content="Some(0)")
  inspect(result.map(fn(m) { m.bass_sounds.length() }), content="Some(0)")
  inspect(result.map(fn(m) { m.drum_sounds.length() }), content="Some(0)")
}

///|
test "decode_midi: tempo meta event sets BPM" {
  // 0x0F4240 = 1000000 us → 60 BPM
  let track_data = [
    0, 255, 81, 3, 15, 66, 64, // Tempo = 1000000 μs = 60 BPM
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.bpm }), content="Some(Some(60))")
}

///|
test "decode_midi: key signature meta event sf=1 sets G major" {
  let track_data = [
    0, 255, 89, 2, 1, 0, // KeySig, sf=1 (G major)
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(
    result.map(fn(m) { m.key.map(fn(k) { k.root }) }),
    content="Some(Some(G))",
  )
}

///|
test "decode_midi: flat key signature encoded as value >= 128 sets F major" {
  // sf=255 (= -1 signed) → F major
  let track_data = [
    0, 255, 89, 2, 255, 0, // KeySig, sf=255 (-1 = F major)
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(
    result.map(fn(m) { m.key.map(fn(k) { k.root }) }),
    content="Some(Some(F))",
  )
}

///|
test "decode_midi: time signature meta event sets numerator and denominator" {
  // nn=3, dd=2 → 3/4 (denominator = 1 << 2 = 4)
  let track_data = [
    0, 255, 88, 4, 3, 2, 24, 8, // TimeSig 3/4
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(
    result.map(fn(m) { m.time_sig.map(fn(ts) { ts.numerator }) }),
    content="Some(Some(3))",
  )
  inspect(
    result.map(fn(m) { m.time_sig.map(fn(ts) { ts.denominator }) }),
    content="Some(Some(4))",
  )
}

///|
test "decode_midi: Note On with velocity 0 acts as Note Off" {
  let track_data = [
    0, 144, 60, 80, // NoteOn ch0, C4, vel=80
     131, 96, 144, 60, 0, // delta=480, NoteOn ch0, C4, vel=0 (= Note Off)
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.melody_sounds.length() }), content="Some(1)")
  inspect(
    result.map(fn(m) { m.melody_sounds[0].duration.to_milliseconds() }),
    content="Some(500)",
  )
}

///|
test "decode_midi: running status reuses previous status byte" {
  // After NoteOn 0x90, subsequent event without status uses same 0x90
  // NoteOn with vel=0 acts as NoteOff under running status
  let track_data = [
    0, 144, 60, 80, // NoteOn ch0, C4, vel=80 (status=0x90)
     131, 96, 60, 0, // delta=480, running status 0x90, C4, vel=0 (= Note Off)
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.melody_sounds.length() }), content="Some(1)")
  inspect(
    result.map(fn(m) { m.melody_sounds[0].duration.to_milliseconds() }),
    content="Some(500)",
  )
}

///|
test "decode_midi: two simultaneous notes have correct start times" {
  // C4 and E4 both start at tick 0, both end at tick 480
  let track_data = [
    0, 144, 60, 80, // delta=0, NoteOn C4
     0, 144, 64, 80, // delta=0, NoteOn E4
     131, 96, 128, 60, 0, // delta=480, NoteOff C4
     0, 128, 64, 0, // delta=0, NoteOff E4
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.melody_sounds.length() }), content="Some(2)")
  inspect(
    result.map(fn(m) { m.melody_sounds[0].start_time.to_milliseconds() }),
    content="Some(0)",
  )
  inspect(
    result.map(fn(m) { m.melody_sounds[1].start_time.to_milliseconds() }),
    content="Some(0)",
  )
}

///|
test "decode_midi: measure_count is 1 for a note shorter than one measure" {
  // 500ms note; at 120 BPM, 4/4 → ms_per_measure = 2000ms → count = 1
  let track_data = [0, 144, 60, 80, 131, 96, 128, 60, 0, 0, 255, 47, 0]
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.measure_count }), content="Some(Some(1))")
}

///|
test "decode_midi: note timing scales correctly with tempo" {
  // 60 BPM (1000000 us/beat), 480 TPQ → 480 ticks = 1000 ms
  let track_data = [
    0, 255, 81, 3, 15, 66, 64, // Tempo = 1000000 μs = 60 BPM
     0, 144, 60, 80, // NoteOn C4
     131, 96, 128, 60, 0, // NoteOff at tick 480
     0, 255, 47, 0,
  ]
  let result = decode_midi(smf0(480, track_data))
  inspect(result.map(fn(m) { m.bpm }), content="Some(Some(60))")
  inspect(
    result.map(fn(m) { m.melody_sounds[0].duration.to_milliseconds() }),
    content="Some(1000)",
  )
}

///|
test "decode_midi: format 1 with two tracks is parsed correctly" {
  // SMF format 1: separate tempo track + note track
  let tempo_track_data = [
    0, 255, 81, 3, 7, 161, 32, // Tempo = 500000 μs = 120 BPM
     0, 255, 47, 0,
  ]
  let note_track_data = [
    0, 144, 60, 80, // NoteOn ch0, C4
     131, 96, 128, 60, 0, // NoteOff ch0, C4 at tick 480
     0, 255, 47, 0,
  ]
  let tlen1 = tempo_track_data.length()
  let tlen2 = note_track_data.length()
  let bytes = [
      77,
      84,
      104,
      100,
      0,
      0,
      0,
      6,
      0,
      1,
      0,
      2,
      1,
      224, // MThd format=1 tracks=2 tpq=480
      77,
      84,
      114,
      107,
      (tlen1 >> 24) & 0xFF,
      (tlen1 >> 16) & 0xFF,
      (tlen1 >> 8) & 0xFF,
      tlen1 & 0xFF,
    ] +
    tempo_track_data +
    [
      77,
      84,
      114,
      107,
      (tlen2 >> 24) & 0xFF,
      (tlen2 >> 16) & 0xFF,
      (tlen2 >> 8) & 0xFF,
      tlen2 & 0xFF,
    ] +
    note_track_data
  let result = decode_midi(bytes)
  inspect(result.map(fn(m) { m.bpm }), content="Some(Some(120))")
  inspect(result.map(fn(m) { m.melody_sounds.length() }), content="Some(1)")
  inspect(
    result.map(fn(m) { m.melody_sounds[0].duration.to_milliseconds() }),
    content="Some(500)",
  )
}
