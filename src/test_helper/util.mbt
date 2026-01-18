///|
/// Unwraps a Result, returning the Ok value or failing the test with the error message.
pub fn[T] unwrap_or_fail(result : Result[T, String]) -> T raise Failure {
  match result {
    Ok(value) => value
    Err(e) => fail(e)
  }
}
