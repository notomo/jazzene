///|
/// Chord progression editor - structured GUI for building chord progressions

///|
/// Identifies which chord is being edited in the dialog
pub(all) struct EditingChord {
  measure_idx : Int
  chord_idx : Int
} derive(Eq, Show)

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
  Array::makei(measures.length() - 1, fn(i) {
    if i < mi {
      measures[i]
    } else if i == mi {
      @music.DegreeMeasure::{ chords: merged_chords }
    } else {
      measures[i + 1]
    }
  })
}

///|
/// Split the measure at ec.measure_idx before ec.chord_idx
fn split_measure_at(
  measures : Array[@music.DegreeMeasure],
  ec : EditingChord,
) -> Array[@music.DegreeMeasure] {
  guard ec.measure_idx < measures.length() else { return measures }
  let measure = measures[ec.measure_idx]
  guard ec.chord_idx > 0 && ec.chord_idx < measure.chords.length() else {
    return measures
  }
  let left_chords = Array::makei(ec.chord_idx, fn(i) { measure.chords[i] })
  let right_chords = Array::makei(measure.chords.length() - ec.chord_idx, fn(
    i,
  ) {
    measure.chords[ec.chord_idx + i]
  })
  let result : Array[@music.DegreeMeasure] = []
  for i in 0..<measures.length() {
    if i == ec.measure_idx {
      result.push(@music.DegreeMeasure::{ chords: left_chords })
      result.push(@music.DegreeMeasure::{ chords: right_chords })
    } else {
      result.push(measures[i])
    }
  }
  result
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
    Array::makei(measures.length() - 1, fn(i) {
      if i < ec.measure_idx {
        measures[i]
      } else {
        measures[i + 1]
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
/// Chord progression display — shows badges for each chord in the header.
/// No add buttons; always shows an Edit button. Truncates when long.
pub fn chord_progression_display(
  degree_measures : @signals.Signal[Array[@music.DegreeMeasure]],
  key : @signals.Signal[@music.KeySignature],
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
              let key_root = key.get().root
              let chord_badges = measure.chords
                .iter()
                .mapi(fn(ci, chord) {
                  let label = @music.format_chord(chord.resolve(key_root))
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
                          degree_measures.update(fn(measures) {
                            merge_measures_at(measures, merge_mi)
                          })
                          editing_chord.set(None)
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
        class="relative z-10 bg-slate-800 rounded-xl p-4 max-w-md w-full mx-4 flex flex-col gap-4 shadow-2xl",
        attrs=[
          ("aria-label", @luna_dom.Attr::AttrString("chord editor dialog")),
        ],
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
          // Upper: current progression preview with editing chord highlighted
          @luna_dom.div(class="flex items-center gap-1 flex-wrap", [
            @luna_dom.for_each(fn() { degree_measures.get() }, fn(measure, mi) {
              let key_root = key.get().root
              let chord_spans = measure.chords
                .iter()
                .mapi(fn(ci, chord) {
                  let label = @music.format_chord(chord.resolve(key_root))
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
          // Divider
          @luna_dom.div(class="border-t border-slate-600", []),
          // Degree selection
          @luna_dom.div(class="flex flex-col gap-1", [
            @luna_dom.div(
              class="text-xs text-slate-400 uppercase tracking-wide",
              [@luna_dom.text("Degree")],
            ),
            @luna_dom.div(class="flex gap-1 flex-wrap", [
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
                      "flex flex-col items-center px-2 py-1 rounded text-xs transition-colors min-w-8",
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
            @luna_dom.div(class="flex flex-wrap gap-1", [
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
            @luna_dom.div(class="flex gap-1 flex-wrap", [
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
                      "flex flex-col items-center px-2 py-1 rounded text-xs transition-colors min-w-8",
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
          // Actions: Delete + Split + Add chord + Add measure
          @luna_dom.div(class="flex justify-between items-center", [
            @luna_dom.div(class="flex gap-2", [
              @luna_dom.button(
                class="px-3 py-1 text-sm bg-red-800 hover:bg-red-700 text-white rounded transition-colors",
                attrs=[
                  ("aria-label", @luna_dom.Attr::AttrString("delete chord")),
                ],
                on=@luna_dom.events().click(fn(_) {
                  match editing_chord.peek() {
                    None => ()
                    Some(ec) =>
                      degree_measures.update(fn(measures) {
                        delete_chord_at(measures, ec)
                      })
                  }
                }),
                [@luna_dom.text("Delete")],
              ),
              @luna_dom.show(
                fn() {
                  match editing_chord.get() {
                    Some(ec) => ec.chord_idx > 0
                    None => false
                  }
                },
                fn() {
                  @luna_dom.button(
                    class="px-3 py-1 text-sm bg-slate-600 hover:bg-slate-500 text-white rounded transition-colors",
                    attrs=[
                      (
                        "aria-label",
                        @luna_dom.Attr::AttrString("split measure"),
                      ),
                    ],
                    on=@luna_dom.events().click(fn(_) {
                      match editing_chord.peek() {
                        None => ()
                        Some(ec) => {
                          degree_measures.update(fn(measures) {
                            split_measure_at(measures, ec)
                          })
                          editing_chord.set(
                            Some(EditingChord::{
                              measure_idx: ec.measure_idx + 1,
                              chord_idx: 0,
                            }),
                          )
                        }
                      }
                    }),
                    [@luna_dom.text("Split |")],
                  )
                },
              ),
            ]),
            @luna_dom.div(class="flex gap-2", [
              @luna_dom.button(
                dyn_class=fn() {
                  let at_limit = match degree_measures.get() {
                    ms if ms.is_empty() => false
                    ms =>
                      ms[ms.length() - 1].chords.length() >=
                      max_chords_per_measure
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
                    @luna_dom.Attr::AttrString("Add chord to last measure"),
                  ),
                ],
                on=@luna_dom.events().click(fn(_) {
                  let measures = degree_measures.peek()
                  let at_limit = match measures {
                    ms if ms.is_empty() => false
                    ms =>
                      ms[ms.length() - 1].chords.length() >=
                      max_chords_per_measure
                  }
                  guard not(at_limit) else { return }
                  let (mi, ci) = if measures.is_empty() {
                    (0, 0)
                  } else {
                    let last_mi = measures.length() - 1
                    (last_mi, measures[last_mi].chords.length())
                  }
                  degree_measures.update(fn(ms) {
                    if ms.is_empty() {
                      [@music.DegreeMeasure::{ chords: [default_degree_chord] }]
                    } else {
                      let new_ms = ms.copy()
                      let last_idx = new_ms.length() - 1
                      let last = new_ms[last_idx]
                      let new_chords = last.chords.copy()
                      new_chords.push(default_degree_chord)
                      new_ms[last_idx] = @music.DegreeMeasure::{
                        chords: new_chords,
                      }
                      new_ms
                    }
                  })
                  editing_chord.set(
                    Some(EditingChord::{ measure_idx: mi, chord_idx: ci }),
                  )
                }),
                [@luna_dom.text("+")],
              ),
              @luna_dom.button(
                class="px-3 py-1 text-sm bg-slate-600 hover:bg-slate-500 text-white rounded transition-colors",
                attrs=[
                  ("aria-label", @luna_dom.Attr::AttrString("add measure")),
                  ("title", @luna_dom.Attr::AttrString("Add new measure")),
                ],
                on=@luna_dom.events().click(fn(_) {
                  let mi = degree_measures.peek().length()
                  degree_measures.update(fn(ms) {
                    let new_ms = ms.copy()
                    new_ms.push(@music.DegreeMeasure::{
                      chords: [default_degree_chord],
                    })
                    new_ms
                  })
                  editing_chord.set(
                    Some(EditingChord::{ measure_idx: mi, chord_idx: 0 }),
                  )
                }),
                [@luna_dom.text("|+")],
              ),
            ]),
          ]),
        ],
      ),
    ])
  })
}
