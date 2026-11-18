import 'package:mechanix_calculator/features/calculator/domain/input/superscript.dart';

/// Formats calculation results for display, using scientific notation
/// with superscript exponents (9.99999998×10¹⁷) for very large or small
/// values.
abstract final class ResultFormatter {
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

  static final _groupingPattern = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  static final _trailingZeros = RegExp(r'0+$');

  static String format(double value) {
    if (value == 0) return '0';

    final abs = value.abs();
    if (abs >= scientificUpperThreshold || abs < scientificLowerThreshold) {
      return _formatScientific(value);
    }

    var result = double.parse(
      value.toStringAsPrecision(plainPrecision),
    ).toString();
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
      mantissa = mantissa.replaceFirst(_trailingZeros, '');
      if (mantissa.endsWith('.')) {
        mantissa = mantissa.substring(0, mantissa.length - 1);
      }
    }
    final exponent = int.parse(parts[1]);
    return '$mantissa×10${Superscript.fromPlain('$exponent')}';
  }

  static String _groupThousands(String number) =>
      number.replaceAllMapped(_groupingPattern, (m) => '${m[1]},');
}
