///|
/// Main lead sheet component - orchestrates all sheet music rendering

///|
let lead_sheet_container_id = "lead-sheet-container"

///|
extern "js" fn scroll_element_to(element : @js_dom.Element, top : Int) -> Unit =
  #|(element, top) => { element.scrollTo({ top: top, behavior: 'smooth' }); }

///|
/// Calculate the current playback row based on position
fn calculate_playback_row(
  position : @music.Duration,
  bpm : Int,
  measure_count : Int,
) -> Int {
  let pos_ms = position.to_milliseconds()
  let ms_per_measure = @music.ms_per_measure(bpm)
  if ms_per_measure <= 0.0 || measure_count <= 0 {
    return 0
  }
  let measure_idx = (pos_ms / ms_per_measure).to_int()
  let clamped_idx = if measure_idx >= measure_count {
    measure_count - 1
  } else {
    measure_idx
  }
  clamped_idx / measures_per_row
}

///|
/// Main lead sheet component
pub fn lead_sheet(
  measures : () -> Array[@music.Measure],
  playback_position : @signal.Signal[@music.Duration],
  bpm : @signal.Signal[Int],
) -> @luna_dom.DomNode {
  // Set up auto-scroll effect
  let _ = @signal.effect(fn() {
    let measure_count = measures().length()
    let current_row = calculate_playback_row(
      playback_position.get(),
      bpm.get(),
      measure_count,
    )
    match @js_dom.document().getElementById(lead_sheet_container_id) {
      Some(container) => {
        // Get the SVG element to calculate the scale factor
        let svg = container.querySelector("svg")
        guard svg is Some(svg_element) else { return }
        let svg_height = svg_element.clientHeight()
        if svg_height <= 0 {
          return
        }
        // Calculate total rows and SVG viewBox height
        let total_rows = (measure_count + measures_per_row - 1) /
          measures_per_row
        let viewbox_height = staff_top + total_rows.to_double() * row_height
        // Scale factor: how many pixels per SVG unit
        let scale = svg_height.to_double() / viewbox_height
        // Current row's bottom position in pixels
        let row_bottom_svg = staff_top +
          (current_row + 1).to_double() * row_height
        let row_bottom_px = (row_bottom_svg * scale).to_int()
        // Visible area
        let scroll_top = container.scrollTop()
        let visible_height = container.clientHeight()
        let visible_bottom = scroll_top + visible_height
        // Only scroll if the current row's bottom is below the visible area
        // Add margin so the next row is fully visible
        let margin = (row_height * scale).to_int()
        if row_bottom_px + margin > visible_bottom {
          let new_scroll = row_bottom_px + margin - visible_height
          scroll_element_to(container, new_scroll)
        }
      }
      None => ()
    }
  })

  // Return container with SVG
  @luna_dom.div(
    class="w-full h-full overflow-auto bg-gray-900 p-4",
    attrs=[("id", @luna_dom.Attr::AttrString(lead_sheet_container_id))],
    [
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
              let rows = (measure_count + measures_per_row - 1) /
                measures_per_row
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
    ],
  )
}
