///|
/// Note rendering (heads, stems, flags, dots, ledger lines)

///|
/// Render a sharp accidental symbol
fn render_sharp(x : Double, y : Double) -> @luna_dom.DomNode {
  let scale = staff_line_spacing / 50.0
  let transform_str = "scale(" +
    scale.to_string() +
    ") translate(" +
    (x / scale).to_string() +
    " " +
    (y / scale).to_string() +
    ")"
  @luna_dom.svg_path(
    d="m 11.967664,-92.777598 c -2.592279,2.937274 -3.6034477,12.33642 -4.1191285,16.448606 -0.2774289,2.212313 -0.7606507,23.078514 -1.2247298,43.183928 -3.6203519,1.384509 -7.38501817,2.863046 -10.9357661,4.30103 0.5525928,-16.197194 0.9406466,-28.486102 0.8397398,-29.115536 -0.3296179,-2.05609 -1.9318763,-9.693465 -3.1067851,-9.693465 -2.0458297,0.58746 -2.4843925,9.105815 -2.7114632,12.924277 -0.065283,1.097785 -0.5261107,12.819575 -1.1063921,28.399297 -5.775688,2.441639 -10.029312,4.429707 -10.387997,5.046721 -1.46904,3.055591 -2.644687,19.3473226 -1.175639,20.78426148 0.447972,0.43817645 4.83961,-0.95607978 10.739914,-3.13572518 -0.229579,6.4571535 -0.454597,12.8859172 -0.679029,19.5192197 -5.758096,2.489822 -10.099011,4.456798 -10.647929,4.825029 -2.056691,3.00932 -1.469289,17.061495 -0.294039,19.268075 0.359402,0.674782 4.546581,-0.231717 10.216948,-1.867586 -0.692843,22.416281 -1.122391,40.553476 -0.769463,42.275456 0.96321,4.69964 1.313486,7.930472 3.6581763,7.636742 2.3446898,-0.293719 2.1349044,-12.294668 2.0624059,-16.448608 -0.03842,-2.200913 0.4482676,-16.948192 1.0846884,-35.29707 3.4523839,-1.093878 7.1099071,-2.319047 10.6164062,-3.543969 -0.8234125,15.916608 -1.6063939,32.66324 -1.4143858,34.435107 0.3501205,3.230999 1.3488617,9.98647 3.4049626,9.98647 2.0560876,0 3.6492523,-9.692764 3.5672236,-14.392404 -0.03841,-2.201344 0.2911792,-16.89191 0.7296708,-32.286916 6.252239,-2.31218 11.02556,-4.302929 11.503173,-4.952669 1.46907,-1.998501 1.175022,-20.7844839 -0.29404,-22.221383 -0.456554,-0.4465611 -4.71769,0.953045 -10.424686,3.1279729 0.284266,-7.36657404 0.561086,-12.9604345 0.780314,-14.1614073 0.114644,-0.6280203 0.279017,-2.5948746 0.470258,-5.3443766 6.552049,-2.785589 11.527594,-5.049362 11.817881,-5.461683 0.88142,-1.251979 2.644471,-20.140771 0.8816,-20.808032 -0.557398,-0.210978 -5.231657,1.317385 -11.394652,3.567224 1.032206,-19.855823 2.078387,-43.17915 2.042253,-45.249435 -0.0615,-3.524729 -2.260859,-11.749151 -3.72949,-11.749151 z m -5.8812932,82.323137 c -0.1859571,7.3186582 -0.3483213,12.813194 -0.4635394,14.4709515 -0.05983,0.8608695 -0.1605809,2.5023471 -0.287319,4.6710335 -3.629906,1.454428 -7.4665336,3.044984 -11.1192176,4.587317 0.2303304,-6.5164549 0.4511199,-12.80904822 0.6774762,-19.2344861 3.6463869,-1.4199844 7.5025963,-2.9733319 11.1925998,-4.4948159 z",
    fill=color_foreground,
    stroke="none",
    attrs=[("transform", @luna_dom.Attr::AttrString(transform_str))],
  )
}

