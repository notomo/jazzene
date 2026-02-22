///|
test "DrumVoice::midi_number returns GM standard numbers" {
  assert_eq(DrumVoice::Kick.midi_number(), MidiNumber::{ value: 36 })
  assert_eq(DrumVoice::Snare.midi_number(), MidiNumber::{ value: 38 })
  assert_eq(DrumVoice::HiHat.midi_number(), MidiNumber::{ value: 42 })
  assert_eq(DrumVoice::Ride.midi_number(), MidiNumber::{ value: 51 })
}

///|
test "DrumVoice::from_midi returns correct voice for valid numbers" {
  assert_eq(DrumVoice::from_midi(MidiNumber::{ value: 36 }), Some(Kick))
  assert_eq(DrumVoice::from_midi(MidiNumber::{ value: 38 }), Some(Snare))
  assert_eq(DrumVoice::from_midi(MidiNumber::{ value: 42 }), Some(HiHat))
  assert_eq(DrumVoice::from_midi(MidiNumber::{ value: 51 }), Some(Ride))
}

///|
test "DrumVoice::from_midi returns None for non-drum numbers" {
  assert_eq(DrumVoice::from_midi(MidiNumber::{ value: 60 }), None)
  assert_eq(DrumVoice::from_midi(MidiNumber::{ value: 0 }), None)
  assert_eq(DrumVoice::from_midi(MidiNumber::{ value: 127 }), None)
}

///|
test "DrumVoice::from_midi roundtrips with midi_number" {
  let voices : Array[DrumVoice] = [Kick, Snare, HiHat, Ride]
  for voice in voices {
    assert_eq(DrumVoice::from_midi(voice.midi_number()), Some(voice))
  }
}

///|
test "generate_drum_sounds 4/4 produces correct number of hits" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  // jazz_4_4 pattern has 8 hits per measure (HiHat+Kick, HiHat+Snare, HiHat+Kick, HiHat+Snare)
  let sounds = generate_drum_sounds(120, 1, time_signature=time_sig)
  assert_eq(sounds.length(), 8)
}

///|
test "generate_drum_sounds 4/4 two measures doubles hits" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  let sounds = generate_drum_sounds(120, 2, time_signature=time_sig)
  assert_eq(sounds.length(), 16)
}

///|
test "generate_drum_sounds 3/4 produces correct number of hits" {
  let time_sig = TimeSignature::{ numerator: 3, denominator: 4 }
  // jazz_waltz pattern has 3 hits per measure (Kick, HiHat, HiHat)
  let sounds = generate_drum_sounds(120, 1, time_signature=time_sig)
  assert_eq(sounds.length(), 3)
}

///|
test "generate_drum_sounds 4/4 start times increase within measure" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  let sounds = generate_drum_sounds(120, 1, time_signature=time_sig)
  // All start times should be non-negative and within the measure
  for sound in sounds {
    assert_true(sound.start_time.to_milliseconds() >= 0.0)
  }
  // Last hit should be before the end of the measure (2000ms at 120bpm)
  let max_start = sounds.fold(init=0.0, fn(acc, s) {
    let ms = s.start_time.to_milliseconds()
    if ms > acc {
      ms
    } else {
      acc
    }
  })
  assert_true(max_start < 2000.0)
}

///|
test "generate_drum_sounds second measure starts after first" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  let sounds = generate_drum_sounds(120, 2, time_signature=time_sig)
  // At 120 bpm, measure duration = 2000ms
  // Second measure hits should start at >= 2000ms
  let second_measure = sounds.filter(fn(s) {
    s.start_time.to_milliseconds() >= 2000.0
  })
  assert_eq(second_measure.length(), 8)
}

///|
test "generate_drum_sounds zero measures returns empty" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  let sounds = generate_drum_sounds(120, 0, time_signature=time_sig)
  assert_eq(sounds.length(), 0)
}

///|
test "generate_drum_sounds all notes are Eighth duration" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  let sounds = generate_drum_sounds(120, 1, time_signature=time_sig)
  for sound in sounds {
    match sound.sound_event {
      Note(duration=Eighth, ..) => ()
      other => fail("expected Eighth note, got \{other}")
    }
  }
}

///|
test "generate_drum_sounds uses drum MIDI numbers" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  let sounds = generate_drum_sounds(120, 1, time_signature=time_sig)
  let drum_midis = [36, 38, 42]
  for sound in sounds {
    match sound.sound_event {
      Note(midi~, ..) => assert_true(drum_midis.contains(midi.value))
      other => fail("expected Note, got \{other}")
    }
  }
}

///|
test "SwingRide pattern produces 12 hits per measure" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  let sounds = generate_drum_sounds(
    120,
    1,
    time_signature=time_sig,
    pattern_style=SwingRide,
  )
  assert_eq(sounds.length(), 12)
}

///|
test "SwingRide pattern includes Ride cymbal" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  let sounds = generate_drum_sounds(
    120,
    1,
    time_signature=time_sig,
    pattern_style=SwingRide,
  )
  let has_ride = sounds
    .iter()
    .any(fn(s) {
      match s.sound_event {
        Note(midi~, ..) => midi.value == 51
        _ => false
      }
    })
  assert_true(has_ride)
}

///|
test "Brushes pattern produces 5 hits per measure" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  let sounds = generate_drum_sounds(
    120,
    1,
    time_signature=time_sig,
    pattern_style=Brushes,
  )
  assert_eq(sounds.length(), 5)
}

///|
test "BossaNova pattern produces 13 hits per measure" {
  let time_sig = TimeSignature::{ numerator: 4, denominator: 4 }
  let sounds = generate_drum_sounds(
    120,
    1,
    time_signature=time_sig,
    pattern_style=BossaNova,
  )
  assert_eq(sounds.length(), 13)
}

///|
test "3/4 time uses waltz pattern regardless of style" {
  let time_sig = TimeSignature::{ numerator: 3, denominator: 4 }
  for
    style in ([Basic, SwingRide, BossaNova, Brushes] : Array[DrumPatternStyle]) {
    let sounds = generate_drum_sounds(
      120,
      1,
      time_signature=time_sig,
      pattern_style=style,
    )
    assert_eq(sounds.length(), 3)
  }
}
