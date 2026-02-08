///|
test "create_chord_segments evenly distributes chords" {
  let chords = [
    @music.Chord::{ root: @music.C, quality: @music.Major7 },
    @music.Chord::{ root: @music.G, quality: @music.Dominant7 },
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
    @music.Chord::{ root: @music.C, quality: @music.Major7 },
    @music.Chord::{ root: @music.G, quality: @music.Dominant7 },
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
                },
              ],
            },
          ],
          outgoing_tie: None,
          outgoing_stamina: ctx.incoming_stamina,
          outgoing_last_midi: Some(tie_ctx.midi),
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
                },
              ],
            },
          ],
          outgoing_tie: Some(TieContext::{ midi: midi60, remaining_beats: 2.0 }),
          outgoing_stamina: ctx.incoming_stamina,
          outgoing_last_midi: Some(midi60),
        }
    }
  }
  let measure_defs = [
    [@music.Chord::{ root: @music.C, quality: @music.Major7 }],
  ]
  let settings = Settings::default(0)
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
                },
                @music.MeasureNote::{
                  midi: Some(62),
                  duration: @music.Half,
                  accidental: None,
                  tie: None,
                },
              ],
            },
          ],
          outgoing_tie: None,
          outgoing_stamina: ctx.incoming_stamina,
          outgoing_last_midi: Some(midi62),
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
                  },
                ],
              },
            ],
            outgoing_tie: None,
            outgoing_stamina: ctx.incoming_stamina,
            outgoing_last_midi: None,
          }
        }
    }
  }
  let measure_defs = [
    [@music.Chord::{ root: @music.C, quality: @music.Major7 }],
  ]
  let settings = Settings::default(0)
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
