///|
/// Chord progression editor - structured GUI for building chord progressions

///|
/// Identifies which chord is being edited in the dialog
pub(all) struct EditingChord {
  measure_idx : Int
  chord_idx : Int
} derive(Eq, Debug)

///|
pub impl Show for EditingChord with output(self, logger) {
  self.to_repr().output(logger)
}

///|
/// Get the DegreeChord at the given indices from the measures array
fn get_chord_at(
  measures : Array[@music.DegreeMeasure],
  ec : EditingChord,
) -> @music.DegreeChord? {
  if ec.measure_idx < measures.length() {
    let m = measures[ec.measure_idx]
    if ec.chord_idx < m.chords.length() {
      Some(m.chords[ec.chord_idx])
    } else {
      None
    }
  } else {
    None
  }
}

///|
/// Update the chord at the given editing position
fn update_chord_at(
  measures : Array[@music.DegreeMeasure],
  ec : EditingChord,
  new_chord : @music.DegreeChord,
) -> Array[@music.DegreeMeasure] {
  guard ec.measure_idx < measures.length() else { return measures }
  let measure = measures[ec.measure_idx]
  guard ec.chord_idx < measure.chords.length() else { return measures }
  let new_measures = measures.copy()
  let new_chords = measure.chords.copy()
  new_chords[ec.chord_idx] = new_chord
  new_measures[ec.measure_idx] = @music.DegreeMeasure::{ chords: new_chords }
  new_measures
}

///|
/// Merge the measure at mi with the next measure (mi+1)
fn merge_measures_at(
  measures : Array[@music.DegreeMeasure],
  mi : Int,
) -> Array[@music.DegreeMeasure] {
  guard mi >= 0 && mi < measures.length() - 1 else { return measures }
  let left = measures[mi]
  let right = measures[mi + 1]
  let merged_chords = left.chords + right.chords
  // Items after mi+1 shift down by 1; give them new references so that
  // for_each (reference-based reconciliation) re-renders with correct indices.
  Array::makei(measures.length() - 1, fn(i) {
    if i < mi {
      measures[i]
    } else if i == mi {
      @music.DegreeMeasure::{ chords: merged_chords }
    } else {
      @music.DegreeMeasure::{ chords: measures[i + 1].chords }
    }
  })
}

///|
/// Insert a chord after ec.chord_idx in ec.measure_idx
fn insert_chord_after(
  measures : Array[@music.DegreeMeasure],
  ec : EditingChord,
  chord : @music.DegreeChord,
) -> Array[@music.DegreeMeasure] {
  guard ec.measure_idx < measures.length() else { return measures }
  let measure = measures[ec.measure_idx]
  guard ec.chord_idx < measure.chords.length() else { return measures }
  let new_chords = Array::makei(measure.chords.length() + 1, fn(i) {
    if i <= ec.chord_idx {
      measure.chords[i]
    } else if i == ec.chord_idx + 1 {
      chord
    } else {
      measure.chords[i - 1]
    }
  })
  let new_measures = measures.copy()
  new_measures[ec.measure_idx] = @music.DegreeMeasure::{ chords: new_chords }
  new_measures
}

///|
/// Insert a new measure after mi
fn insert_measure_after(
  measures : Array[@music.DegreeMeasure],
  mi : Int,
  measure : @music.DegreeMeasure,
) -> Array[@music.DegreeMeasure] {
  // Measures after the insertion point get new object references so that
  // for_each (which uses reference-based reconciliation) re-renders them
  // with correct updated indices instead of reusing stale index values.
  Array::makei(measures.length() + 1, fn(i) {
    if i <= mi {
      measures[i]
    } else if i == mi + 1 {
      measure
    } else {
      @music.DegreeMeasure::{ chords: measures[i - 1].chords }
    }
  })
}

///|
let max_chords_per_measure : Int = 4

///|
let default_degree_chord : @music.DegreeChord = @music.DegreeChord::{
  accidental: 0,
  degree: @music.I,
  quality: @music.Major7,
  bass: None,
}

