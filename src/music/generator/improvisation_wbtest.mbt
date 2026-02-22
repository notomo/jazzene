///|
test "Chord::scale_tones returns non-chord diatonic tones for Cmaj7 in C" {
  let chord = @music.Chord::{
    root: @music.C,
    quality: @music.Major7,
    bass: None,
  }
  let scale_tones = chord.scale_tones()
  // Cmaj7 chord tones: C(0), E(4), G(7), B(11)
  // Ionian scale from C: C(0), D(2), E(4), F(5), G(7), A(9), B(11)
  // Scale tones (non-chord): D(62), F(65), A(69)
  let pitch_classes = scale_tones.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[2, 5, 9]")
  // Verify none are chord tones
  let chord_pcs = chord.tones().map(fn(m) { m.pitch_class() })
  for pc in pitch_classes {
    assert_false(chord_pcs.contains(pc))
  }
}

///|
test "Chord::scale_tones returns non-chord diatonic tones for Dm7 in C" {
  let chord = @music.Chord::{
    root: @music.D,
    quality: @music.Minor7,
    bass: None,
  }
  let scale_tones = chord.scale_tones()
  // Dm7 chord tones: D(2), F(5), A(9), C(0)
  // Dorian scale from D: D E F G A B C
  // Scale tones (non-chord): E(64), G(67), B(71)
  let pitch_classes = scale_tones.map(fn(m) { m.pitch_class() })
  inspect(pitch_classes, content="[4, 7, 11]")
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
    incoming_motif_memory: MotifMemory::empty(),
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
          outgoing_motif_memory: MotifMemory::empty(),
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
          outgoing_tie: Some(TieContext::{ midi: midi60, remaining_beats: 2.0 }),
          outgoing_stamina: ctx.incoming_stamina,
          outgoing_last_midi: Some(midi60),
          outgoing_phrase: None,
          outgoing_motif_memory: MotifMemory::empty(),
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
          outgoing_motif_memory: MotifMemory::empty(),
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
            outgoing_motif_memory: MotifMemory::empty(),
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
            outgoing_motif_memory: MotifMemory::empty(),
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
