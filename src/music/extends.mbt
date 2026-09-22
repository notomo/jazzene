// Explicit re-exports of trait implementations as regular methods,
// so dot syntax keeps working without relying on the deprecated
// implicit promotion (warning 79: implicit_impl_as_method).

///|
pub extend Accidental with Eq::{equal, not_equal}

///|
pub extend Accidental with Debug::{to_repr}

///|
pub extend Accidental with Show::{output, to_string}

///|
pub extend AudioSound with Eq::{equal, not_equal}

///|
pub extend AudioSound with Debug::{to_repr}

///|
pub extend AudioSound with Show::{output, to_string}

///|
pub extend BassStyle with Eq::{equal, not_equal}

///|
pub extend BassStyle with Debug::{to_repr}

///|
pub extend BassStyle with Show::{output, to_string}

///|
pub extend Chord with Eq::{equal, not_equal}

///|
pub extend Chord with Debug::{to_repr}

///|
pub extend Chord with Show::{output, to_string}

///|
pub extend ChordQuality with Eq::{equal, not_equal}

///|
pub extend ChordQuality with Debug::{to_repr}

///|
pub extend ChordQuality with Show::{output}

///|
pub extend ChordRoot with Eq::{equal, not_equal}

///|
pub extend ChordRoot with Debug::{to_repr}

///|
pub extend ChordRoot with Show::{output}

///|
pub extend ChordScale with Eq::{equal, not_equal}

///|
pub extend ChordScale with Debug::{to_repr}

///|
pub extend ChordScale with Show::{output, to_string}

///|
pub extend CompingStyle with Eq::{equal, not_equal}

///|
pub extend CompingStyle with Debug::{to_repr}

///|
pub extend CompingStyle with Show::{output, to_string}

///|
pub extend CompingPattern with Eq::{equal, not_equal}

///|
pub extend CompingPattern with Debug::{to_repr}

///|
pub extend CompingPattern with Show::{output, to_string}

///|
pub extend ScaleDegree with Eq::{equal, not_equal}

///|
pub extend ScaleDegree with Debug::{to_repr}

///|
pub extend ScaleDegree with Show::{output, to_string}

///|
pub extend DegreeBass with Eq::{equal, not_equal}

///|
pub extend DegreeBass with Debug::{to_repr}

///|
pub extend DegreeBass with Show::{output, to_string}

///|
pub extend DegreeChord with Eq::{equal, not_equal}

///|
pub extend DegreeChord with Debug::{to_repr}

///|
pub extend DegreeChord with Show::{output}

///|
pub extend DegreeMeasure with Eq::{equal, not_equal}

///|
pub extend DegreeMeasure with Debug::{to_repr}

///|
pub extend DegreeMeasure with Show::{output}

///|
pub extend DrumVoice with Eq::{equal, not_equal}

///|
pub extend DrumVoice with Debug::{to_repr}

///|
pub extend DrumVoice with Show::{output, to_string}

///|
pub extend DrumPatternStyle with Eq::{equal, not_equal}

///|
pub extend DrumPatternStyle with Debug::{to_repr}

///|
pub extend DrumPatternStyle with Show::{output, to_string}

///|
pub extend Duration with Eq::{equal, not_equal}

///|
pub extend Duration with Debug::{to_repr}

///|
pub extend Duration with Show::{output, to_string}

///|
pub extend Duration with Compare::{compare, op_ge, op_gt, op_le, op_lt}

///|
pub extend Duration with Add::{add}

///|
pub extend Duration with Sub::{sub}

///|
pub extend MelodyMode with Eq::{equal, not_equal}

///|
pub extend MelodyMode with Debug::{to_repr}

///|
pub extend MelodyMode with Show::{output, to_string}

///|
pub extend CompingMode with Eq::{equal, not_equal}

///|
pub extend CompingMode with Debug::{to_repr}

///|
pub extend CompingMode with Show::{output, to_string}

///|
pub extend JazzStyle with Eq::{equal, not_equal}

///|
pub extend JazzStyle with Debug::{to_repr}

///|
pub extend JazzStyle with Show::{output, to_string}

///|
pub extend MidiNumber with Eq::{equal, not_equal}

///|
pub extend MidiNumber with Debug::{to_repr}

///|
pub extend MidiNumber with Show::{output, to_string}

///|
pub extend NoteDuration with Eq::{equal, not_equal}

///|
pub extend NoteDuration with Debug::{to_repr}

///|
pub extend NoteDuration with Show::{output, to_string}

///|
pub extend ScheduledSound with Eq::{equal, not_equal}

///|
pub extend ScheduledSound with Debug::{to_repr}

///|
pub extend ScheduledSound with Show::{output, to_string}

///|
pub extend SoundEvent with Eq::{equal, not_equal}

///|
pub extend SoundEvent with Debug::{to_repr}

///|
pub extend SoundEvent with Show::{output, to_string}

///|
pub extend SwingConfig with Eq::{equal, not_equal}

///|
pub extend SwingConfig with Debug::{to_repr}

///|
pub extend Techniques with Eq::{equal, not_equal}

///|
pub extend Techniques with Debug::{to_repr}

///|
pub extend Techniques with Show::{output, to_string}

///|
pub extend Tie with Eq::{equal, not_equal}

///|
pub extend Tie with Debug::{to_repr}

///|
pub extend Tie with Show::{output, to_string}

///|
pub extend ToneOrigin with Eq::{equal, not_equal}

///|
pub extend ToneOrigin with Debug::{to_repr}

///|
pub extend ToneOrigin with Show::{output, to_string}