///|
/// Render a flat accidental symbol
fn render_flat(x : Double, y : Double) -> @luna_dom.DomNode {
  let scale = staff_line_spacing / 90.0
  let transform_str = "scale(" +
    scale.to_string() +
    ") translate(" +
    (x / scale).to_string() +
    " " +
    (y / scale).to_string() +
    ")"
  @luna_dom.svg_path(
    d="m -15.438068,-176.64949 c -1.250095,-0.0254 -3.528975,0.24675 -6.794415,1.87947 -5.224703,2.61235 -6.705018,5.57279 -6.705018,5.57279 0,3.65729 1.044898,273.7745 1.044898,273.7745 0,0 7.148557,-7.450219 13.584182,-15.151525 15.7200571,-18.811737 44.122948,-63.681766 50.157146,-78.892865 7.04342,-17.7551713 13.828972,-49.542146 9.404594,-63.219398 -3.26589,-10.095957 -8.844077,-14.834105 -15.206824,-17.129186 -5.752571,-2.074979 -20.3208675,1.977867 -29.20286911,9.292455 -8.88199879,7.314592 -14.10663089,17.241327 -14.10663089,17.241327 l -1.045416,-133.230108 c 0,0 -0.379587,-0.12221 -1.129647,-0.13746 z m 26.567371,148.427114 c 2.053656,0.04732 4.082105,0.876099 5.910752,2.704743 4.179757,4.17976 3.912901,13.061407 2.612241,20.898466 -1.28311,7.7313101 -9.7799703,25.847722 -18.2862212,36.050513 -8.3132664,9.971318 -14.1066308,15.673978 -14.1066308,15.673978 l 0.914154,-51.4206329 c 0,0 1.175509,-3.9608204 4.3103324,-8.1405891 3.1348203,-4.17976 6.79217949,-8.881996 10.97194,-12.539286 2.3511139,-2.057226 5.0330178,-3.288038 7.6734326,-3.227192 z",
    fill=color_foreground,
    stroke="none",
    attrs=[("transform", @luna_dom.Attr::AttrString(transform_str))],
  )
}

///|
/// Render a natural accidental symbol
fn render_natural(x : Double, y : Double) -> @luna_dom.DomNode {
  let scale = staff_line_spacing / 45.0
  let transform_str = "scale(" +
    scale.to_string() +
    ") translate(" +
    (x / scale).to_string() +
    " " +
    (y / scale).to_string() +
    ")"
  @luna_dom.svg_path(
    d="m 9.656708,-34.358224 c -3.5747253,1.401619 -13.4508224,3.469626 -17.0015704,4.90761 0.5525928,-16.197194 0.9406466,-33.441544 0.8397398,-34.070978 -0.3296179,-2.05609 -1.9318763,-4.738023 -3.1067851,-4.738023 -2.0458293,0.58746 -2.2484193,2.498559 -2.4754903,6.317021 -0.855749,24.500192 -1.185409,30.786081 -2.166087,57.7018099 -0.229579,6.4571535 -0.454597,12.8859172 -0.679029,19.5192201 -1.305033,23.756551 -1.10549,22.559419 5.3107876,20.392038 3.4523839,-1.093878 13.0083498,-2.988388 16.6822104,-4.150549 -0.7863859,20.34178 -1.3163862,36.459078 -1.1784127,38.210682 0.2515884,3.194049 1.1128887,6.210895 3.1689897,6.210895 2.056087,0 2.962,-2.222355 3.095276,-6.841255 1.394492,-38.448523 2.494889,-57.372836 2.766379,-78.0455522 0.47485,-30.7554458 1.06906,-27.9275238 -5.256008,-25.4129188 z m -0.537435,20.182496 c -0.124201,7.3418156 -0.284176,15.345355 -0.46354,16.9790577 -0.09314,0.8483779 -0.3271086,5.3311879 -0.5659976,7.4578193 -3.7765155,1.399449 -13.5323372,2.815529 -17.1850212,4.357862 0.2303304,-6.5164552 0.7297985,-17.5465845 0.9561548,-23.9720224 3.6463869,-1.4199846 13.5119216,-3.3224126 17.258404,-4.8227166 z",
    fill=color_foreground,
    stroke="none",
    attrs=[("transform", @luna_dom.Attr::AttrString(transform_str))],
  )
}

///|
/// Render an accidental symbol at the given position
fn render_accidental(
  accidental : @music.Accidental,
  x : Double,
  y : Double,
) -> @luna_dom.DomNode {
  match accidental {
    Sharp => render_sharp(x, y)
    Flat => render_flat(x, y)
    Natural => render_natural(x, y)
  }
}

