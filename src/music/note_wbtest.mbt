///|
test "NoteDuration to_beats" {
  inspect(Eighth.to_beats(), content="0.5")
  inspect(Quarter.to_beats(), content="1")
  inspect(Half.to_beats(), content="2")
}

///|
test "NoteDuration to_beats for dotted notes" {
  inspect(DottedEighth.to_beats(), content="0.75")
  inspect(DottedQuarter.to_beats(), content="1.5")
  inspect(DottedHalf.to_beats(), content="3")
}

///|
test "NoteValue duration with bpm 120" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  inspect(
    Note(midi~, duration=Eighth).duration(bpm).to_milliseconds(),
    content="250",
  )
  inspect(
    Note(midi~, duration=Quarter).duration(bpm).to_milliseconds(),
    content="500",
  )
  inspect(
    Note(midi~, duration=Half).duration(bpm).to_milliseconds(),
    content="1000",
  )
  inspect(Rest(duration=Quarter).duration(bpm).to_milliseconds(), content="500")
}

///|
test "Dotted notes duration with bpm 120" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  inspect(
    Note(midi~, duration=DottedEighth).duration(bpm).to_milliseconds(),
    content="375",
  )
  inspect(
    Note(midi~, duration=DottedQuarter).duration(bpm).to_milliseconds(),
    content="750",
  )
  inspect(
    Note(midi~, duration=DottedHalf).duration(bpm).to_milliseconds(),
    content="1500",
  )
  inspect(
    Rest(duration=DottedQuarter).duration(bpm).to_milliseconds(),
    content="750",
  )
}

///|
test "calculate_total_duration with bpm 120" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()

  // Single quarter note: 500ms
  let notes1 = [Note(midi~, duration=Quarter)]
  let sounds1 = NoteValueSound::from_note_values(notes1, bpm)
  inspect(calculate_total_duration(sounds1).to_milliseconds(), content="500")

  // Two quarter notes: 1000ms
  let notes2 = [Note(midi~, duration=Quarter), Note(midi~, duration=Quarter)]
  let sounds2 = NoteValueSound::from_note_values(notes2, bpm)
  inspect(calculate_total_duration(sounds2).to_milliseconds(), content="1000")

  // Mixed durations: Half + Quarter + Eighth = 2 + 1 + 0.5 beats = 1750ms
  let notes3 = [
    Note(midi~, duration=Half),
    Note(midi~, duration=Quarter),
    Note(midi~, duration=Eighth),
  ]
  let sounds3 = NoteValueSound::from_note_values(notes3, bpm)
  inspect(calculate_total_duration(sounds3).to_milliseconds(), content="1750")

  // With rests
  let notes4 = [
    Note(midi~, duration=Quarter),
    Rest(duration=Quarter),
    Note(midi~, duration=Quarter),
  ]
  let sounds4 = NoteValueSound::from_note_values(notes4, bpm)
  inspect(calculate_total_duration(sounds4).to_milliseconds(), content="1500")
}

///|
test "calculate_total_duration with bpm 90" {
  let bpm = 90
  let midi = MidiNumber::new(60).unwrap()

  // Quarter note at 90 bpm: 60000/90 = 666.6666666666666ms
  let notes = [Note(midi~, duration=Quarter)]
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  inspect(
    calculate_total_duration(sounds).to_milliseconds(),
    content="666.6666666666666",
  )

  // Half note: 2 beats = 1333.3333333333333ms (60000/90 * 2)
  let notes2 = [Note(midi~, duration=Half)]
  let sounds2 = NoteValueSound::from_note_values(notes2, bpm)
  inspect(
    calculate_total_duration(sounds2).to_milliseconds(),
    content="1333.3333333333333",
  )
}

///|
test "calculate_total_duration empty array" {
  let notes : Array[NoteValue] = []
  let sounds = NoteValueSound::from_note_values(notes, 120)
  inspect(calculate_total_duration(sounds).to_milliseconds(), content="0")
}

