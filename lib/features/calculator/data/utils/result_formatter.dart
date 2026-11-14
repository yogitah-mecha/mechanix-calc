/// Formats calculation results for display and converts displayed
/// scientific notation back into an evaluable expression.
class ResultFormatter {
  /// Results with an absolute value at or above this use scientific notation
  /// (16+ integer digits can't be represented exactly by a double).
  static const double scientificUpperThreshold = 1e15;

  /// Non-zero results with an absolute value below this use scientific
  /// notation instead of a long run of leading zeros.
  static const double scientificLowerThreshold = 1e-6;

  /// Significant digits shown for plain (non-scientific) results.
  static const int plainPrecision = 15;

  /// Significant digits shown in a scientific mantissa (Ubuntu-style).
  static const int scientificPrecision = 10;

  static const _superscriptDigits = {
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

  static final Map<String, String> _plainDigits = {
    for (final e in _superscriptDigits.entries) e.value: e.key,
  };

  static const String superscriptChars = '⁻⁰¹²³⁴⁵⁶⁷⁸⁹';

  /// Matches a displayed scientific suffix such as `×10¹⁷` or `×10⁻⁸`.
  static final RegExp scientificSuffixPattern = RegExp(
    '×10([$superscriptChars]+)',
  );

  static final _groupingPattern = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  static bool isScientific(String text) =>
      scientificSuffixPattern.hasMatch(text);

  /// Converts superscript characters back to plain ones: "⁻²⁰" -> "-20".
  static String fromSuperscript(String text) =>
      text.split('').map((c) => _plainDigits[c] ?? c).join();

  /// Splits "9.99999998×10¹⁷" into ("9.99999998×10", "17") for rendering
  /// the exponent as raised, smaller plain digits. Returns null otherwise.
  static ({String base, String exponent})? splitScientific(String text) {
    final match = scientificSuffixPattern.firstMatch(text);
    if (match == null || match.end != text.length) return null;
    final exponent = match[1]!.split('').map((c) => _plainDigits[c]!).join();
    return (base: text.substring(0, match.start + 3), exponent: exponent);
  }

  static String format(double value) {
    if (value == 0) return '0';

    final abs = value.abs();
    if (abs >= scientificUpperThreshold || abs < scientificLowerThreshold) {
      return _formatScientific(value);
    }

    var result = double.parse(value.toStringAsPrecision(plainPrecision))
        .toString();
    if (result.endsWith('.0')) {
      result = result.substring(0, result.length - 2);
    }
    // Rounding to plainPrecision can push a value onto a threshold edge.
    if (result.contains('e')) return _formatScientific(value);

    // Only whole numbers get thousands separators (existing behaviour).
    return result.contains('.') ? result : _groupThousands(result);
  }

  static String _formatScientific(double value) {
    final parts = value
        .toStringAsExponential(scientificPrecision - 1)
        .split('e');
    var mantissa = parts[0];
    if (mantissa.contains('.')) {
      mantissa = mantissa.replaceFirst(RegExp(r'0+$'), '');
      if (mantissa.endsWith('.')) {
        mantissa = mantissa.substring(0, mantissa.length - 1);
      }
    }
    final exponent = int.parse(parts[1]);
    return '$mantissa×10${toSuperscript(exponent)}';
  }

  static String _groupThousands(String number) =>
      number.replaceAllMapped(_groupingPattern, (m) => '${m[1]},');

  static String toSuperscript(int exponent) => exponent
      .toString()
      .split('')
      .map((c) => _superscriptDigits[c] ?? c)
      .join();

  /// Rewrites `×10¹⁷` as `*10^(17)` so the expression can be parsed.
  static String toEvaluable(String expression) =>
      expression.replaceAllMapped(scientificSuffixPattern, (m) {
        final exponent = m[1]!.split('').map((c) => _plainDigits[c]!).join();
        return '*10^($exponent)';
      });
}
