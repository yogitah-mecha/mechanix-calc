/// Superscript digits, used for powers: `5²`, `(2+3)²`, and results such as
/// `9.9×10¹⁷` or `1.2×10⁻⁷` (10 to a power).
abstract final class Superscript {
  /// Every superscript character: the minus sign and the ten digits.
  static const String chars = '⁻⁰¹²³⁴⁵⁶⁷⁸⁹';

  /// A power: an optional superscript minus followed by at least one digit.
  static final RegExp powerPattern = RegExp('⁻?[⁰¹²³⁴⁵⁶⁷⁸⁹]+');

  /// A power while it is being typed: [powerPattern], or only its `⁻` so far.
  static final RegExp typedPowerPattern = RegExp('⁻?[⁰¹²³⁴⁵⁶⁷⁸⁹]+|⁻');

  static const _fromPlain = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '-': '⁻',
  };

  static final Map<String, String> _toPlain = {
    for (final entry in _fromPlain.entries) entry.value: entry.key,
  };

  /// `-17` -> `⁻¹⁷`. Characters without a superscript form are kept.
  static String fromPlain(String text) =>
      text.split('').map((c) => _fromPlain[c] ?? c).join();

  /// `⁻¹⁷` -> `-17`. Other characters are kept.
  static String toPlain(String text) =>
      text.split('').map((c) => _toPlain[c] ?? c).join();
}