///|
test "calculate_total_duration with mixed dotted and non-dotted notes" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()

  // Quarter + DottedEighth + Quarter = 1 + 0.75 + 1 = 2.75 beats = 1375ms
  let notes1 = [
    Note(midi~, duration=Quarter),
    Note(midi~, duration=DottedEighth),
    Note(midi~, duration=Quarter),
  ]
  let sounds1 = NoteValueSound::from_note_values(notes1, bpm)
  inspect(calculate_total_duration(sounds1).to_milliseconds(), content="1375")

  // DottedQuarter + Rest(Eighth) + DottedHalf = 1.5 + 0.5 + 3.0 = 5.0 beats = 2500ms
  let notes2 = [
    Note(midi~, duration=DottedQuarter),
    Rest(duration=Eighth),
    Note(midi~, duration=DottedHalf),
  ]
  let sounds2 = NoteValueSound::from_note_values(notes2, bpm)
  inspect(calculate_total_duration(sounds2).to_milliseconds(), content="2500")
}

///|
test "in_range - position before note starts" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // starts at 0ms, duration 500ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let sound = sounds[0]

  // Position -100ms is before the note starts
  let in_range = sound.in_range(Duration::from_milliseconds(-100))
  inspect(in_range, content="false")
}

///|
test "in_range - position at exact start" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // starts at 0ms, duration 500ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let sound = sounds[0]

  // Position at exact start (0ms) should be in range
  let in_range = sound.in_range(Duration::from_milliseconds(0))
  inspect(in_range, content="true")
}

///|
test "in_range - position in middle of note" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // starts at 0ms, duration 500ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let sound = sounds[0]

  // Position in middle (250ms) should be in range
  let in_range = sound.in_range(Duration::from_milliseconds(250))
  inspect(in_range, content="true")
}

///|
test "in_range - position just before end" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // starts at 0ms, duration 500ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let sound = sounds[0]

  // Position just before end (499ms) should be in range
  let in_range = sound.in_range(Duration::from_milliseconds(499))
  inspect(in_range, content="true")
}

///|
test "in_range - position at exact end" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // starts at 0ms, duration 500ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let sound = sounds[0]

  // Position at exact end (500ms) should NOT be in range (exclusive end)
  let in_range = sound.in_range(Duration::from_milliseconds(500))
  inspect(in_range, content="false")
}

///|
test "in_range - position after note ends" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // starts at 0ms, duration 500ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let sound = sounds[0]

  // Position after note ends (600ms) should NOT be in range
  let in_range = sound.in_range(Duration::from_milliseconds(600))
  inspect(in_range, content="false")
}

///|
test "in_range - with different BPM" {
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)]

  // BPM 120: Quarter note = 500ms
  let sounds_120 = NoteValueSound::from_note_values(notes, 120)
  let sound_120 = sounds_120[0]
  inspect(sound_120.in_range(Duration::from_milliseconds(250)), content="true")
  inspect(sound_120.in_range(Duration::from_milliseconds(500)), content="false")

  // BPM 90: Quarter note = 666.666...ms
  let sounds_90 = NoteValueSound::from_note_values(notes, 90)
  let sound_90 = sounds_90[0]
  inspect(sound_90.in_range(Duration::from_milliseconds(250)), content="true")
  inspect(
    sound_90.in_range(Duration::from_milliseconds(666.6666666666666)),
    content="false",
  )
}

///|
test "in_range - rest note" {
  let bpm = 120
  let notes = [Rest(duration=Quarter)] // rest at 0-500ms
  let sounds = NoteValueSound::from_note_values(notes, bpm)
  let sound = sounds[0]

  // Rest should have the same in_range behavior as notes
  inspect(sound.in_range(Duration::from_milliseconds(250)), content="true")
  inspect(sound.in_range(Duration::from_milliseconds(500)), content="false")
}

///|
test "calculate_playing_notes - note playing at exact start position" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration at 120 BPM
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)

  // Position at exact start (0ms) should be playing
  let active = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(0),
  )
  let midi_numbers = active
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_numbers, content="[60]")
}

///|
test "calculate_playing_notes - note playing in middle of duration" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)

  // Position in middle (250ms) should be playing
  let active = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(250),
  )
  let midi_numbers = active
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_numbers, content="[60]")
}

///|
test "calculate_playing_notes - note just before end" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)

  // Position just before end (499ms) should still be playing
  let active = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(499),
  )
  let midi_numbers = active
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_numbers, content="[60]")
}

///|
test "calculate_playing_notes - position at note end boundary" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)

  // Position at exact end (500ms) should NOT be playing (exclusive end)
  let active = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(500),
  )
  let midi_numbers = active
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_numbers, content="[]")
}

///|
test "calculate_playing_notes - position after note ends" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // 500ms duration
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)

  // Position after note ends should not be playing
  let active = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(600),
  )
  let midi_numbers = active
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_numbers, content="[]")
}

