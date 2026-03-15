///|
/// Generate app measures with leading/trailing rests
pub fn generate_full_measures(
  measure_chords : Array[Array[@music.Chord]],
  seed : Int,
  measure_count : Int,
  bpm : Int,
  key : @music.KeySignature,
  time_signature : @music.TimeSignature,
  jazz_style : @music.JazzStyle,
) -> Array[@music.Measure] {
  let beats_per_measure = time_signature.beats_per_measure()
  let settings = ImprovisationConfig::default(seed)
    |> ImprovisationConfig::with_techniques(jazz_style.techniques)
    |> ImprovisationConfig::with_pitch_range(
      jazz_style.pitch_min,
      jazz_style.pitch_max,
    )
  let music_measures = settings
    |> create_measure_generator
    |> improvisation(
      measure_chords,
      bpm,
      measure_count - 2,
      key,
      settings,
      time_signature~,
      beats_per_measure~,
      start_offset=1,
    )
  let leading_rest = leading_rest_measure(beats_per_measure~)
  let trailing_rest_start = (measure_count - 1).to_double() *
    @music.ms_per_measure(bpm, beats_per_measure~)
  let trailing_rest = trailing_rest_measure(
    start_time=@music.Duration::from_milliseconds(trailing_rest_start),
    beats_per_measure~,
  )
  leading_rest + music_measures + trailing_rest
}

///|
/// Create a leading rest measure (empty measure at the beginning)
fn leading_rest_measure(beats_per_measure~ : Double) -> Array[@music.Measure] {
  [
    @music.Measure::{
      chords: [],
      beats: [
        @music.Beat::{
          count: 0,
          notes: rest_notes_for_beats(beats_per_measure),
        },
      ],
      start_time: @music.Duration::from_milliseconds(0.0),
    },
  ]
}

///|
/// Create a trailing rest measure (empty measure at the end)
fn trailing_rest_measure(
  start_time~ : @music.Duration,
  beats_per_measure~ : Double,
) -> Array[@music.Measure] {
  [
    @music.Measure::{
      chords: [],
      beats: [
        @music.Beat::{
          count: 0,
          notes: rest_notes_for_beats(beats_per_measure),
        },
      ],
      start_time,
    },
  ]
}

///|
/// Create rest notes that fill the given number of beats.
/// Uses the largest fitting duration repeatedly to fill the measure.
fn rest_notes_for_beats(beats : Double) -> Array[@music.MeasureNote] {
  let notes : Array[@music.MeasureNote] = []
  for remaining = beats {
    guard remaining > 0.001 else { break notes }
    match @music.NoteDuration::fit(remaining) {
      Some(duration) => {
        notes.push(@music.MeasureNote::{
          midi: None,
          duration,
          accidental: None,
          tie: None,
          tone_origin: None,
        })
        continue remaining - duration.to_beats()
      }
      None => break notes
    }
  }
}

///|
/// State passed between measures during improvisation generation
priv struct ImprovisationState {
  measures : Array[@music.Measure]
  incoming_tie : TieContext?
  incoming_stamina : Int
  incoming_last_midi : @music.MidiNumber?
  incoming_phrase : Int?
}

///|
/// Generate improvisation using measure generator
/// Returns array of Measures
/// measure_count specifies the number of music measures (excluding leading rest)
/// start_offset specifies the measure index offset for start_time calculation
/// measure_defs contains arrays of chords per measure (supports multiple chords per measure)
fn improvisation(
  generator : MeasureGenerator,
  measure_defs : Array[Array[@music.Chord]],
  bpm : Int,
  measure_count : Int,
  key : @music.KeySignature,
  settings : ImprovisationConfig,
  time_signature~ : @music.TimeSignature,
  beats_per_measure~ : Double,
  start_offset? : Int = 0,
) -> Array[@music.Measure] {
  if measure_defs.is_empty() {
    return []
  }

  let measure_duration_ms = @music.ms_per_measure(bpm, beats_per_measure~)
  let initial_state = ImprovisationState::{
    measures: [],
    incoming_tie: None,
    incoming_stamina: settings.stamina_initial,
    incoming_last_midi: None,
    incoming_phrase: None,
  }

  let final_state = Array::makei(measure_count, fn(i) { i })
    .iter()
    .fold(init=initial_state, fn(state, i) {
      let measure_chords = measure_defs[i % measure_defs.length()]
      let chord_segments = create_chord_segments(
        measure_chords, beats_per_measure,
      )
      let result = generator(MeasureContext::{
        chords: chord_segments,
        incoming_tie: state.incoming_tie,
        key,
        time_signature,
        beats_per_measure,
        incoming_stamina: state.incoming_stamina,
        incoming_last_midi: state.incoming_last_midi,
        incoming_phrase: state.incoming_phrase,
      })
      state.measures.push(@music.Measure::{
        chords: measure_chords,
        beats: result.beats,
        start_time: @music.Duration::from_milliseconds(
          (i + start_offset).to_double() * measure_duration_ms,
        ),
      })
      ImprovisationState::{
        measures: state.measures,
        incoming_tie: result.outgoing_tie,
        incoming_stamina: result.outgoing_stamina,
        incoming_last_midi: result.outgoing_last_midi,
        incoming_phrase: result.outgoing_phrase,
      }
    })
  remove_dangling_tie(final_state.measures, final_state.incoming_tie)
}

