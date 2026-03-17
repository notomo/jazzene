///|
fn make_sound(
  pitch : Int,
  start_ms : Double,
  dur_ms : Double,
) -> @music.ScheduledSound {
  @music.ScheduledSound::{
    sound_event: @music.Note(
      midi=@music.MidiNumber::new(pitch).unwrap(),
      duration=@music.NoteDuration::Quarter,
    ),
    duration: @music.Duration::from_milliseconds(dur_ms),
    start_time: @music.Duration::from_milliseconds(start_ms),
    tone_origin: Some(@music.ToneOrigin::Imported),
  }
}

///|
fn empty_imported() -> ImportedMidi {
  ImportedMidi::{
    melody_sounds: [],
    comping_sounds: [],
    bass_sounds: [],
    drum_sounds: [],
    bpm: Some(120),
    key: None,
    time_signature: None,
    measure_count: None,
  }
}

///|
fn default_key() -> @music.KeySignature {
  @music.KeySignature::from_root(@music.ChordRoot::C)
}

///|
fn default_time_signature() -> @music.TimeSignature {
  @music.TimeSignature::{ numerator: 4, denominator: 4 }
}

///|
fn make_measure(start_ms : Double) -> @music.Measure {
  @music.Measure::{
    chords: [],
    beats: [
      @music.Beat::{ count: 0, notes: [] },
      @music.Beat::{ count: 1, notes: [] },
      @music.Beat::{ count: 2, notes: [] },
      @music.Beat::{ count: 3, notes: [] },
    ],
    start_time: @music.Duration::from_milliseconds(start_ms),
  }
}

///|
test "select_melody_sounds: Off returns empty regardless of imported" {
  let full = [make_sound(60, 0.0, 500.0)]
  let imported = {
    ..empty_imported(),
    melody_sounds: [make_sound(64, 0.0, 500.0)],
  }
  inspect(
    select_melody_sounds(@music.Off, Some(imported), full, 120, default_key()).length(),
    content="0",
  )
  inspect(
    select_melody_sounds(@music.Off, None, full, 120, default_key()).length(),
    content="0",
  )
}

///|
test "select_melody_sounds: On with no imported uses full_sounds" {
  let full = [make_sound(60, 0.0, 500.0)]
  inspect(
    select_melody_sounds(@music.On, None, full, 120, default_key()).length(),
    content="1",
  )
  inspect(
    select_melody_sounds(@music.On, None, full, 120, default_key())[0]
    .midi()
    .map(fn(m) { m.value }),
    content="Some(60)",
  )
}

///|
test "select_melody_sounds: On with imported that has no melody uses full_sounds" {
  let full = [make_sound(60, 0.0, 500.0)]
  let imported = empty_imported()
  inspect(
    select_melody_sounds(@music.On, Some(imported), full, 120, default_key()).length(),
    content="1",
  )
}

///|
test "select_melody_sounds: On with imported melody uses imported sounds" {
  let full = [make_sound(60, 0.0, 500.0)]
  let imported = {
    ..empty_imported(),
    melody_sounds: [make_sound(64, 0.0, 500.0), make_sound(67, 500.0, 500.0)],
  }
  let result = select_melody_sounds(
    @music.On,
    Some(imported),
    full,
    120,
    default_key(),
  )
  inspect(result.length(), content="2")
  inspect(result[0].midi().map(fn(m) { m.value }), content="Some(64)")
}

///|
test "select_melody_sounds: Silent behaves same as On" {
  let full = [make_sound(60, 0.0, 500.0)]
  let imported = {
    ..empty_imported(),
    melody_sounds: [make_sound(64, 0.0, 500.0)],
  }
  let result = select_melody_sounds(
    @music.Silent,
    Some(imported),
    full,
    120,
    default_key(),
  )
  inspect(result.length(), content="1")
  inspect(result[0].midi().map(fn(m) { m.value }), content="Some(64)")
}

///|
test "select_melody_sounds: On with imported adapts BPM scaling" {
  // imported BPM=60, current BPM=120 → times halved
  let imported = {
    ..empty_imported(),
    bpm: Some(60),
    melody_sounds: [make_sound(60, 0.0, 1000.0)],
  }
  let result = select_melody_sounds(
    @music.On,
    Some(imported),
    [],
    120,
    default_key(),
  )
  inspect(result[0].duration.to_milliseconds(), content="500")
}

///|
test "select_melody_sounds: On with imported adapts key transposition" {
  // imported key=C (root midi=60), current key=G (root midi=67) → +7 semitones?
  // Actually key_shift normalizes to [-6,6]: 67-60=7 > 6 → 7-12=-5
  let imported = {
    ..empty_imported(),
    key: Some(@music.KeySignature::from_root(@music.ChordRoot::C)),
    melody_sounds: [make_sound(60, 0.0, 500.0)],
  }
  let g_key = @music.KeySignature::from_root(@music.ChordRoot::G)
  let result = select_melody_sounds(@music.On, Some(imported), [], 120, g_key)
  // G root midi=67, C root midi=60: raw=7 > 6 → shift=-5 → 60+(-5)=55
  inspect(result[0].midi().map(fn(m) { m.value }), content="Some(55)")
}

