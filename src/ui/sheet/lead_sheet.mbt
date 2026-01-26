///|
/// Main lead sheet component - orchestrates all sheet music rendering

///|
/// Main lead sheet component
pub fn lead_sheet(
  measures : () -> Array[@music.Measure],
  playback_position : @signal.Signal[@music.Duration],
  bpm : @signal.Signal[Int],
) -> @luna_dom.DomNode {
  // Return container with SVG
  @luna_dom.div(class="w-full h-full overflow-auto bg-gray-900 p-4", [
    @luna_dom.svg(
      attrs=[
        ("preserveAspectRatio", @luna_dom.Attr::AttrString("xMinYMin meet")),
      ],
      width="100%",
      dyn_attrs=[
        (
          "viewBox",
          @luna_dom.AttrValue::Dynamic(fn() {
            let measure_count = measures().length()
            let rows = (measure_count + measures_per_row - 1) / measures_per_row
            let height = staff_top + rows.to_double() * row_height
            let width = measure_start_x +
              clef_space_width +
              measures_per_row.to_double() * measure_width
            "\{0} \{0} \{width.to_int()} \{height.to_int()}"
          }),
        ),
      ],
      [
        // Static measure elements (no current_measure_index dependency)
        @luna_dom.for_each(measures, fn(m, idx) {
          render_measure(m, idx, playback_position)
        }),
        // Playback position indicator overlay
        render_playback_indicator(playback_position, bpm, fn() {
          measures().length()
        }),
      ],
    ),
  ])
}