///|
/// Delete the chord at the given editing position.
/// If the measure has only one chord, the entire measure is removed.
fn delete_chord_at(
  measures : Array[@music.DegreeMeasure],
  ec : EditingChord,
) -> Array[@music.DegreeMeasure] {
  guard ec.measure_idx < measures.length() else { return measures }
  let measure = measures[ec.measure_idx]
  if measure.chords.length() <= 1 {
    // Items after ec.measure_idx shift down by 1; give them new references so
    // that for_each (reference-based reconciliation) re-renders with correct indices.
    Array::makei(measures.length() - 1, fn(i) {
      if i < ec.measure_idx {
        measures[i]
      } else {
        @music.DegreeMeasure::{ chords: measures[i + 1].chords }
      }
    })
  } else {
    let new_measures = measures.copy()
    let new_chords = Array::makei(measure.chords.length() - 1, fn(j) {
      if j < ec.chord_idx {
        measure.chords[j]
      } else {
        measure.chords[j + 1]
      }
    })
    new_measures[ec.measure_idx] = @music.DegreeMeasure::{ chords: new_chords }
    new_measures
  }
}

///|
/// Compute the next editing position after merging measures at merge_mi.
/// Preserves the current selection, adjusting indices as needed.
fn next_editing_chord_after_merge(
  measures : Array[@music.DegreeMeasure],
  merge_mi : Int,
  current_ec : EditingChord?,
) -> EditingChord? {
  match current_ec {
    None => Some(EditingChord::{ measure_idx: merge_mi, chord_idx: 0 })
    Some(ec) =>
      if ec.measure_idx < merge_mi {
        Some(ec)
      } else if ec.measure_idx == merge_mi {
        Some(ec)
      } else if ec.measure_idx == merge_mi + 1 {
        let left_len = measures[merge_mi].chords.length()
        Some(EditingChord::{
          measure_idx: merge_mi,
          chord_idx: left_len + ec.chord_idx,
        })
      } else {
        Some(EditingChord::{
          measure_idx: ec.measure_idx - 1,
          chord_idx: ec.chord_idx,
        })
      }
  }
}

///|
/// Compute the next editing position after deleting the chord at ec.
/// Prefers the chord to the right; falls back to the chord to the left.
fn next_editing_chord_after_delete(
  measures : Array[@music.DegreeMeasure],
  ec : EditingChord,
) -> EditingChord? {
  guard ec.measure_idx < measures.length() else { return None }
  let measure = measures[ec.measure_idx]
  if measure.chords.length() <= 1 {
    // Whole measure is removed — try right first, then left
    let new_len = measures.length() - 1
    if ec.measure_idx < new_len {
      Some(EditingChord::{ measure_idx: ec.measure_idx, chord_idx: 0 })
    } else if ec.measure_idx > 0 {
      let left_mi = ec.measure_idx - 1
      Some(EditingChord::{
        measure_idx: left_mi,
        chord_idx: measures[left_mi].chords.length() - 1,
      })
    } else {
      None
    }
  } else {
    // Chord removed within the same measure
    let new_chord_len = measure.chords.length() - 1
    if ec.chord_idx < new_chord_len {
      Some(ec)
    } else {
      Some(EditingChord::{
        measure_idx: ec.measure_idx,
        chord_idx: ec.chord_idx - 1,
      })
    }
  }
}

///|
extern "js" fn focus_next_tick(el : @js.Any) -> Unit =
  #|(el) => setTimeout(() => el.focus(), 0)

