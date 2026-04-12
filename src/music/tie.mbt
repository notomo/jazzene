///|
/// Tie state for notes that span measure or beat boundaries
pub(all) enum Tie {
  TieStart // Ties to next note
  TieEnd // Tied from previous note
  TieBoth // Spans 3+ segments (both in and out)
} derive(Eq, Debug)

///|
pub impl Show for Tie with output(self, logger) {
  self.to_repr().output(logger)
}
