///|
test "improvisation removes dangling tie at last measure" {
  // Generator that always produces a note with TieStart at the end
  let generator : MeasureGenerator = fn(ctx) {
    let midi60 = @music.MidiNumber::new(60).unwrap()
    match ctx.incoming_tie {
      Some(tie_ctx) =>
        // Handle incoming tie
        MeasureResult::{
          notes: [
            @music.MeasureNote::{
              midi: Some(tie_ctx.midi.value),
              duration: @music.NoteDuration::from_beats(tie_ctx.remaining_beats),
              start_beat: 0.0,
              accidental: None,
              tie: Some(@music.TieEnd),
            },
          ],
          outgoing_tie: None,
        }
      None =>
        // Always produce a note that extends beyond the measure (TieStart)
        MeasureResult::{
          notes: [
            @music.MeasureNote::{
              midi: Some(60),
              duration: @music.Whole,
              start_beat: 0.0,
              accidental: None,
              tie: Some(@music.TieStart),
            },
          ],
          outgoing_tie: Some(TieContext::{ midi: midi60, remaining_beats: 2.0 }),
        }
    }
  }
  let chords = [@music.Chord::{ root: @music.C, quality: @music.Major7 }]
  let measures = improvisation(
    generator,
    chords,
    120,
    3,
    @music.KeySignature::c_major(),
  ) // 1 leading rest + 2 chord measures

  // Last measure's last note should have tie removed
  let last_measure = measures[measures.length() - 1]
  let last_note = last_measure.notes[last_measure.notes.length() - 1]
  inspect(last_note.tie, content="None")
}

///|
test "improvisation preserves tie when not at last measure" {
  // Generator that produces TieStart, then subsequent measures handle it
  let call_count = Ref::new(0)
  let generator : MeasureGenerator = fn(ctx) {
    let midi60 = @music.MidiNumber::new(60).unwrap()
    call_count.val = call_count.val + 1
    match ctx.incoming_tie {
      Some(tie_ctx) =>
        MeasureResult::{
          notes: [
            @music.MeasureNote::{
              midi: Some(tie_ctx.midi.value),
              duration: @music.NoteDuration::from_beats(tie_ctx.remaining_beats),
              start_beat: 0.0,
              accidental: None,
              tie: Some(@music.TieEnd),
            },
            @music.MeasureNote::{
              midi: Some(62),
              duration: @music.Half,
              start_beat: 2.0,
              accidental: None,
              tie: None,
            },
          ],
          outgoing_tie: None,
        }
      None =>
        if call_count.val == 2 {
          // Second measure (first chord measure): create tie
          MeasureResult::{
            notes: [
              @music.MeasureNote::{
                midi: Some(60),
                duration: @music.Whole,
                start_beat: 0.0,
                accidental: None,
                tie: Some(@music.TieStart),
              },
            ],
            outgoing_tie: Some(TieContext::{
              midi: midi60,
              remaining_beats: 2.0,
            }),
          }
        } else {
          // Leading rest measure
          MeasureResult::{
            notes: [
              @music.MeasureNote::{
                midi: None,
                duration: @music.Whole,
                start_beat: 0.0,
                accidental: None,
                tie: None,
              },
            ],
            outgoing_tie: None,
          }
        }
    }
  }
  let chords = [@music.Chord::{ root: @music.C, quality: @music.Major7 }]
  let measures = improvisation(
    generator,
    chords,
    120,
    4,
    @music.KeySignature::c_major(),
  ) // 1 leading rest + 3 chord measures

  // Second measure should have TieStart preserved (not last measure)
  let second_measure = measures[1]
  let second_last_note = second_measure.notes[second_measure.notes.length() - 1]
  inspect(second_last_note.tie, content="Some(TieStart)")

  // Third measure should have TieEnd
  let third_measure = measures[2]
  let third_first_note = third_measure.notes[0]
  inspect(third_first_note.tie, content="Some(TieEnd)")
}