///|
/// Chord progression display — shows badges for each chord in the header.
/// No add buttons; always shows an Edit button. Truncates when long.
pub fn chord_progression_display(
  degree_measures : @signals.Signal[Array[@music.DegreeMeasure]],
  editing_chord : @signals.Signal[EditingChord?],
) -> @luna_dom.DomNode {
  @luna_dom.div(class="flex items-center gap-1 min-w-0 flex-1", [
    @luna_dom.label(
      class="hidden lg:inline text-sm text-slate-400 whitespace-nowrap",
      [@luna_dom.text("Chords:")],
    ),
    @luna_dom.div(
      class="flex items-center gap-1 flex-1 min-w-0 bg-slate-900 rounded px-2 py-1 lg:py-2 border border-slate-600",
      [
        @luna_dom.div(
          class="flex items-center gap-1 overflow-hidden flex-1 min-w-0",
          [
            @luna_dom.for_each(fn() { degree_measures.get() }, fn(measure, mi) {
              let chord_badges = measure.chords
                .iter()
                .mapi(fn(ci, chord) {
                  let label = chord.to_string()
                  @luna_dom.button(
                    dyn_class=fn() {
                      let is_editing = match editing_chord.get() {
                        Some(ec) => ec.measure_idx == mi && ec.chord_idx == ci
                        None => false
                      }
                      cn([
                        "px-2 py-0.5 text-sm rounded cursor-pointer transition-colors shrink-0",
                        if is_editing {
                          "bg-blue-600 text-white"
                        } else {
                          "bg-slate-700 text-white hover:bg-blue-700"
                        },
                      ])
                    },
                    attrs=[
                      (
                        "aria-label",
                        @luna_dom.Attr::AttrString("chord badge \{label}"),
                      ),
                    ],
                    on=@luna_dom.events().click(fn(_) {
                      editing_chord.set(
                        Some(EditingChord::{ measure_idx: mi, chord_idx: ci }),
                      )
                    }),
                    [@luna_dom.text(label)],
                  )
                })
                .collect()
              @luna_dom.div(
                class="flex items-center gap-1 shrink-0",
                [
                  ..chord_badges,
                  @luna_dom.show(
                    fn() { mi < degree_measures.get().length() - 1 },
                    fn() {
                      let merge_mi = mi
                      @luna_dom.button(
                        class="text-slate-400 px-0.5 select-none hover:text-white transition-colors cursor-pointer shrink-0",
                        attrs=[
                          (
                            "aria-label",
                            @luna_dom.Attr::AttrString("remove bar line"),
                          ),
                          (
                            "title",
                            @luna_dom.Attr::AttrString("Click to merge"),
                          ),
                        ],
                        on=@luna_dom.events().click(fn(_) {
                          let new_ec = next_editing_chord_after_merge(
                            degree_measures.peek(),
                            merge_mi,
                            editing_chord.peek(),
                          )
                          degree_measures.update(fn(measures) {
                            merge_measures_at(measures, merge_mi)
                          })
                          editing_chord.set(new_ec)
                        }),
                        [@luna_dom.text("|")],
                      )
                    },
                  ),
                ],
              )
            }),
          ],
        ),
        @luna_dom.button(
          class="px-2 py-0.5 text-sm text-slate-400 hover:text-white rounded cursor-pointer transition-colors shrink-0 ml-1",
          attrs=[("aria-label", @luna_dom.Attr::AttrString("edit chords"))],
          on=@luna_dom.events().click(fn(_) {
            if editing_chord.peek() is None {
              let measures = degree_measures.peek()
              let ec = if measures.is_empty() {
                EditingChord::{ measure_idx: 0, chord_idx: 0 }
              } else {
                EditingChord::{ measure_idx: 0, chord_idx: 0 }
              }
              editing_chord.set(Some(ec))
            }
          }),
          [@luna_dom.text("Edit")],
        ),
      ],
    ),
  ])
}

