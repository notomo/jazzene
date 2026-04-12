///|
/// Segmented button control: renders a row of option buttons where one is active.
/// is_disabled: called inside reactive context (dyn_class/on), so signal access is tracked.
pub fn[T : Eq] segmented_buttons(
  options : Array[(String, T)],
  current : () -> T,
  on_select : (T) -> Unit,
  is_disabled? : (T) -> Bool = fn(_) { false },
) -> @luna_dom.DomNode {
  let base = "px-2 py-0.5 text-xs border-y border-r first:border-l first:rounded-l last:rounded-r transition-colors"
  let active = "bg-blue-800 border-blue-500 text-white"
  let inactive = "bg-slate-900 border-slate-600 text-slate-300 hover:bg-slate-700"
  let disabled_style = "cursor-not-allowed bg-slate-950 border-slate-800 text-slate-600"
  @luna_dom.div(
    class="flex w-full",
    options.map(fn(pair) {
      let (label, value) = pair
      @luna_dom.button(
        dyn_class=fn() {
          cn([
            base,
            "flex-1 min-w-0 text-center",
            if is_disabled(value) {
              disabled_style
            } else if current() == value {
              active
            } else {
              inactive
            },
          ])
        },
        on=@luna_dom.events().click(fn(_) {
          if !is_disabled(value) {
            on_select(value)
          }
        }),
        dyn_attrs=[
          (
            "aria-pressed",
            @luna_dom.AttrValue::Dynamic(fn() {
              (current() == value).to_string()
            }),
          ),
        ],
      ) <| [
        @luna_dom.text(label),
      ]
    }),
  )
}

///|
/// Toggle switch for a boolean setting.
pub fn toggle_switch(
  label~ : String,
  value~ : () -> Bool,
  on_toggle~ : () -> Unit,
) -> @luna_dom.DomNode {
  @luna_dom.label(class="flex items-center gap-1.5 cursor-pointer") <| [
    @luna_dom.div(
      dyn_class=fn() {
        cn([
          "relative w-7 h-4 rounded-full transition-colors shrink-0",
          if value() {
            "bg-blue-600"
          } else {
            "bg-slate-600"
          },
        ])
      },
    ) <| [
      @luna_dom.div(
        dyn_class=fn() {
          cn([
            "absolute top-0.5 w-3 h-3 rounded-full bg-white transition-transform",
            if value() {
              "translate-x-3.5"
            } else {
              "translate-x-0.5"
            },
          ])
        },
      ) <| [],
      @luna_dom.create_element(
        "input",
        [
          ("type", @luna_dom.AttrValue::Static("checkbox")),
          ("class", @luna_dom.AttrValue::Static("sr-only")),
          (
            "checked",
            @luna_dom.AttrValue::Dynamic(fn() { value().to_string() }),
          ),
          ("change", @luna_dom.AttrValue::Handler(fn(_) { on_toggle() })),
        ],
        [],
      ),
    ],
    @luna_dom.span(class="text-xs text-slate-300") <| [
      @luna_dom.text(label),
    ],
  ]
}
