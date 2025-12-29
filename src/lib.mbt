///|
fn main {
  let count = @signal.signal(0)
  let doubled = @signal.memo(fn() { count.get() * 2 })
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let app = @dom.div(
        [
          @dom.h1([@dom.text("Luna test (MoonBit)")]),
          @dom.p([@dom.text_dyn(fn() { "Count: " + count.get().to_string() })]),
          @dom.p([@dom.text_dyn(fn() { "Doubled: " + doubled().to_string() })]),
          @dom.div([
            @dom.button(
              on=@dom.events().click(_ => count.update(fn(n) { n + 1 })),
              [@dom.text("+1")],
              class="px-2 border",
            ),
            @dom.button(
              on=@dom.events().click(_ => count.update(fn(n) { n - 1 })),
              [@dom.text("-1")],
              class="px-2 border",
            ),
            @dom.button(
              on=@dom.events().click(_ => count.set(0)),
              [@dom.text("Reset")],
              class="px-2 border",
            ),
          ]),
        ],
        class="text-3xl flex flex-col gap-3",
      )
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}
