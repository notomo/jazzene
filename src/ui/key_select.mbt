///|
/// Render key selection dropdown
fn key_select(key : @signals.Signal[@music.KeySignature]) -> @luna_dom.DomNode {
  select_input(
    label="Key:",
    aria_label="key",
    options=@music.KeySignature::all_roots().map(@music.ChordRoot::to_string),
    initial=key.get().root.to_string(),
    value=fn() { key.get().root.to_string() },
    on_change=fn(value) {
      @music.ChordRoot::from_string(value)
      |> Result::map(fn(root) { key.set(@music.KeySignature::from_root(root)) })
      |> ignore
    },
  )
}
