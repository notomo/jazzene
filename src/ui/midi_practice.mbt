///|
/// Practice score display: current and best score as score/max.

///|
pub fn midi_practice(
  practice_score : @signals.Signal[Double],
  practice_best_score : @signals.Signal[Double],
  practice_max_score : () -> Int,
) -> @luna_dom.DomNode {
  @luna_dom.div(class="flex gap-2", [
    @luna_dom.div(
      class="flex-1 flex flex-col items-center gap-0.5 bg-slate-700 rounded px-2 py-1",
      [
        @luna_dom.span(class="text-xs text-slate-200", [
          @luna_dom.text("Current"),
        ]),
        @luna_dom.span(
          class="text-base font-mono text-white",
          attrs=[
            ("aria-label", @luna_dom.Attr::AttrString("practice current score")),
          ],
          [
            @luna_dom.text_dyn(fn() {
              format_practice_score(practice_score.get(), practice_max_score())
            }),
          ],
        ),
      ],
    ),
    @luna_dom.div(
      class="flex-1 flex flex-col items-center gap-0.5 bg-slate-700 rounded px-2 py-1",
      [
        @luna_dom.span(class="text-xs text-slate-200", [@luna_dom.text("Best")]),
        @luna_dom.span(
          class="text-base font-mono text-white",
          attrs=[
            ("aria-label", @luna_dom.Attr::AttrString("practice best score")),
          ],
          [
            @luna_dom.text_dyn(fn() {
              format_practice_score(
                practice_best_score.get(),
                practice_max_score(),
              )
            }),
          ],
        ),
      ],
    ),
  ])
}

///|
fn format_practice_score(score : Double, max : Int) -> String {
  let whole = score.to_int()
  let frac = ((score - whole.to_double()) * 10.0).to_int()
  whole.to_string() + "." + frac.to_string() + " / " + max.to_string()
}
