// Explicit re-exports of trait implementations as regular methods,
// so dot syntax keeps working without relying on the deprecated
// implicit promotion (warning 79: implicit_impl_as_method).

///|
pub extend SheetBeamStem with Debug::{to_repr}

///|
pub extend SheetBeamStem with Show::{output, to_string}

///|
pub extend SheetBeamRest with Debug::{to_repr}

///|
pub extend SheetBeamRest with Show::{output, to_string}

///|
pub extend SheetBeamGroup with Debug::{to_repr}

///|
pub extend SheetBeamGroup with Show::{output, to_string}

///|
pub extend SheetMeasure with Debug::{to_repr}

///|
pub extend SheetMeasure with Show::{output, to_string}

///|
pub extend SheetNote with Debug::{to_repr}

///|
pub extend SheetNote with Show::{output, to_string}

///|
pub extend OttavaMarking with Eq::{equal, not_equal}

///|
pub extend OttavaMarking with Debug::{to_repr}

///|
pub extend OttavaMarking with Show::{output, to_string}

///|
pub extend OttavaSpanRole with Eq::{equal, not_equal}

///|
pub extend OttavaSpanRole with Debug::{to_repr}

///|
pub extend OttavaSpanRole with Show::{output, to_string}

///|
pub extend OttavaSpan with Eq::{equal, not_equal}

///|
pub extend OttavaSpan with Debug::{to_repr}

///|
pub extend OttavaSpan with Show::{output, to_string}

///|
pub extend SheetTieArc with Debug::{to_repr}

///|
pub extend SheetTieArc with Show::{output, to_string}
