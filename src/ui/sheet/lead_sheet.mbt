///|
/// Main lead sheet component - orchestrates all sheet music rendering

///|
/// Main lead sheet component
pub fn lead_sheet(
  measures : () -> Array[@music.Measure],
  playback_position : @signal.Signal[@music.Duration],
  bpm : @signal.Signal[Int],
) -> @luna_dom.DomNode {
  // Calculate current measure index
  let current_measure_index = @signal.memo(fn() {
    let pos = playback_position.get().to_milliseconds()
    let measure_duration_ms = @music.ms_per_measure(bpm.get())
    if measure_duration_ms > 0.0 {
      // Leading rest is measure 0, chord measures start at 1
      let measure_idx = (pos / measure_duration_ms).to_int()
      // For measure 0 (leading rest), return -1 to not highlight any chord
      // For measures >= 1, return the measure index
      if measure_idx == 0 {
        -1 // Still in leading rest, no chord to highlight
      } else {
        measure_idx
      }
    } else {
      0
    }
  })

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
            "0 0 1200 \{height.to_int().to_string()}"
          }),
        ),
      ],
      [
        @luna_dom.for_each(measures, fn(m, idx) {
          render_measure(m, idx, current_measure_index)
        }),
      ],
    ),
  ])
}