///|
test "calculate_playing_notes - position before note starts" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)] // starts at 0ms
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)

  // Negative position should not be playing
  let active = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(-100),
  )
  let midi_numbers = active
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_numbers, content="[]")
}

///|
test "calculate_playing_notes - rest notes are included" {
  let bpm = 120
  let notes = [Rest(duration=Quarter)] // 500ms rest
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)

  // Position during rest should return the rest
  let active = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(250),
  )
  // Rests don't have MIDI values, so MIDI extraction returns empty
  let midi_numbers = active
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_numbers, content="[]")
}

///|
test "calculate_playing_notes - multiple sequential notes" {
  let bpm = 120
  let midi1 = MidiNumber::new(60).unwrap()
  let midi2 = MidiNumber::new(64).unwrap()
  let midi3 = MidiNumber::new(67).unwrap()
  // Note 1: 0-500ms, Note 2: 500-1000ms, Note 3: 1000-1500ms
  let notes = [
    Note(midi=midi1, duration=Quarter),
    Note(midi=midi2, duration=Quarter),
    Note(midi=midi3, duration=Quarter),
  ]
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)

  // First note playing
  let active1 = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(250),
  )
  let midi1_nums = active1.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
  inspect(midi1_nums, content="[60]")

  // Second note playing
  let active2 = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(750),
  )
  let midi2_nums = active2.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
  inspect(midi2_nums, content="[64]")

  // Third note playing
  let active3 = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(1250),
  )
  let midi3_nums = active3.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
  inspect(midi3_nums, content="[67]")
}

///|
test "calculate_playing_notes - notes with rests in between" {
  let bpm = 120
  let midi1 = MidiNumber::new(60).unwrap()
  let midi2 = MidiNumber::new(64).unwrap()
  // Note 1: 0-500ms, Rest: 500-1000ms, Note 2: 1000-1500ms
  let notes = [
    Note(midi=midi1, duration=Quarter),
    Rest(duration=Quarter),
    Note(midi=midi2, duration=Quarter),
  ]
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)

  // First note playing
  let active1 = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(250),
  )
  let midi1_nums = active1.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
  inspect(midi1_nums, content="[60]")

  // During rest, nothing playing
  let active_rest = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(750),
  )
  let rest_midi = active_rest
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(rest_midi, content="[]")

  // Second note playing
  let active2 = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(1250),
  )
  let midi2_nums = active2.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
  inspect(midi2_nums, content="[64]")
}

///|
test "calculate_playing_notes - empty note array" {
  let notes : Array[NoteValue] = []
  let sounds_list = NoteValueSound::from_note_values(notes, 120)
  let active = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(100),
  )
  let midi_numbers = active
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_numbers, content="[]")
}

///|
test "calculate_playing_notes - different bpm" {
  let midi = MidiNumber::new(60).unwrap()
  let notes = [Note(midi~, duration=Quarter)]

  // bpm 120: Quarter note = 500ms
  let sounds_120 = NoteValueSound::from_note_values(notes, 120)
  let active_120_mid = calculate_playing_notes(
    sounds_120,
    Duration::from_milliseconds(250.0),
  )
  let midi_120_mid = active_120_mid
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_120_mid, content="[60]")
  let active_120_end = calculate_playing_notes(
    sounds_120,
    Duration::from_milliseconds(500.0),
  )
  let midi_120_end = active_120_end
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_120_end, content="[]")

  // bpm 90: Quarter note = 666.666...ms
  let sounds_90 = NoteValueSound::from_note_values(notes, 90)
  let active_90_mid = calculate_playing_notes(
    sounds_90,
    Duration::from_milliseconds(250.0),
  )
  let midi_90_mid = active_90_mid
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_90_mid, content="[60]")
  let active_90_end = calculate_playing_notes(
    sounds_90,
    Duration::from_milliseconds(666.6666666666666),
  )
  let midi_90_end = active_90_end
    .filter_map(fn(s) { s.midi() })
    .map(fn(m) { m.value })
  inspect(midi_90_end, content="[]")
}