///|
/// Remove dangling tie at the end of the last measure.
/// The last note that would overflow into a non-existent next measure
/// is removed entirely rather than kept with its tie cleared.
/// Returns a new array without mutating the original.
fn remove_dangling_tie(
  measures : Array[@music.Measure],
  last_tie : TieContext?,
) -> Array[@music.Measure] {
  guard last_tie is Some(_) else { return measures }
  guard measures is [.. rest_measures, last_measure] else { return measures }
  guard last_measure.beats is [.. _rest_beats] else { return measures }

  // Remove trailing tied notes from the last measure's beats
  let new_beats = remove_trailing_tied_notes(last_measure.beats)
  [..rest_measures, @music.Measure::{ ..last_measure, beats: new_beats }]
}

///|
/// Remove trailing tied notes from beats.
/// Works backwards through beats, removing notes with TieStart/TieBoth ties
/// from the end of the last beat that has notes.
fn remove_trailing_tied_notes(beats : Array[@music.Beat]) -> Array[@music.Beat] {
  // Work backwards through beats to find and remove the trailing tied note chain
  // State: (result_beats, should_continue_removing)
  let (result, _) = beats[:].rev_fold(init=([], true), fn(acc, beat) {
    let (result_beats, removing) = acc
    match (removing, beat.notes) {
      (true, [.. rest, { tie: Some(@music.TieStart | @music.TieBoth), .. }]) => {
        // Remove the last note and continue removing backwards
        let new_beat = @music.Beat::{
          count: beat.count,
          notes: rest.to_array(),
        }
        ([new_beat, ..result_beats], true)
      }
      _ =>
        // Stop removing: either not removing or last note doesn't have tie
        ([beat, ..result_beats], false)
    }
  })
  result
}

///|
test "Chord::scale_tones returns non-chord non-tension diatonic tones for Cmaj7 in C" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let scale_tones = chord.scale_tones()
  // Cmaj7 chord tones: C(0), E(4), G(7), B(11)
  // Ionian scale from C: C(0), D(2), E(4), F(5), G(7), A(9), B(11)
  // Tensions Major7: D(9th), F#(#11), A(13th) excluded
  // Scale tone: F(5) only — natural 11 (avoid note, not a tension)
  let pitch_classes = scale_tones.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[5]")
  // Verify none are chord tones
  let chord_pcs = chord.tones().map(fn(m) { m.pitch_class() })
  for pc in pitch_classes {
    assert_false(chord_pcs.contains(pc))
  }
}

///|
test "Chord::scale_tones returns empty for Dm7 — all scale tones are tensions" {
  let chord = @music.Chord::{
    root: @music.D,
    quality: @music.Minor7,
    bass: None,
  }
  let scale_tones = chord.scale_tones()
  // Dm7 chord tones: D(2), F(5), A(9), C(0)
  // Dorian scale from D: D E F G A B C
  // Tensions Minor7: E(9th), G(11th), B(13th) — all scale tones are tensions
  let pitch_classes = scale_tones.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[]")
}

///|
test "Chord::approach_tones returns chromatic half-steps around chord tones for Cmaj7" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let approach = chord.approach_tones()
  // Cmaj7 chord tones: C(60), E(64), G(67), B(71)
  // Approach tones (half-step below/above, excluding chord tones):
  //   C: B(59) is chord tone → excluded, Db(61) ✓
  //   E: Eb(63) ✓, F(65) ✓
  //   G: Gb(66) ✓, Ab(68) ✓
  //   B: Bb(70) ✓, C(72) is chord tone → excluded
  let pitch_classes = approach.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[1, 3, 5, 6, 8, 10]")
  // Verify none are chord tones
  let chord_pcs = chord.tones().map(fn(m) { m.pitch_class() })
  for pc in pitch_classes {
    assert_false(chord_pcs.contains(pc))
  }
}

