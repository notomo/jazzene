///|
fn mouse_event_target_rect_left(e : @js_dom.MouseEvent) -> Double {
  e
  .as_any()
  ._get("currentTarget")
  ._call("getBoundingClientRect", [])
  ._get("left")
  .cast()
}

///|
fn mouse_event_target_rect_width(e : @js_dom.MouseEvent) -> Double {
  e
  .as_any()
  ._get("currentTarget")
  ._call("getBoundingClientRect", [])
  ._get("width")
  .cast()
}

///|
fn touch_event_target_rect_left(e : @js_dom.TouchEvent) -> Double {
  e
  .as_any()
  ._get("currentTarget")
  ._call("getBoundingClientRect", [])
  ._get("left")
  .cast()
}

///|
fn touch_event_target_rect_width(e : @js_dom.TouchEvent) -> Double {
  e
  .as_any()
  ._get("currentTarget")
  ._call("getBoundingClientRect", [])
  ._get("width")
  .cast()
}

///|
/// Register document-level drag listeners for horizontal (X-axis) drag.
fn add_document_drag_listeners(
  on_move : (Double) -> Unit,
  on_up : () -> Unit,
) -> Unit {
  let doc = @js_dom.document().as_event_target()
  let move_ref : Ref[(@js.Any) -> Unit] = { val: fn(_) { () } }
  let up_ref : Ref[(@js.Any) -> Unit] = { val: fn(_) { () } }
  move_ref.val = fn(e) { on_move(e._get("clientX").cast()) }
  up_ref.val = fn(_e) {
    on_up()
    doc.removeEventListener("mousemove", move_ref.val)
    doc.removeEventListener("mouseup", up_ref.val)
  }
  doc.addEventListener("mousemove", move_ref.val)
  doc.addEventListener("mouseup", up_ref.val)
  let touch_move_ref : Ref[(@js.Any) -> Unit] = { val: fn(_) { () } }
  let touch_end_ref : Ref[(@js.Any) -> Unit] = { val: fn(_) { () } }
  touch_move_ref.val = fn(e) {
    let touches = e._get("touches")
    if (touches._get("length").cast() : Int) > 0 {
      e._call("preventDefault", []) |> ignore
      on_move(touches._get_by_index(0)._get("clientX").cast())
    }
  }
  touch_end_ref.val = fn(_e) {
    on_up()
    doc.removeEventListener("touchmove", touch_move_ref.val)
    doc.removeEventListener("touchend", touch_end_ref.val)
    doc.removeEventListener("touchcancel", touch_end_ref.val)
  }
  doc.addEventListener("touchmove", touch_move_ref.val)
  doc.addEventListener("touchend", touch_end_ref.val)
  doc.addEventListener("touchcancel", touch_end_ref.val)
}

///|
let pitch_slider_min = 21 // A0

///|
let pitch_slider_max = 108 // C8

///|
let pitch_slider_range = 87 // 108 - 21

///|
fn midi_to_note_label(midi : Int) -> String {
  let name = @music.ChordRoot::from_pitch_class(midi % 12).to_string()
  let octave = (midi / 12 - 1).to_string()
  name + octave
}

///|
fn midi_to_pct(midi : Int) -> Double {
  (midi - pitch_slider_min).to_double() / pitch_slider_range.to_double() * 100.0
}

///|
fn pct_to_midi(pct : Double) -> Int {
  pitch_slider_min +
  (pct / 100.0 * pitch_slider_range.to_double() + 0.5).to_int()
}

