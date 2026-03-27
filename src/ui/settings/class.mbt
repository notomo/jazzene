///|
/// cn(["base-class", if condition { "active" } else { "" }])
fn cn(classes : Array[String]) -> String {
  classes.filter(fn(c) { c != "" }).join(" ")
}