///|
test "calculate_playing_notes - mixed note durations" {
  let bpm = 120
  let midi1 = MidiNumber::new(60).unwrap()
  let midi2 = MidiNumber::new(64).unwrap()
  let midi3 = MidiNumber::new(67).unwrap()
  // Half (1000ms) + Quarter (500ms) + Eighth (250ms)
  let notes = [
    Note(midi=midi1, duration=Half), // 0-1000ms
    Note(midi=midi2, duration=Quarter), // 1000-1500ms
    Note(midi=midi3, duration=Eighth), // 1500-1750ms
  ]
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)
  let active1 = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(500),
  )
  let midi1_nums = active1.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
  inspect(midi1_nums, content="[60]")
  let active2 = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(1250),
  )
  let midi2_nums = active2.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
  inspect(midi2_nums, content="[64]")
  let active3 = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(1625),
  )
  let midi3_nums = active3.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
  inspect(midi3_nums, content="[67]")
}

///|
test "calculate_playing_notes - multiple notes with same MIDI number" {
  let bpm = 120
  let midi = MidiNumber::new(60).unwrap()
  // Same note repeated
  let notes = [
    Note(midi~, duration=Quarter), // 0-500ms
    Note(midi~, duration=Quarter),
  ] // 500-1000ms
  let sounds_list = NoteValueSound::from_note_values(notes, bpm)

  // First occurrence
  let active1 = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(250),
  )
  let midi1_nums = active1.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
  inspect(midi1_nums, content="[60]")

  // Second occurrence
  let active2 = calculate_playing_notes(
    sounds_list,
    Duration::from_milliseconds(750),
  )
  let midi2_nums = active2.filter_map(fn(s) { s.midi() }).map(fn(m) { m.value })
  inspect(midi2_nums, content="[60]")
}

///|
test "slice_notes extracts notes in range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms - 500ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms - 1000ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms - 1500ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(500)
  let lookahead = Duration::from_milliseconds(1000)
  let sliced = slice_notes(sounds_list, position, lookahead)
  inspect(sliced.length(), content="2")
  inspect(sliced[0].midi().unwrap().value, content="62")
  inspect(sliced[0].start_time.to_milliseconds(), content="500")
  inspect(sliced[1].midi().unwrap().value, content="64")
  inspect(sliced[1].start_time.to_milliseconds(), content="1000")
}

///|
test "slice_notes includes rests" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms
    Rest(duration=Quarter), // 500ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1500)
  let sliced = slice_notes(sounds_list, position, lookahead)
  inspect(sliced.length(), content="3")
  inspect(sliced[0].midi().unwrap().value, content="60")
  inspect(sliced[1].midi(), content="None")
  inspect(sliced[2].midi().unwrap().value, content="64")
}

///|
test "slice_notes excludes notes outside range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms
    Note(midi=MidiNumber::{ value: 65 }, duration=Quarter), // 1500ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(500)
  let lookahead = Duration::from_milliseconds(1000)
  let sliced = slice_notes(sounds_list, position, lookahead)
  inspect(sliced.length(), content="2")
  inspect(sliced[0].midi().unwrap().value, content="62")
  inspect(sliced[1].midi().unwrap().value, content="64")
}

///|
test "slice_notes returns empty for empty input" {
  let note_values : Array[NoteValue] = []
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1000)
  let sliced = slice_notes(sounds_list, position, lookahead)
  inspect(sliced.length(), content="0")
}

///|
test "slice_notes returns empty when all notes outside range" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(1000)
  let lookahead = Duration::from_milliseconds(500)
  let sliced = slice_notes(sounds_list, position, lookahead)
  inspect(sliced.length(), content="0")
}

///|
test "slice_notes stops early when past window" {
  let note_values : Array[NoteValue] = [
    Note(midi=MidiNumber::{ value: 60 }, duration=Quarter), // 0ms
    Note(midi=MidiNumber::{ value: 62 }, duration=Quarter), // 500ms
    Note(midi=MidiNumber::{ value: 64 }, duration=Quarter), // 1000ms
    Note(midi=MidiNumber::{ value: 65 }, duration=Quarter), // 1500ms
    Note(midi=MidiNumber::{ value: 67 }, duration=Quarter), // 2000ms
  ]
  let bpm = 120
  let sounds_list = NoteValueSound::from_note_values(note_values, bpm)
  let position = Duration::from_milliseconds(0)
  let lookahead = Duration::from_milliseconds(1000)
  let sliced = slice_notes(sounds_list, position, lookahead)
  // Should only process first two notes and break early
  inspect(sliced.length(), content="2")
  inspect(sliced[0].midi().unwrap().value, content="60")
  inspect(sliced[1].midi().unwrap().value, content="62")
}
