///|
/// Render time signature selection dropdown
fn time_signature_select(
  time_signature : @signal.Signal[@music.TimeSignature],
) -> @luna_dom.DomNode {
  select_input(
    label="Time:",
    aria_label="time signature",
    options=@music.TimeSignature::all().map(@music.TimeSignature::to_string),
    initial=time_signature.get().to_string(),
    value=fn() { time_signature.get().to_string() },
    on_change=fn(value) {
      @music.TimeSignature::from_string(value)
      |> Result::map(fn(ts) {
        time_signature.set(ts)
        let default_ts = @music.TimeSignature::default().to_string()
        set_query_param("time", ts.to_string(), default=default_ts)
      })
      |> ignore
    },
  )
}
