/// Limits on what can be typed. The user-facing messages that state these
/// numbers live with the other display strings in `core/utils/constant.dart`.
class InputLimits {
  const InputLimits({
    this.maxCharacters = 100,
    this.maxOperations = 20,
    this.maxDigits = 15,
  });

  /// Length of the displayed expression.
  final int maxCharacters;

  /// Operators, percents and superscript powers; brackets and the sign of a
  /// negative number do not count.
  final int maxOperations;

  /// Digits in one number; the decimal point and its power do not count.
  final int maxDigits;
}

/// The input limit an edit would have broken.
enum InputLimitError { maxCharacters, maxOperations, maxDigits }
