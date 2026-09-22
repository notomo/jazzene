// Explicit re-exports of trait implementations as regular methods,
// so dot syntax keeps working without relying on the deprecated
// implicit promotion (warning 79: implicit_impl_as_method).

///|
pub extend EditingChord with Eq::{equal, not_equal}

///|
pub extend EditingChord with Debug::{to_repr}

///|
pub extend EditingChord with Show::{output, to_string}

///|
pub extend ViewState with Eq::{equal, not_equal}
