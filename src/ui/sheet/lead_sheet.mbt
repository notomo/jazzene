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

  clamped_idx / @sheet_layout.MEASURES_PER_ROW
}

///|
/// Main lead sheet component
pub fn lead_sheet(
  measures : () -> Array[@music.Measure],
  playback_position : @signals.Signal[@music.Duration],
  bpm : @signals.Signal[Int],
  key : @signals.Signal[@music.KeySignature],
  time_signature : @signals.Signal[@music.TimeSignature],
  loop_a_measure : @signals.Signal[Int],
  loop_b_measure : @signals.Signal[Int],
) -> @luna_dom.DomNode {
  // Set up auto-scroll effect
  let last_scrolled_row : Ref[Int] = Ref::new(-1)
  let _ = @signals.effect(fn() {
    let measure_count = measures().length()
    let beats_per_measure = time_signature.get().beats_per_measure()
    let current_row = calculate_playback_row(
      playback_position.get(),
      bpm.get(),
      measure_count,
      beats_per_measure~,
    )
    if current_row == last_scrolled_row.val {
      return
    }
    last_scrolled_row.val = current_row
    match @js_dom.document().getElementById(LEAD_SHEET_CONTAINER_ID) {
      Some(container) => {
        let svg = container.querySelector("svg")
        guard svg is Some(svg_element) else { return }
        let svg_height = svg_element.clientHeight()
        if svg_height <= 0 {
          return
        }
        let total_rows = (measure_count + @sheet_layout.MEASURES_PER_ROW - 1) /
          @sheet_layout.MEASURES_PER_ROW
        let viewbox_height = @sheet_layout.STAFF_TOP +
          total_rows.to_double() * @sheet_layout.ROW_HEIGHT
        let scale = svg_height.to_double() / viewbox_height
        let row_top_svg = @sheet_layout.STAFF_TOP +
          current_row.to_double() * @sheet_layout.ROW_HEIGHT
        let row_top_px = (row_top_svg * scale).to_int()
        let row_bottom_svg = @sheet_layout.STAFF_TOP +
          (current_row + 1).to_double() * @sheet_layout.ROW_HEIGHT
        let row_bottom_px = (row_bottom_svg * scale).to_int()
        let scroll_top = container.scrollTop()
        let visible_height = container.clientHeight()
        let visible_bottom = scroll_top + visible_height
        let row_height_px = row_bottom_px - row_top_px
        let max_margin = @cmp.maximum(0, (visible_height - row_height_px) / 2)
        let margin = @cmp.minimum(
          (@sheet_layout.ROW_HEIGHT * scale).to_int(),
          max_margin,
        )
        if row_top_px - margin < scroll_top {
          let new_scroll = row_top_px - margin
          scroll_element_to(container, @cmp.maximum(0, new_scroll))
        } else if row_bottom_px + margin > visible_bottom {
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
            let ms = measures()
            let measure_count = ms.length()
            let rows = (measure_count + @sheet_layout.MEASURES_PER_ROW - 1) /
              @sheet_layout.MEASURES_PER_ROW
            let height = @sheet_layout.STAFF_TOP +
              rows.to_double() * @sheet_layout.ROW_HEIGHT
            let k = key.get()
            let ts = time_signature.get()
            let key_sig_width = @sheet_layout.key_signature_layout_width(k)
            let mw = @sheet_layout.compute_unified_measure_width(ms, ts)
            let viewbox_start_x = @sheet_layout.MEASURE_START_X - 15.0
            let width = @sheet_layout.MEASURE_START_X -
              viewbox_start_x +
              @sheet_layout.CLEF_SPACE_WIDTH +
              key_sig_width +
              @sheet_layout.MEASURES_PER_ROW.to_double() * mw
            "\{viewbox_start_x.to_int()} \{0} \{width.to_int()} \{height.to_int()}"
          }),
        ),
      ],
      [
        @luna_dom.for_each(measures, fn(m, idx) {
          let ts = time_signature.get()
          let k = key.get()
          let mw = @sheet_layout.compute_unified_measure_width(measures(), ts)
          render_measure(m, idx, playback_position, k, ts, measure_width=mw, fn() {
            let measure_number = idx + 1
            measure_number < loop_a_measure.get() ||
            measure_number > loop_b_measure.get()
          })
        }),
        render_playback_indicator(
          playback_position,
          bpm,
          fn() { measures().length() },
          key,
          time_signature,
          fn() {
            let ts = time_signature.get()
            @sheet_layout.compute_unified_measure_width(measures(), ts)
          },
        ),
      ],
    ),
  ])
}
