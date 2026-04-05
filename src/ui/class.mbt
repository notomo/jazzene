///|
/// Join CSS class name strings, filtering out empty strings.
///
/// ```
/// cn(["base-class", if condition { "active" } else { "" }])
/// ```
fn cn(classes : Array[String]) -> String {
  classes.iter().filter(fn(s) { !s.is_empty() }).join(" ")
}