///|
/// Chord editor dialog — shown when editing_chord is Some(...)
pub fn chord_editor_dialog(
  editing_chord : @signals.Signal[EditingChord?],
  degree_measures : @signals.Signal[Array[@music.DegreeMeasure]],
  key : @signals.Signal[@music.KeySignature],
) -> @luna_dom.DomNode {
  @luna_dom.show(fn() { editing_chord.get() is Some(_) }, fn() {
    @luna_dom.div(class="fixed inset-0 z-50 flex items-center justify-center", [
      // Backdrop — click to close
      @luna_dom.div(
        class="absolute inset-0 bg-black/60",
        on=@luna_dom.events().click(fn(_) { editing_chord.set(None) }),
        [],
      ),
      // Dialog panel
      @luna_dom.div(
        class="relative z-10 bg-slate-800 rounded-xl p-4 max-w-md w-full mx-4 flex flex-col gap-4 shadow-2xl outline-none",
        attrs=[
          ("aria-label", @luna_dom.Attr::AttrString("chord editor dialog")),
          ("tabindex", @luna_dom.Attr::AttrString("-1")),
        ],
        ref_=fn(el) { focus_next_tick(el.as_any()) },
        on=@luna_dom.events().keydown(fn(e) {
          if e.key == "Backspace" {
            match editing_chord.peek() {
              None => ()
              Some(ec) => {
                let new_ec = next_editing_chord_after_delete(
                  degree_measures.peek(),
                  ec,
                )
                degree_measures.update(fn(measures) {
                  delete_chord_at(measures, ec)
                })
                editing_chord.set(new_ec)
                e.currentTarget().as_any()._call("focus", []) |> ignore
              }
            }
          }
        }),
        [
          // Title row
          @luna_dom.div(class="flex items-center justify-between", [
            @luna_dom.span(class="text-sm font-semibold text-white", [
              @luna_dom.text("Chords"),
            ]),
            @luna_dom.button(
              class="px-2 py-0.5 text-sm text-slate-400 hover:text-white transition-colors rounded cursor-pointer",
              attrs=[("aria-label", @luna_dom.Attr::AttrString("close dialog"))],
              on=@luna_dom.events().click(fn(_) { editing_chord.set(None) }),
              [@luna_dom.text("✕")],
            ),
          ]),
          // Chord progression preview with editing chord highlighted
          @luna_dom.div(class="flex items-center gap-1 flex-wrap", [
            @luna_dom.for_each(fn() { degree_measures.get() }, fn(measure, mi) {
              let chord_spans = measure.chords
                .iter()
                .mapi(fn(ci, chord) {
                  let label = chord.to_string()
                  @luna_dom.button(
                    dyn_class=fn() {
                      let is_editing = match editing_chord.get() {
                        Some(ec) => ec.measure_idx == mi && ec.chord_idx == ci
                        None => false
                      }
                      if is_editing {
                        "px-2 py-0.5 rounded bg-blue-600 text-white text-sm font-bold"
                      } else {
                        "px-2 py-0.5 rounded bg-slate-600 text-slate-300 text-sm hover:bg-slate-500 cursor-pointer"
                      }
                    },
                    on=@luna_dom.events().click(fn(_) {
                      editing_chord.set(
                        Some(EditingChord::{ measure_idx: mi, chord_idx: ci }),
                      )
                    }),
                    [@luna_dom.text(label)],
                  )
                })
                .collect()
              @luna_dom.div(
                class="flex items-center gap-1",
                [
                  ..chord_spans,
                  @luna_dom.show(
                    fn() { mi < degree_measures.get().length() - 1 },
                    fn() {
                      @luna_dom.span(class="text-slate-400 px-0.5", [
                        @luna_dom.text("|"),
                      ])
                    },
                  ),
                ],
              )
            }),
          ]),
          // Actions: + | on left, Delete on right
          @luna_dom.div(class="flex justify-between items-center", [
            @luna_dom.div(class="flex gap-2", [
              @luna_dom.button(
                dyn_class=fn() {
                  let at_limit = match editing_chord.get() {
                    Some(ec) =>
                      ec.measure_idx < degree_measures.get().length() &&
                      degree_measures.get()[ec.measure_idx].chords.length() >=
                      max_chords_per_measure
                    None => false
                  }
                  if at_limit {
                    "px-3 py-1 text-sm bg-slate-700 text-slate-500 rounded cursor-not-allowed"
                  } else {
                    "px-3 py-1 text-sm bg-slate-600 hover:bg-slate-500 text-white rounded transition-colors"
                  }
                },
                attrs=[
                  ("aria-label", @luna_dom.Attr::AttrString("add chord")),
                  (
                    "title",
                    @luna_dom.Attr::AttrString("Add chord after selected chord"),
                  ),
                ],
                on=@luna_dom.events().click(fn(_) {
                  match editing_chord.peek() {
                    None => {
                      degree_measures.update(fn(_) {
                        [
                          @music.DegreeMeasure::{
                            chords: [default_degree_chord],
                          },
                        ]
                      })
                      editing_chord.set(
                        Some(EditingChord::{ measure_idx: 0, chord_idx: 0 }),
                      )
                    }
                    Some(_) => {
                      let measures = degree_measures.peek()
                      if measures.is_empty() {
                        degree_measures.update(fn(_) {
                          [
                            @music.DegreeMeasure::{
                              chords: [default_degree_chord],
                            },
                          ]
                        })
                        editing_chord.set(
                          Some(EditingChord::{ measure_idx: 0, chord_idx: 0 }),
                        )
                      } else {
                        let ec = editing_chord.peek().unwrap()
                        guard ec.measure_idx < measures.length() else { return }
                        guard measures[ec.measure_idx].chords.length() <
                          max_chords_per_measure else {
                          return
                        }
                        degree_measures.update(fn(ms) {
                          insert_chord_after(ms, ec, default_degree_chord)
                        })
                        editing_chord.set(
                          Some(EditingChord::{
                            measure_idx: ec.measure_idx,
                            chord_idx: ec.chord_idx + 1,
                          }),
                        )
                      }
                    }
                  }
                }),
                [@luna_dom.text("+")],
              ),
              @luna_dom.button(
                class="px-3 py-1 text-sm bg-slate-600 hover:bg-slate-500 text-white rounded transition-colors",
                attrs=[
                  ("aria-label", @luna_dom.Attr::AttrString("add measure")),
                  (
                    "title",
                    @luna_dom.Attr::AttrString(
                      "Add measure after selected measure",
                    ),
                  ),
                ],
                on=@luna_dom.events().click(fn(_) {
                  match editing_chord.peek() {
                    None => ()
                    Some(ec) => {
                      let ms = degree_measures.peek()
                      if ms.is_empty() {
                        degree_measures.update(fn(_) {
                          [
                            @music.DegreeMeasure::{
                              chords: [default_degree_chord],
                            },
                          ]
                        })
                        editing_chord.set(
                          Some(EditingChord::{ measure_idx: 0, chord_idx: 0 }),
                        )
                        return
                      }
                      let measure = ms[ec.measure_idx]
                      let new_mi = ec.measure_idx + 1
                      if ec.chord_idx < measure.chords.length() - 1 {
                        // Split: chords after ec become a new measure
                        let left_chords = Array::makei(ec.chord_idx + 1, fn(i) {
                          measure.chords[i]
                        })
                        let right_chords = Array::makei(
                          measure.chords.length() - ec.chord_idx - 1,
                          fn(i) { measure.chords[ec.chord_idx + 1 + i] },
                        )
                        degree_measures.update(fn(ms) {
                          let new_ms = ms.copy()
                          new_ms[ec.measure_idx] = @music.DegreeMeasure::{
                            chords: left_chords,
                          }
                          insert_measure_after(new_ms, ec.measure_idx, @music.DegreeMeasure::{
                            chords: right_chords,
                          })
                        })
                      } else {
                        // Last chord in last measure: add new empty measure
                        degree_measures.update(fn(ms) {
                          insert_measure_after(ms, ec.measure_idx, @music.DegreeMeasure::{
                            chords: [default_degree_chord],
                          })
                        })
                      }
                      editing_chord.set(
                        Some(EditingChord::{ measure_idx: new_mi, chord_idx: 0 }),
                      )
                    }
                  }
                }),
                [@luna_dom.text("|")],
              ),
            ]),
            @luna_dom.button(
              class="px-3 py-1 text-sm bg-red-800 hover:bg-red-700 text-white rounded transition-colors",
              attrs=[("aria-label", @luna_dom.Attr::AttrString("delete chord"))],
              on=@luna_dom.events().click(fn(_) {
                match editing_chord.peek() {
                  None => ()
                  Some(ec) => {
                    let new_ec = next_editing_chord_after_delete(
                      degree_measures.peek(),
                      ec,
                    )
                    degree_measures.update(fn(measures) {
                      delete_chord_at(measures, ec)
                    })
                    editing_chord.set(new_ec)
                  }
                }
              }),
              [@luna_dom.text("Delete")],
            ),
          ]),
          // Divider
          @luna_dom.div(class="border-t border-slate-600", []),
          // Diatonic chord shortcuts
          @luna_dom.div(class="flex flex-col gap-1", [
            @luna_dom.div(
              class="text-xs text-slate-400 uppercase tracking-wide",
              [@luna_dom.text("Diatonic")],
            ),
            @luna_dom.div(class="grid grid-cols-7 gap-1 w-full", [
              @luna_dom.for_each(
                fn() {
                  [
                    (@music.I, @music.Major7),
                    (@music.II, @music.Minor7),
                    (@music.III, @music.Minor7),
                    (@music.IV, @music.Major7),
                    (@music.V, @music.Dominant7),
                    (@music.VI, @music.Minor7),
                    (@music.VII, @music.HalfDiminished),
                  ]
                },
                fn(item, _) {
                  let (degree, quality) = item
                  let label = degree.to_roman() + quality.to_string()
                  @luna_dom.button(
                    class="px-1 py-1 rounded text-xs transition-colors border border-slate-600 text-slate-400 hover:border-amber-400 hover:text-amber-200 cursor-pointer w-full",
                    attrs=[
                      (
                        "title",
                        @luna_dom.Attr::AttrString(
                          "Set to \{degree.to_roman()}\{quality.to_parse_string()}",
                        ),
                      ),
                    ],
                    on=@luna_dom.events().click(fn(_) {
                      match editing_chord.peek() {
                        None => ()
                        Some(ec) =>
                          degree_measures.update(fn(measures) {
                            match get_chord_at(measures, ec) {
                              None => measures
                              Some(chord) =>
                                update_chord_at(measures, ec, @music.DegreeChord::{
                                  ..chord,
                                  accidental: 0,
                                  degree,
                                  quality,
                                })
                            }
                          })
                      }
                    }),
                    [@luna_dom.text(label)],
                  )
                },
              ),
            ]),
          ]),
          // Degree selection
          @luna_dom.div(class="flex flex-col gap-1", [
            @luna_dom.div(
              class="text-xs text-slate-400 uppercase tracking-wide",
              [@luna_dom.text("Degree")],
            ),
            @luna_dom.div(class="grid grid-cols-7 gap-1 w-full", [
              @luna_dom.for_each(fn() { @music.all_degrees }, fn(degree, _) {
                let key_root = key.get().root
                let pc = (key_root.midi() + degree.semitones()) % 12
                let note_name = @music.ChordRoot::from_pitch_class(pc).to_string()
                @luna_dom.button(
                  dyn_class=fn() {
                    let active = match
                      get_chord_at(
                        degree_measures.get(),
                        match editing_chord.get() {
                          Some(ec) => ec
                          None => EditingChord::{ measure_idx: 0, chord_idx: 0 }
                        },
                      ) {
                      Some(chord) => chord.degree == degree
                      None => false
                    }
                    cn([
                      "flex flex-col items-center px-2 py-1 rounded text-xs transition-colors w-full",
                      if active {
                        "bg-blue-600 text-white"
                      } else {
                        "bg-slate-700 text-slate-300 hover:bg-slate-600"
                      },
                    ])
                  },
                  on=@luna_dom.events().click(fn(_) {
                    match editing_chord.peek() {
                      None => ()
                      Some(ec) =>
                        degree_measures.update(fn(measures) {
                          match get_chord_at(measures, ec) {
                            None => measures
                            Some(chord) =>
                              update_chord_at(measures, ec, @music.DegreeChord::{
                                ..chord,
                                accidental: 0,
                                degree,
                              })
                          }
                        })
                    }
                  }),
                  [
                    @luna_dom.div(class="font-bold", [
                      @luna_dom.text(degree.to_roman()),
                    ]),
                    @luna_dom.div(class="text-slate-400 text-xs", [
                      @luna_dom.text(note_name),
                    ]),
                  ],
                )
              }),
            ]),
          ]),
          // Quality selection
          @luna_dom.div(class="flex flex-col gap-1", [
            @luna_dom.div(
              class="text-xs text-slate-400 uppercase tracking-wide",
              [@luna_dom.text("Quality")],
            ),
            @luna_dom.div(class="grid grid-cols-4 gap-1", [
              @luna_dom.for_each(fn() { @music.all_qualities }, fn(quality, _) {
                @luna_dom.button(
                  dyn_class=fn() {
                    let active = match
                      get_chord_at(
                        degree_measures.get(),
                        match editing_chord.get() {
                          Some(ec) => ec
                          None => EditingChord::{ measure_idx: 0, chord_idx: 0 }
                        },
                      ) {
                      Some(chord) => chord.quality == quality
                      None => false
                    }
                    cn([
                      "px-2 py-1 rounded text-xs transition-colors",
                      if active {
                        "bg-blue-600 text-white"
                      } else {
                        "bg-slate-700 text-slate-300 hover:bg-slate-600"
                      },
                    ])
                  },
                  on=@luna_dom.events().click(fn(_) {
                    match editing_chord.peek() {
                      None => ()
                      Some(ec) =>
                        degree_measures.update(fn(measures) {
                          match get_chord_at(measures, ec) {
                            None => measures
                            Some(chord) =>
                              update_chord_at(measures, ec, @music.DegreeChord::{
                                ..chord,
                                quality,
                              })
                          }
                        })
                    }
                  }),
                  [@luna_dom.text(quality.to_string())],
                )
              }),
            ]),
          ]),
          // Bass selection (slash chord)
          @luna_dom.div(class="flex flex-col gap-1", [
            @luna_dom.div(
              class="text-xs text-slate-400 uppercase tracking-wide",
              [@luna_dom.text("Bass")],
            ),
            @luna_dom.div(class="grid grid-cols-8 gap-1 w-full", [
              // None button
              @luna_dom.button(
                dyn_class=fn() {
                  let active = match
                    get_chord_at(
                      degree_measures.get(),
                      match editing_chord.get() {
                        Some(ec) => ec
                        None => EditingChord::{ measure_idx: 0, chord_idx: 0 }
                      },
                    ) {
                    Some(chord) => chord.bass is None
                    None => true
                  }
                  cn([
                    "px-2 py-1 rounded text-xs transition-colors w-full",
                    if active {
                      "bg-blue-600 text-white"
                    } else {
                      "bg-slate-700 text-slate-300 hover:bg-slate-600"
                    },
                  ])
                },
                on=@luna_dom.events().click(fn(_) {
                  match editing_chord.peek() {
                    None => ()
                    Some(ec) =>
                      degree_measures.update(fn(measures) {
                        match get_chord_at(measures, ec) {
                          None => measures
                          Some(chord) =>
                            update_chord_at(measures, ec, @music.DegreeChord::{
                              ..chord,
                              bass: None,
                            })
                        }
                      })
                  }
                }),
                [@luna_dom.text("—")],
              ),
              // Degree buttons for bass
              @luna_dom.for_each(fn() { @music.all_degrees }, fn(
                bass_degree,
                _,
              ) {
                let key_root = key.get().root
                let pc = (key_root.midi() + bass_degree.semitones()) % 12
                let note_name = @music.ChordRoot::from_pitch_class(pc).to_string()
                @luna_dom.button(
                  dyn_class=fn() {
                    let active = match
                      get_chord_at(
                        degree_measures.get(),
                        match editing_chord.get() {
                          Some(ec) => ec
                          None => EditingChord::{ measure_idx: 0, chord_idx: 0 }
                        },
                      ) {
                      Some(chord) =>
                        match chord.bass {
                          Some(b) => b.degree == bass_degree
                          None => false
                        }
                      None => false
                    }
                    cn([
                      "flex flex-col items-center px-2 py-1 rounded text-xs transition-colors w-full",
                      if active {
                        "bg-blue-600 text-white"
                      } else {
                        "bg-slate-700 text-slate-300 hover:bg-slate-600"
                      },
                    ])
                  },
                  on=@luna_dom.events().click(fn(_) {
                    match editing_chord.peek() {
                      None => ()
                      Some(ec) =>
                        degree_measures.update(fn(measures) {
                          match get_chord_at(measures, ec) {
                            None => measures
                            Some(chord) => {
                              let new_accidental = match chord.bass {
                                Some(b) if b.degree == bass_degree =>
                                  b.accidental
                                _ => 0
                              }
                              update_chord_at(measures, ec, @music.DegreeChord::{
                                ..chord,
                                bass: Some(@music.DegreeBass::{
                                  accidental: new_accidental,
                                  degree: bass_degree,
                                }),
                              })
                            }
                          }
                        })
                    }
                  }),
                  [
                    @luna_dom.div(class="font-bold", [
                      @luna_dom.text(bass_degree.to_roman()),
                    ]),
                    @luna_dom.div(class="text-slate-400 text-xs", [
                      @luna_dom.text(note_name),
                    ]),
                  ],
                )
              }),
            ]),
            // Accidental row — shown when bass is Some
            @luna_dom.show(
              fn() {
                match editing_chord.get() {
                  Some(ec) =>
                    match get_chord_at(degree_measures.get(), ec) {
                      Some(chord) => chord.bass is Some(_)
                      None => false
                    }
                  None => false
                }
              },
              fn() {
                @luna_dom.div(class="flex gap-1 mt-1", [
                  @luna_dom.for_each(
                    fn() { [(-1, "b"), (0, "♮"), (1, "#")] },
                    fn(item, _) {
                      let (acc_val, acc_label) = item
                      @luna_dom.button(
                        dyn_class=fn() {
                          let active = match editing_chord.get() {
                            Some(ec) =>
                              match get_chord_at(degree_measures.get(), ec) {
                                Some(chord) =>
                                  match chord.bass {
                                    Some(b) => b.accidental == acc_val
                                    None => false
                                  }
                                None => false
                              }
                            None => false
                          }
                          cn([
                            "px-3 py-1 rounded text-xs transition-colors",
                            if active {
                              "bg-blue-600 text-white"
                            } else {
                              "bg-slate-700 text-slate-300 hover:bg-slate-600"
                            },
                          ])
                        },
                        on=@luna_dom.events().click(fn(_) {
                          match editing_chord.peek() {
                            None => ()
                            Some(ec) =>
                              degree_measures.update(fn(measures) {
                                match get_chord_at(measures, ec) {
                                  None => measures
                                  Some(chord) =>
                                    match chord.bass {
                                      None => measures
                                      Some(b) =>
                                        update_chord_at(measures, ec, @music.DegreeChord::{
                                          ..chord,
                                          bass: Some(@music.DegreeBass::{
                                            ..b,
                                            accidental: acc_val,
                                          }),
                                        })
                                    }
                                }
                              })
                          }
                        }),
                        [@luna_dom.text(acc_label)],
                      )
                    },
                  ),
                ])
              },
            ),
          ]),
        ],
      ),
    ])
  })
}