///|
test "Chord::approach_tones returns chromatic half-steps around chord tones for Dm7" {
  let chord = @music.Chord::{
    root: @music.D,
    quality: @music.Minor7,
    bass: None,
  }
  let approach = chord.approach_tones()
  // Dm7 chord tones: D(62), F(65), A(69), C(72)
  // Approach tones:
  //   D: Db(61) ✓, Eb(63) ✓
  //   F: E(64) ✓, Gb(66) ✓
  //   A: Ab(68) ✓, Bb(70) ✓
  //   C: B(71) ✓, Db(73) ✓ (but same pc as 61)
  let pitch_classes = approach.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[1, 3, 4, 6, 8, 10, 11, 1]")
}

///|
test "create_chord_segments evenly distributes chords" {
  let chords = [
    @music.Chord::{ root: @music.C, quality: @music.Major7, bass: None },
    @music.Chord::{ root: @music.G, quality: @music.Dominant7, bass: None },
  ]
  let segments = create_chord_segments(chords, 4.0)
  assert_eq(segments.length(), 2)
  // First chord: beats 0-2
  assert_eq(segments[0].start_beat, 0.0)
  assert_eq(segments[0].end_beat, 2.0)
  assert_eq(segments[0].chord.root, @music.C)
  // Second chord: beats 2-4
  assert_eq(segments[1].start_beat, 2.0)
  assert_eq(segments[1].end_beat, 4.0)
  assert_eq(segments[1].chord.root, @music.G)
}

///|
test "MeasureContext::chord_at returns correct chord for position" {
  let chords = [
    @music.Chord::{ root: @music.C, quality: @music.Major7, bass: None },
    @music.Chord::{ root: @music.G, quality: @music.Dominant7, bass: None },
  ]
  let segments = create_chord_segments(chords, 4.0)
  let ctx = MeasureContext::{
    chords: segments,
    incoming_tie: None,
    key: @music.KeySignature::c_major(),
    time_signature: @music.TimeSignature::default(),
    beats_per_measure: 4.0,
    incoming_stamina: 50,
    incoming_last_midi: None,
    incoming_phrase: None,
  }
  // Beat 0 should be first chord
  assert_eq(ctx.chord_at(0.0).root, @music.C)
  // Beat 1.5 should be first chord
  assert_eq(ctx.chord_at(1.5).root, @music.C)
  // Beat 2 should be second chord
  assert_eq(ctx.chord_at(2.0).root, @music.G)
  // Beat 3 should be second chord
  assert_eq(ctx.chord_at(3.0).root, @music.G)
  // Beat 4 (at end) should return last chord
  assert_eq(ctx.chord_at(4.0).root, @music.G)
}

///|
test "improvisation removes dangling tie at last measure" {
  // Generator that always produces a note with TieStart at the end
  let generator : MeasureGenerator = fn(ctx) {
    let midi60 = @music.MidiNumber::new(60).unwrap()
    match ctx.incoming_tie {
      Some(tie_ctx) =>
        // Handle incoming tie
        MeasureResult::{
          beats: [
            @music.Beat::{
              count: 0,
              notes: [
                @music.MeasureNote::{
                  midi: Some(tie_ctx.midi.value),
                  duration: @music.NoteDuration::from_beats(
                    tie_ctx.remaining_beats,
                  ),
                  accidental: None,
                  tie: Some(@music.TieEnd),
                  tone_origin: None,
                },
              ],
            },
          ],
          outgoing_tie: None,
          outgoing_stamina: ctx.incoming_stamina,
          outgoing_last_midi: Some(tie_ctx.midi),
          outgoing_phrase: None,
        }
      None =>
        // Always produce a note that extends beyond the measure (TieStart)
        MeasureResult::{
          beats: [
            @music.Beat::{
              count: 0,
              notes: [
                @music.MeasureNote::{
                  midi: Some(60),
                  duration: @music.Whole,
                  accidental: None,
                  tie: Some(@music.TieStart),
                  tone_origin: None,
                },
              ],
            },
          ],
          outgoing_tie: Some(TieContext::{
            midi: midi60,
            remaining_beats: 2.0,
          }),
          outgoing_stamina: ctx.incoming_stamina,
          outgoing_last_midi: Some(midi60),
          outgoing_phrase: None,
        }
    }
  }
  let measure_defs = [
    [@music.Chord::{ root: @music.C, quality: @music.Major7, bass: None }],
  ]
  let settings = ImprovisationConfig::default(0)
  let measures = improvisation(
    generator,
    measure_defs,
    120,
    3,
    @music.KeySignature::c_major(),
    settings,
    time_signature=@music.TimeSignature::default(),
    beats_per_measure=4.0,
  ) // 1 leading rest + 2 chord measures

  // Last measure's overflowing note should be removed entirely
  let last_measure = measures[measures.length() - 1]
  inspect(last_measure.all_notes().is_empty(), content="true")
}

