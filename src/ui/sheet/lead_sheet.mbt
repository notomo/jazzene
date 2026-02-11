///|
/// Main lead sheet component - orchestrates all sheet music rendering

///|
const COLOR_FOREGROUND = "#f1f5f9"

///|
const LEAD_SHEET_CONTAINER_ID = "lead-sheet-container"

///|
extern "js" fn scroll_element_to(element : @js_dom.Element, top : Int) -> Unit =
  #|(element, top) => { element.scrollTo({ top: top, behavior: 'smooth' }); }

///|
/// Calculate the current playback row based on position
fn calculate_playback_row(
  position : @music.Duration,
  bpm : Int,
  measure_count : Int,
  beats_per_measure~ : Double,
) -> Int {
  let pos_ms = position.to_milliseconds()
  let ms_per_measure = @music.ms_per_measure(bpm, beats_per_measure~)
  if ms_per_measure <= 0.0 || measure_count <= 0 {
    return 0
  }

  let measure_idx = (pos_ms / ms_per_measure).to_int()
  let clamped_idx = if measure_idx >= measure_count {
    measure_count - 1
  } else {
    measure_idx
  }

  clamped_idx / MEASURES_PER_ROW
}

///|
/// Main lead sheet component
pub fn lead_sheet(
  measures : () -> Array[@music.Measure],
  playback_position : @signal.Signal[@music.Duration],
  bpm : @signal.Signal[Int],
  key : @signal.Signal[@music.KeySignature],
  time_signature : @signal.Signal[@music.TimeSignature],
) -> @luna_dom.DomNode {
  // Set up auto-scroll effect
  let _ = @signal.effect(fn() {
    let measure_count = measures().length()
    let beats_per_measure = time_signature.get().beats_per_measure()
    let current_row = calculate_playback_row(
      playback_position.get(),
      bpm.get(),
      measure_count,
      beats_per_measure~,
    )
    match @js_dom.document().getElementById(LEAD_SHEET_CONTAINER_ID) {
      Some(container) => {
        // Get the SVG element to calculate the scale factor
        let svg = container.querySelector("svg")
        guard svg is Some(svg_element) else { return }
        let svg_height = svg_element.clientHeight()
        if svg_height <= 0 {
          return
        }
        // Calculate total rows and SVG viewBox height
        let total_rows = (measure_count + MEASURES_PER_ROW - 1) /
          MEASURES_PER_ROW
        let viewbox_height = STAFF_TOP + total_rows.to_double() * ROW_HEIGHT
        // Scale factor: how many pixels per SVG unit
        let scale = svg_height.to_double() / viewbox_height
        // Current row's position in pixels
        let row_top_svg = STAFF_TOP + current_row.to_double() * ROW_HEIGHT
        let row_top_px = (row_top_svg * scale).to_int()
        let row_bottom_svg = STAFF_TOP +
          (current_row + 1).to_double() * ROW_HEIGHT
        let row_bottom_px = (row_bottom_svg * scale).to_int()
        // Visible area
        let scroll_top = container.scrollTop()
        let visible_height = container.clientHeight()
        let visible_bottom = scroll_top + visible_height
        // Margin to show the next/previous row
        let margin = (ROW_HEIGHT * scale).to_int()
        // Scroll up if the current row's top is above the visible area
        if row_top_px - margin < scroll_top {
          let new_scroll = row_top_px - margin
          scroll_element_to(container, @cmp.maximum(0, new_scroll))
        } else if row_bottom_px + margin > visible_bottom {
          // Scroll down if the current row's bottom is below the visible area
          let new_scroll = row_bottom_px + margin - visible_height
          scroll_element_to(container, new_scroll)
        }
      }
      None => ()
    }
  })

  // Return container with SVG
  @luna_dom.div(class="w-full p-4", [
    @luna_dom.svg(
      attrs=[
        ("preserveAspectRatio", @luna_dom.Attr::AttrString("xMidYMin meet")),
      ],
      width="100%",
      fill=COLOR_FOREGROUND,
      stroke=COLOR_FOREGROUND,
      dyn_attrs=[
        (
          "viewBox",
          @luna_dom.AttrValue::Dynamic(fn() {
            let measure_count = measures().length()
            let rows = (measure_count + MEASURES_PER_ROW - 1) / MEASURES_PER_ROW
            let height = STAFF_TOP + rows.to_double() * ROW_HEIGHT
            let key_sig_width = key_signature_width(key.get())
            let viewbox_start_x = MEASURE_START_X - 15.0
            let width = MEASURE_START_X -
              viewbox_start_x +
              CLEF_SPACE_WIDTH +
              key_sig_width +
              MEASURES_PER_ROW.to_double() * MEASURE_WIDTH
            "\{viewbox_start_x.to_int()} \{0} \{width.to_int()} \{height.to_int()}"
          }),
        ),
      ],
      [
        // Static measure elements (no current_measure_index dependency)
        @luna_dom.for_each(measures, fn(m, idx) {
          let ts = time_signature.get()
          render_measure(
            m,
            idx,
            playback_position,
            key.get(),
            ts.beats_per_measure(),
            ts,
          )
        }),
        // Playback position indicator overlay
        render_playback_indicator(
          playback_position,
          bpm,
          fn() { measures().length() },
          key,
          time_signature,
        ),
      ],
    ),
  ])
}
