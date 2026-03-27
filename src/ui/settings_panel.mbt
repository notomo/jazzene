///|
/// Settings panel for jazz style configuration.
/// Contains controls for legend, swing, melody techniques, comping, bass, and drums.

///|
/// Render the settings panel with jazz style controls.
pub fn settings_panel(
  jazz_style : @signals.Signal[@music.JazzStyle],
  show_technique_hints : @signals.Signal[Bool],
  midi_active_notes : @signals.Signal[Array[@music.MidiNumber]],
  get_midi_bytes : () -> Array[Int],
  on_import : (Array[Int]) -> Unit,
  imported_midi : @signals.Signal[@midi.ImportedMidi?],
  is_recording : @signals.Signal[Bool],
  recorded_lines : @signals.Signal[Array[RecordedLine]],
  on_note_on : (@music.MidiNumber) -> Unit,
  on_note_off : (@music.MidiNumber) -> Unit,
  practice_score : @signals.Signal[Double],
  practice_best_score : @signals.Signal[Double],
  practice_max_score : () -> Int,
) -> @luna_dom.DomNode {
  let midi_imported = fn() { imported_midi.get() is Some(_) }
  @luna_dom.div(
    class="bg-slate-800 border-l border-slate-600 p-3 overflow-y-auto flex flex-col gap-3 w-64 shrink-0",
    attrs=[
      ("id", @luna_dom.Attr::AttrString("settings-panel")),
      ("aria-label", @luna_dom.Attr::AttrString("jazz settings panel")),
    ],
    [
      settings_section("MIDI", [
        midi_device_select(midi_active_notes, on_note_on~, on_note_off~),
        @luna_dom.div(class="flex gap-1", [
          midi_import_button(on_import),
          midi_export_button(get_midi_bytes),
        ]),
        midi_recording(is_recording, recorded_lines),
        midi_practice(practice_score, practice_best_score, practice_max_score),
      ]),
      legend_section(show_technique_hints),
      preset_section(jazz_style),
      melody_section(jazz_style),
      settings_section("Pitch Range", [pitch_range_slider(jazz_style)]),
      swing_section(jazz_style),
      melody_techniques_section(jazz_style),
      comping_section(jazz_style, midi_imported),
      bass_section(jazz_style, midi_imported),
      drums_section(jazz_style, midi_imported),
    ],
  )
}
