///|
/// Rest symbol rendering (quarter, half, eighth rests with dots)

///|
let rest_scale_divisor = 40.0

///|
/// Render a single rest symbol
fn render_rest(
  note : @music.MeasureNote,
  note_x : Double,
  staff_y : Double,
) -> Array[@luna_dom.DomNode] {
  let children : Array[@luna_dom.DomNode] = []

  // Render rest
  let rest_y = staff_y + staff_line_spacing * 2.0
  children.push(
    match note.duration {
      Quarter | DottedQuarter => {
        // Quarter rest with detailed SVG path
        let scale = staff_line_spacing / rest_scale_divisor
        let transform_str = "scale(" +
          scale.to_string() +
          ") translate(" +
          (note_x / scale).to_string() +
          " " +
          (rest_y / scale).to_string() +
          ")"
        @luna_dom.svg_path(
          d="m -16.211221,-70.215638 c -1.61619,1.614428 -1.011,3.125643 1.00395,5.644331 2.01495,2.51869 16.8752195,21.912602 17.1270895,23.675682 0.25187,1.76308 -14.3565295,36.0172608 -14.1046595,39.0396808 0.25187,3.02243 23.641819,32.2836802 23.641819,32.2836802 0,0 -6.1681595,-5.06483 -13.8442995,-6.74396 -5.74739,-1.25721 -11.6310095,0.39343 -16.1196095,6.29672 -4.90857,6.45564 -6.47301,15.64047 -2.24145,23.57473 3.66088,6.86424 13.6009195,15.37074 18.8901695,15.364 4.18228,-0.005 4.28177,-1.00747 3.52616,-2.26682 -0.75560996,-1.25934 -19.3229595,-17.78691 -7.05233,-26.94997 10.05045,-7.50515 20.7031805,-1.07037 22.4662605,0.44084 1.76308,1.51121 3.5431,3.29123 5.80992,1.52815 2.26682,-1.76308 3.50923,-2.03189 -0.0169,-5.80992 -3.52617,-3.77803 -10.88029,-13.53803 -13.3989805,-20.59036 -2.51869,-7.0523302 -3.02243,-9.3191502 -0.75561,-14.6084002 2.2668195,-5.28925 13.0971905,-29.7205298 12.3415805,-32.4910898 -0.75561,-2.770561 -32.73768,-36.767581 -33.74515,-37.775056 -1.00748,-1.007475 -1.91526,-2.020238 -3.52793,-0.612238 z",
          fill=color_foreground,
          stroke="none",
          attrs=[("transform", @luna_dom.Attr::AttrString(transform_str))],
        )
      }
      Half | DottedHalf => {
        // Half rest - rectangle with bottom touching center line
        let rest_width = staff_line_spacing * 2.0
        let rest_height = staff_line_spacing / 2.0
        @luna_dom.svg_rect(
          x=(note_x - rest_width / 2.0).to_string(),
          y=(rest_y - rest_height).to_string(),
          width=rest_width.to_string(),
          height=rest_height.to_string(),
          fill=color_foreground,
        )
      }
      Whole => {
        // Whole rest - rectangle with top touching center line
        let rest_width = staff_line_spacing * 2.0
        let rest_height = staff_line_spacing / 2.0
        @luna_dom.svg_rect(
          x=(note_x - rest_width / 2.0).to_string(),
          y=rest_y.to_string(),
          width=rest_width.to_string(),
          height=rest_height.to_string(),
          fill=color_foreground,
        )
      }
      Eighth | DottedEighth => {
        // Eighth rest with detailed SVG path
        let scale = staff_line_spacing / rest_scale_divisor
        let transform_str = "scale(" +
          scale.to_string() +
          ") translate(" +
          (note_x / scale).to_string() +
          " " +
          (rest_y / scale).to_string() +
          ")"
        @luna_dom.svg_path(
          d="m 3.8445495,48.209315 c 2.61469,0.79432 4.67175,-1.61714 5.57016,-4.31238 0.8984105,-2.69524 16.7104905,-69.5372 17.2495405,-71.33403 0.53905,-1.79682 -0.35937,-4.49206 -1.79683,-4.67175 -1.43746,-0.17968 -3.23429,1.0781 -3.77334,3.59366 -0.53904,2.51555 -1.71153,6.15488 -2.78963,7.41266 -1.07809,1.25778 -6.91323,6.78227 -10.8662505,8.21973 -3.95302,1.43746 -10.84962,2.9872902 -11.32001,1.61714 -0.32006,-0.93228 1.72138,-1.27833 3.59365996,-3.59365 1.20101,-1.48521 2.33587004,-5.57016 1.79682004,-7.90604 -0.53905004,-2.33587 -2.69524,-7.90603 -7.366989,-9.70286 -4.6717485,-1.79683 -10.6012775,-0.53905 -13.8355655,4.1327 -3.234288,4.67175 -3.234288,11.49969 0.179684,15.27303 3.413969,3.7733302 9.343498,7.7263502 17.9682705,6.6482602 8.62476,-1.0781 14.3746105,-4.1327102 15.8120705,-5.2108002 1.43746,-1.0781 3.05461,-2.51556 3.05461,-2.51556 0,0 -15.6962205,54.82677 -16.59463054,57.16265 -0.89841,2.33587 0.60287004,4.53233 3.11843004,5.18724 z",
          fill=color_foreground,
          stroke="none",
          attrs=[("transform", @luna_dom.Attr::AttrString(transform_str))],
        )
      }
    },
  )

  // Dot for dotted rests
  match note.duration {
    DottedEighth | DottedQuarter | DottedHalf => {
      let dot_radius = staff_line_spacing * dot_radius_ratio
      let dot_x = note_x + staff_line_spacing * dot_x_offset_ratio
      let dot_y = rest_y
      children.push(
        @luna_dom.svg_circle(
          cx=dot_x.to_string(),
          cy=dot_y.to_string(),
          r=dot_radius.to_string(),
          fill=color_foreground,
        ),
      )
    }
    _ => ()
  }
  children
}
