// Explicit re-exports of trait implementations as regular methods,
// so dot syntax keeps working without relying on the deprecated
// implicit promotion (warning 79: implicit_impl_as_method).

///|
pub extend DurationWeights with Eq::{equal, not_equal}

///|
pub extend DurationWeights with Debug::{to_repr}

///|
pub extend DurationWeights with Show::{output, to_string}

///|
pub extend ChordSegment with Eq::{equal, not_equal}

///|
pub extend ChordSegment with Debug::{to_repr}

///|
pub extend ChordSegment with Show::{output, to_string}

///|
pub extend ImprovisationConfig with Eq::{equal, not_equal}

///|
pub extend ImprovisationConfig with Debug::{to_repr}

///|
pub extend ImprovisationConfig with Show::{output, to_string}