///|
test "select_measures: Off returns measures with empty beats" {
  let full = [make_measure(0.0), make_measure(2000.0)]
  let result = select_measures(
    @music.Off,
    None,
    full,
    120,
    default_time_signature(),
    2,
    default_key(),
  )
  inspect(result.length(), content="2")
  inspect(result[0].beats[0].notes.length(), content="0")
}

///|
test "select_measures: On with no imported uses full_measures" {
  let full = [make_measure(0.0)]
  let result = select_measures(
    @music.On,
    None,
    full,
    120,
    default_time_signature(),
    1,
    default_key(),
  )
  inspect(result.length(), content="1")
}

///|
test "select_measures: On with empty imported melody uses full_measures" {
  let full = [make_measure(0.0)]
  let result = select_measures(
    @music.On,
    Some(empty_imported()),
    full,
    120,
    default_time_signature(),
    1,
    default_key(),
  )
  inspect(result.length(), content="1")
}

///|
test "select_measures: On with imported melody builds measures from imported sounds" {
  let full = [make_measure(0.0)]
  // One quarter note at beat 0
  let imported = {
    ..empty_imported(),
    melody_sounds: [make_sound(60, 0.0, 500.0)],
  }
  let result = select_measures(
    @music.On,
    Some(imported),
    full,
    120,
    default_time_signature(),
    1,
    default_key(),
  )
  inspect(result.length(), content="1")
  inspect(result[0].beats[0].notes.length(), content="1")
  inspect(result[0].beats[0].notes[0].midi, content="Some(60)")
}

///|
test "select_drum_sounds: drums_enabled=false returns empty" {
  let style = { ..@music.JazzStyle::default(), drums_enabled: false }
  inspect(
    select_drum_sounds(style, None, 120, 4, default_time_signature()).length(),
    content="0",
  )
}

///|
test "select_drum_sounds: Imported with no midi returns empty" {
  let style = {
    ..@music.JazzStyle::default(),
    drums_enabled: true,
    drum_pattern: @music.Imported,
  }
  inspect(
    select_drum_sounds(style, None, 120, 4, default_time_signature()).length(),
    content="0",
  )
}

///|
test "select_drum_sounds: Imported with midi returns drum sounds" {
  let style = {
    ..@music.JazzStyle::default(),
    drums_enabled: true,
    drum_pattern: @music.Imported,
  }
  let imported = {
    ..empty_imported(),
    drum_sounds: [make_sound(36, 0.0, 100.0), make_sound(38, 500.0, 100.0)],
  }
  inspect(
    select_drum_sounds(style, Some(imported), 120, 4, default_time_signature()).length(),
    content="2",
  )
}

///|
test "select_drum_sounds: non-Imported generates drum sounds" {
  let style = {
    ..@music.JazzStyle::default(),
    drums_enabled: true,
    drum_pattern: @music.SwingRide,
  }
  let result = select_drum_sounds(style, None, 120, 1, default_time_signature())
  inspect(result.length() > 0, content="true")
}

///|
test "select_comping_sounds: comping_mode=Off returns empty" {
  let style = { ..@music.JazzStyle::default(), comping_mode: @music.Off }
  inspect(
    select_comping_sounds(style, None, [], 120, [], default_key(), 0).length(),
    content="0",
  )
}

///|
test "select_comping_sounds: Imported with no midi returns empty" {
  let style = {
    ..@music.JazzStyle::default(),
    comping_mode: @music.On,
    comping_style: @music.Imported,
  }
  inspect(
    select_comping_sounds(style, None, [], 120, [], default_key(), 0).length(),
    content="0",
  )
}

///|
test "select_comping_sounds: Imported with midi returns comping sounds" {
  let style = {
    ..@music.JazzStyle::default(),
    comping_mode: @music.On,
    comping_style: @music.Imported,
  }
  let imported = {
    ..empty_imported(),
    comping_sounds: [make_sound(48, 0.0, 500.0)],
  }
  let result = select_comping_sounds(
    style,
    Some(imported),
    [],
    120,
    [],
    default_key(),
    0,
  )
  inspect(result.length(), content="1")
  inspect(result[0].midi().map(fn(m) { m.value }), content="Some(48)")
}

///|
test "select_bass_sounds: bass_enabled=false returns empty" {
  let style = { ..@music.JazzStyle::default(), bass_enabled: false }
  inspect(
    select_bass_sounds(style, None, [], 120, default_key()).length(),
    content="0",
  )
}

///|
test "select_bass_sounds: Imported with no midi returns empty" {
  let style = {
    ..@music.JazzStyle::default(),
    bass_enabled: true,
    bass_style: @music.Imported,
  }
  inspect(
    select_bass_sounds(style, None, [], 120, default_key()).length(),
    content="0",
  )
}

///|
test "select_bass_sounds: Imported with midi returns bass sounds" {
  let style = {
    ..@music.JazzStyle::default(),
    bass_enabled: true,
    bass_style: @music.Imported,
  }
  let imported = {
    ..empty_imported(),
    bass_sounds: [make_sound(36, 0.0, 500.0), make_sound(38, 500.0, 500.0)],
  }
  let result = select_bass_sounds(style, Some(imported), [], 120, default_key())
  inspect(result.length(), content="2")
  inspect(result[0].midi().map(fn(m) { m.value }), content="Some(36)")
}
