///|
/// Section header inside the settings panel.
fn settings_section(
  title : String,
  children : Array[@luna_dom.DomNode],
  aria_label? : String,
) -> @luna_dom.DomNode {
  let attrs : Array[(String, @luna_dom.Attr)] = match aria_label {
    Some(l) => [("aria-label", @luna_dom.Attr::AttrString(l))]
    None => []
  }
  @luna_dom.div(class="flex flex-col gap-1.5", attrs~, [
    @luna_dom.div(
      class="text-xs font-semibold text-slate-400 uppercase tracking-wide",
      [@luna_dom.text(title)],
    ),
    @luna_dom.div(class="flex flex-col gap-2", children),
  ])
}
