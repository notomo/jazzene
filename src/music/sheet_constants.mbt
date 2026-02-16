///|
/// Layout constants for sheet music rendering
/// These are used by both the layout computation (music package)
/// and the rendering layer (ui/sheet package).

// --- Measure layout ---

///|
pub const STAFF_TOP : Double = 120.0

///|
pub const MEASURES_PER_ROW : Int = 4

///|
pub const MEASURE_WIDTH : Double = 320.0

///|
pub const CLEF_SPACE_WIDTH : Double = 50.0

///|
pub const MEASURE_START_X : Double = 40.0

///|
pub const ROW_HEIGHT : Double = 300.0

///|
pub const NOTE_AREA_START_OFFSET : Double = 40.0

///|
pub const NOTE_AREA_PADDING : Double = 75.0

///|
pub const MIN_NOTE_SPACING : Double = 32.0

///|
pub const FLAGGED_EIGHTH_EXTRA_SPACING : Double = 15.0

///|
pub const ACCIDENTAL_EXTRA_SPACING : Double = 14.0

// --- Staff ---

///|
pub const STAFF_LINE_SPACING : Double = 15.0

///|
pub const STAFF_LINES : Int = 5

///|
pub const FIRST_LEDGER_LINE_BELOW_STEP : Int = -2

///|
pub const UPPER_LEDGER_LINE_THRESHOLD : Int = 8

///|
pub const FIRST_LEDGER_LINE_ABOVE_STEP : Int = 10

// --- Note ---

///|
pub const STEM_HEIGHT_SPACES : Double = 3.0

///|
pub const NOTE_HEAD_RX_RATIO : Double = 0.37894733 * 1.9

///|
pub const NOTE_HEAD_RY_RATIO : Double = 0.2542448 * 1.9

///|
pub const COS_NOTE_HEAD_ROTATION : Double = 0.906308

///|
pub const SIN_NOTE_HEAD_ROTATION : Double = 0.422618

///|
pub const STEM_DIRECTION_MIDI_THRESHOLD : Int = 71

// --- Beam ---

///|
pub const BEAM_THICKNESS : Double = 3.5

///|
pub const BEAM_REST_CLEARANCE : Double = 8.0

// --- Ottava ---

///|
pub const OTTAVA_ALTA_THRESHOLD_MIDI : Int = 84

///|
pub const OTTAVA_BASSA_LEDGER_LINE_THRESHOLD : Int = 4

///|
pub const OTTAVA_SHIFT : Int = 12

// --- Key signature ---

///|
pub const KEY_SIG_SYMBOL_SPACING : Double = 12.0
