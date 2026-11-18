import 'package:mechanix_calculator/features/calculator/domain/input/calc_operator.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/superscript.dart';

/// Reads display text back into [InputToken]s: a history entry, a previous
/// result, or text from before tokens were stored.
class ExpressionReader {
  const ExpressionReader();

  static final _mantissa = RegExp(r'[0-9,]*(?:\.[0-9]*)?');

  /// Throws a [FormatException] for text that is not calculator input,
  /// e.g. `2(3)` (multiplication is always written out) or `abc`.
  List<InputToken> read(String text) {
    final tokens = <InputToken>[];
    var position = 0;
    var openBrackets = 0;

    bool expectsValue() =>
        tokens.isEmpty ||
        tokens.last is OperatorInput ||
        tokens.last is LeftParenthesisInput;

    Never fail(String message) =>
        throw FormatException(message, text, position);

    while (position < text.length) {
      final char = text[position];

      // Negative number: "(-5)", "(-5²)", "(-" or "(-0." at the very end.
      if (text.startsWith('(-', position) && expectsValue()) {
        final (number, end) = _readNumber(text, position + 2);
        if (number == null && end == text.length) {
          tokens.add(const NumberInput.pendingSign());
          position = end;
          continue;
        }
        if (number != null && end == text.length) {
          tokens.add(number.copyWith(negative: true));
          position = end;
          continue;
        }
        if (number != null && text[end] == ')') {
          tokens.add(number.copyWith(negative: true));
          position = end + 1;
          continue;
        }
        // Otherwise "(" opens a group, e.g. "(-5+3)".
      }

      if (char == '(') {
        if (!expectsValue()) fail('Expected an operator');
        tokens.add(const LeftParenthesisInput());
        openBrackets++;
        position++;
        continue;
      }

      if (char == ')') {
        if (expectsValue() || openBrackets == 0) fail('Unexpected ")"');
        final power = Superscript.typedPowerPattern.matchAsPrefix(
          text,
          position + 1,
        );
        tokens.add(RightParenthesisInput(power: _plain(power)));
        openBrackets--;
        position = power?.end ?? position + 1;
        continue;
      }

      // "-5" / "-" where a value is expected.
      if (char == '-' && expectsValue()) {
        final (number, end) = _readNumber(text, position + 1);
        if (number == null && end != text.length) fail('Expected a number');
        tokens.add(
          number?.copyWith(negative: true) ?? const NumberInput.pendingSign(),
        );
        position = end;
        continue;
      }

      final operator = CalcOperator.fromSymbol(char);
      if (operator != null || char == '%') {
        if (expectsValue()) fail('Expected a number');
        tokens.add(
          operator != null ? OperatorInput(operator) : const PercentInput(),
        );
        position++;
        continue;
      }

      final (number, end) = _readNumber(text, position);
      if (number == null) fail('Unexpected character');
      if (!expectsValue()) fail('Expected an operator');
      tokens.add(number);
      position = end;
    }

    return tokens;
  }

  /// Reads a formatted result (`-1,234.5`, `9.9×10¹⁷`) as complete input.
  /// Returns null when [text] is not a finished value.
  List<InputToken>? readResult(String text) {
    try {
      final tokens = read(text);
      final last = tokens.lastOrNull;
      final complete =
          (last is NumberInput && !last.isPendingSign) ||
          last is RightParenthesisInput ||
          last is PercentInput;
      return complete ? tokens : null;
    } on FormatException {
      return null;
    }
  }

  /// A number with its optional superscript power, or null (and [start])
  /// when there is no digit at [start].
  static (NumberInput?, int) _readNumber(String text, int start) {
    final mantissa = _mantissa.matchAsPrefix(text, start)!;
    final digits = mantissa[0]!.replaceAll(',', '');
    if (!digits.contains(RegExp('[0-9]'))) return (null, start);

    final power = Superscript.typedPowerPattern.matchAsPrefix(
      text,
      mantissa.end,
    );
    return (
      NumberInput(digits, power: _plain(power)),
      power?.end ?? mantissa.end,
    );
  }

  static String _plain(Match? power) =>
      power == null ? '' : Superscript.toPlain(power[0]!);
}
