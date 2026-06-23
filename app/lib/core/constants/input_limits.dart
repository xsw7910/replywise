/// Shared input length limits used across Reply, Polish, and Guidance Library.
///
/// `guidanceMaxLength` is the single source of truth for any free-form guidance
/// text the user can author: Reply guidance, Polish custom guidance, and saved
/// Guidance Library items. Keeping these aligned prevents a library item that is
/// valid when created from failing validation when used in Reply or Polish.
abstract final class InputLimits {
  /// Max length for any guidance content (Reply guidance, Polish custom
  /// guidance, and Guidance Library item content). Must match the backend
  /// validation in `backend/app/api/v1/ai.py`.
  static const int guidanceMaxLength = 1000;

  /// Max length for a Guidance Library item title.
  static const int guidanceTitleMaxLength = 80;
}