///|
test "improvisation preserves tie when not at last measure" {
  // Generator that produces TieStart, then subsequent measures handle it
  let call_count = Ref::new(0)
  let generator : MeasureGenerator = fn(ctx) {
    let midi60 = @music.MidiNumber::new(60).unwrap()
    let midi62 = @music.MidiNumber::new(62).unwrap()
    call_count.val = call_count.val + 1
    match ctx.incoming_tie {
      Some(tie_ctx) =>
        MeasureResult::{
          beats: [
            @music.Beat::{
              count: 0,
              notes: [
                @music.MeasureNote::{
                  midi: Some(tie_ctx.midi.value),
                  duration: @music.NoteDuration::from_beats(
                    tie_ctx.remaining_beats,
                  ),
                  accidental: None,
                  tie: Some(@music.TieEnd),
                  tone_origin: None,
                },
                @music.MeasureNote::{
                  midi: Some(62),
                  duration: @music.Half,
                  accidental: None,
                  tie: None,
                  tone_origin: None,
                },
              ],
            },
          ],
          outgoing_tie: None,
          outgoing_stamina: ctx.incoming_stamina,
          outgoing_last_midi: Some(midi62),
          outgoing_phrase: None,
        }
      None =>
        if call_count.val == 2 {
          // Second measure (first chord measure): create tie
          MeasureResult::{
            beats: [
              @music.Beat::{
                count: 0,
                notes: [
                  @music.MeasureNote::{
                    midi: Some(60),
                    duration: @music.Whole,
                    accidental: None,
                    tie: Some(@music.TieStart),
                    tone_origin: None,
                  },
                ],
              },
            ],
            outgoing_tie: Some(TieContext::{
              midi: midi60,
              remaining_beats: 2.0,
            }),
            outgoing_stamina: ctx.incoming_stamina,
            outgoing_last_midi: Some(midi60),
            outgoing_phrase: None,
          }
        } else {
          // Leading rest measure
          MeasureResult::{
            beats: [
              @music.Beat::{
                count: 0,
                notes: [
                  @music.MeasureNote::{
                    midi: None,
                    duration: @music.Whole,
                    accidental: None,
                    tie: None,
                    tone_origin: None,
                  },
                ],
              },
            ],
            outgoing_tie: None,
            outgoing_stamina: ctx.incoming_stamina,
            outgoing_last_midi: None,
            outgoing_phrase: None,
          }
        }
    }
  }
  let measure_defs = [
    [@music.Chord::{ root: @music.C, quality: @music.Major7, bass: None }],
  ]
  let settings = ImprovisationConfig::default(0)
  let measures = improvisation(
    generator,
    measure_defs,
    120,
    4,
    @music.KeySignature::c_major(),
    settings,
    time_signature=@music.TimeSignature::default(),
    beats_per_measure=4.0,
  ) // 1 leading rest + 3 chord measures

  // Second measure should have TieStart preserved (not last measure)
  let second_notes = measures[1].all_notes()
  let second_last_note = second_notes[second_notes.length() - 1]
  inspect(second_last_note.tie, content="Some(TieStart)")

  // Third measure should have TieEnd
  let third_notes = measures[2].all_notes()
  let third_first_note = third_notes[0]
  inspect(third_first_note.tie, content="Some(TieEnd)")
}

///|
test "with_techniques disabling non-chord-tone techniques: generated notes use only chord tones" {
  // Disable all techniques that produce non-chord tones
  let techniques = @music.Techniques::{
    tension_tones: false,
    chromatic_approach: false,
    enclosure: false,
    syncopation: true,
    triplets: true,
    bebop_scales: false,
    neighbor_tones: false,
    sixteenth_runs: false,
  }
  let settings = ImprovisationConfig::default(42)
    |> ImprovisationConfig::with_techniques(techniques)
  let chords = [
    [@music.Chord::{ root: @music.C, quality: @music.Major7, bass: None }],
    [@music.Chord::{ root: @music.G, quality: @music.Dominant7, bass: None }],
  ]
  let generator = create_measure_generator(settings)
  let measures = improvisation(
    generator,
    chords,
    120,
    2,
    @music.KeySignature::c_major(),
    settings,
    time_signature=@music.TimeSignature::default(),
    beats_per_measure=4.0,
  )
  // All notes with a tone_origin should be ChordTone only
  let non_chord_origins : Array[String] = []
  for measure in measures {
    for note in measure.all_notes() {
      match note.tone_origin {
        Some(@music.ChordTone) | None => ()
        Some(origin) => non_chord_origins.push(origin.to_string())
      }
    }
  }
  assert_eq(non_chord_origins, [])
}