///|
/// Render a single note with all its elements
pub fn render_note(
  note : @music.MeasureNote,
  note_x : Double,
  staff_y : Double,
) -> Array[@luna_dom.DomNode] {
  let children : Array[@luna_dom.DomNode] = []
  match note.midi {
    Some(midi) => {
      // Render note
      let note_y = @music.midi_to_staff_y(midi, staff_y)

      // Accidental (rendered to the left of the note)
      match note.accidental {
        Some(accidental) => {
          let accidental_x = note_x - staff_line_spacing * 1.2
          children.push(render_accidental(accidental, accidental_x, note_y))
        }
        None => ()
      }

      // Ledger lines (for notes outside the staff)
      let ledger_lines = render_ledger_lines(midi, note_x, staff_y)
      for line in ledger_lines {
        children.push(line)
      }

      // Note head
      children.push(
        match note.duration {
          Eighth | DottedEighth | Quarter | DottedQuarter => {
            // Filled note head - rotated ellipse for more realistic appearance
            let rx = staff_line_spacing * 0.37894733 * 1.9
            let ry = staff_line_spacing * 0.2542448 * 1.9
            @luna_dom.svg_ellipse(
              cx=note_x.to_string(),
              cy=note_y.to_string(),
              rx=rx.to_string(),
              ry=ry.to_string(),
              fill=color_foreground,
              stroke="none",
              attrs=[
                (
                  "transform",
                  @luna_dom.Attr::AttrString(
                    "rotate(-25, " +
                    note_x.to_string() +
                    ", " +
                    note_y.to_string() +
                    ")",
                  ),
                ),
              ],
            )
          }
          Half | DottedHalf => {
            // Hollow note head - hollow ellipse path for more realistic appearance
            let scale = staff_line_spacing / 50.0
            let transform_str = "scale(" +
              scale.to_string() +
              ") translate(" +
              (note_x / scale).to_string() +
              " " +
              (note_y / scale).to_string() +
              ")"
            @luna_dom.svg_path(
              d="m 11.9799,-28.044092 a 25.42448,37.894733 65 0 0 -22.724708,5.001244 25.42448,37.894733 65 0 0 -23.599593,39.057558 25.42448,37.894733 65 0 0 45.089241,7.02748 25.42448,37.894733 65 0 0 23.59959,-39.05756 25.42448,37.894733 65 0 0 -22.36453,-12.028722 z m -11.9801455354,5.461682 a 16.280342,22.582411 0 0 1 16.2806555354,22.58208337714 16.280342,22.582411 0 0 1 -16.2806555354,22.58259662286 16.280342,22.582411 0 0 1 -16.2801434646,-22.58259662286 16.280342,22.582411 0 0 1 16.2801434646,-22.58208337714 z",
              fill=color_foreground,
              stroke="none",
              attrs=[("transform", @luna_dom.Attr::AttrString(transform_str))],
            )
          }
        },
      )

      // Stem and flag
      let stem_height = staff_line_spacing * 3.0 // 3 staff spaces
      let stem_up = midi < 71
      match note.duration {
        Eighth | DottedEighth | Quarter | DottedQuarter | Half | DottedHalf => {
          // Calculate stem attachment point on rotated ellipse
          // Ellipse is rotated -25 degrees
          let rx = staff_line_spacing * 0.37894733 * 1.9
          let cos_25 = 0.906308
          let sin_25 = 0.422618
          let (stem_x_offset, stem_y_offset) = if stem_up {
            // Attach to right side of ellipse (0 degrees before rotation)
            (rx * cos_25, -(rx * sin_25))
          } else {
            // Attach to left side of ellipse (180 degrees before rotation)
            (-(rx * cos_25), rx * sin_25)
          }
          let stem_x = note_x + stem_x_offset
          let y1 = note_y + stem_y_offset
          let y2 = if stem_up { y1 - stem_height } else { y1 + stem_height }
          children.push(
            @luna_dom.svg_line(
              x1=stem_x.to_string(),
              y1=y1.to_string(),
              x2=stem_x.to_string(),
              y2=y2.to_string(),
              stroke=color_foreground,
              stroke_width="1.5",
            ),
          )

          // Flag for eighth notes
          match note.duration {
            Eighth | DottedEighth => {
              let scale = staff_line_spacing / 32.0
              let flag_transform = if stem_up {
                "scale(" +
                scale.to_string() +
                ") translate(" +
                (stem_x / scale).to_string() +
                " " +
                (y2 / scale).to_string() +
                ")"
              } else {
                "scale(" +
                scale.to_string() +
                " " +
                (-scale).to_string() +
                ") translate(" +
                (stem_x / scale).to_string() +
                " " +
                (-y2 / scale).to_string() +
                ")"
              }
              children.push(
                @luna_dom.svg_path(
                  d="m 0.1322915,0.20079656 v 29.17519544 c 0,0 0.94525,1.04738 2.86031,2.860314 2.96256,2.804577 11.7267205,11.463111 16.3037905,16.875851 4.32124,5.11019 8.60276,12.11629 9.13525,19.19871 0.53655,7.13637 -1.14271,16.58785 -4.70907,26.52439 -1.9313,5.380953 -3.62376,8.222963 -3.06452,8.587383 0.79714,0.51945 2.7385,-2.97941 6.4668,-10.625733 6.32003,-12.96167 7.43952,-25.40692 6.55264,-34.62269 -1.15046,-11.95469 -2.28519,-23.402003 -9.94627,-35.007151 -6.79549,-10.293932 -14.7193405,-17.7092604 -19.5333005,-20.7143534 -2.59687,-1.62108305 -4.06563,-2.25191604 -4.06563,-2.25191604 z",
                  fill=color_foreground,
                  stroke="none",
                  attrs=[
                    ("transform", @luna_dom.Attr::AttrString(flag_transform)),
                  ],
                ),
              )
            }
            _ => ()
          }
        }
      }

      // Dot for dotted notes
      match note.duration {
        DottedEighth | DottedQuarter | DottedHalf => {
          let dot_radius = staff_line_spacing * 0.15
          let dot_x = note_x + staff_line_spacing * 1.5
          let dot_y = note_y
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
    }
    None => ()
  }
  children
}