///|
/// Dual-handle horizontal slider for setting pitch_min and pitch_max.
pub fn pitch_range_slider(
  jazz_style : @signals.Signal[@music.JazzStyle],
) -> @luna_dom.DomNode {
  let track_left : Ref[Double] = Ref::new(0.0)
  let track_width : Ref[Double] = Ref::new(1.0)
  let dragging_min : Ref[Bool] = Ref::new(false)

  fn start_drag(left : Double, width : Double, client_x : Double) -> Unit {
    track_left.val = left
    track_width.val = width
    let style = jazz_style.get()
    let clicked_pct = (client_x - left) / width * 100.0
    let min_pct = midi_to_pct(style.pitch_min)
    let max_pct = midi_to_pct(style.pitch_max)
    let dist_min = (clicked_pct - min_pct).abs()
    let dist_max = (clicked_pct - max_pct).abs()
    dragging_min.val = dist_min <= dist_max
    let new_midi = pct_to_midi(clicked_pct)
    if dragging_min.val {
      let clamped = @cmp.minimum(
        @cmp.maximum(new_midi, pitch_slider_min),
        style.pitch_max - 1,
      )
      jazz_style.update(fn(s) { @music.JazzStyle::{ ..s, pitch_min: clamped } })
    } else {
      let clamped = @cmp.minimum(
        @cmp.maximum(new_midi, style.pitch_min + 1),
        pitch_slider_max,
      )
      jazz_style.update(fn(s) { @music.JazzStyle::{ ..s, pitch_max: clamped } })
    }
    add_document_drag_listeners(
      fn(cx) {
        let pct = (cx - track_left.val) / track_width.val * 100.0
        let midi = pct_to_midi(pct)
        let cur = jazz_style.get()
        if dragging_min.val {
          let clamped = @cmp.minimum(
            @cmp.maximum(midi, pitch_slider_min),
            cur.pitch_max - 1,
          )
          jazz_style.update(fn(s) {
            @music.JazzStyle::{ ..s, pitch_min: clamped }
          })
        } else {
          let clamped = @cmp.minimum(
            @cmp.maximum(midi, cur.pitch_min + 1),
            pitch_slider_max,
          )
          jazz_style.update(fn(s) {
            @music.JazzStyle::{ ..s, pitch_max: clamped }
          })
        }
      },
      fn() {  },
    )
  }

  @luna_dom.div(class="flex flex-col gap-1") <| [
    @luna_dom.div(
      class="relative w-full h-5 flex items-center select-none cursor-pointer",
      on=@luna_dom.events()
        .mousedown(fn(e) {
          start_drag(
            mouse_event_target_rect_left(e),
            mouse_event_target_rect_width(e),
            e.clientX,
          )
        })
        .touchstart(fn(e) {
          if e.touches.length() > 0 {
            start_drag(
              touch_event_target_rect_left(e),
              touch_event_target_rect_width(e),
              e.touches[0].clientX,
            )
          }
        }),
    ) <| [
      // Track background
      @luna_dom.div(class="absolute w-full h-1 rounded-full bg-slate-600") <| [],
      // Filled range between handles
      @luna_dom.div(
        class="absolute h-1 rounded-full bg-blue-500",
        dyn_attrs=[
          (
            "style",
            @luna_dom.AttrValue::Dynamic(fn() {
              let s = jazz_style.get()
              let min_pct = midi_to_pct(s.pitch_min)
              let max_pct = midi_to_pct(s.pitch_max)
              "left: " +
              min_pct.to_string() +
              "%; width: " +
              (max_pct - min_pct).to_string() +
              "%"
            }),
          ),
        ],
      ) <| [],
      // Min handle
      @luna_dom.div(
        class="absolute w-3 h-3 rounded-full bg-white border border-slate-400 shadow",
        dyn_attrs=[
          (
            "style",
            @luna_dom.AttrValue::Dynamic(fn() {
              let pct = midi_to_pct(jazz_style.get().pitch_min)
              "left: " + pct.to_string() + "%; transform: translateX(-50%)"
            }),
          ),
        ],
      ) <| [],
      // Max handle
      @luna_dom.div(
        class="absolute w-3 h-3 rounded-full bg-white border border-slate-400 shadow",
        dyn_attrs=[
          (
            "style",
            @luna_dom.AttrValue::Dynamic(fn() {
              let pct = midi_to_pct(jazz_style.get().pitch_max)
              "left: " + pct.to_string() + "%; transform: translateX(-50%)"
            }),
          ),
        ],
      ) <| [],
    ],
    // Range label
    @luna_dom.div(class="text-center text-sm text-slate-200") <| [
      @luna_dom.text_dyn(fn() {
        let s = jazz_style.get()
        midi_to_note_label(s.pitch_min) +
        " ~ " +
        midi_to_note_label(s.pitch_max)
      }),
    ],
  ]
}
