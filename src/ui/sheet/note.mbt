///|
/// Note rendering (heads, stems, flags, dots, ledger lines)

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
        Eighth | DottedEighth | Quarter | DottedQuarter => {
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
        Half | DottedHalf => ()
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
