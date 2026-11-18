import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';

/// Name of the function that stands for postfix percent in the
/// `math_expressions` source. `%` itself means modulo there.
const String percentFunctionName = 'pct';

/// Expression source for `GrammarParser`, plus the values of the number
/// variables it refers to.
class SerializedExpression {
  const SerializedExpression(this.source, this.variables);

  final String source;

  /// `n0`, `n1`, … -> number value. Numbers are bound as variables because
  /// the parser's number literal (`digits(.digits)?`) cannot express every
  /// double (`.5`, `5.`, `9.9e17`); a variable keeps the exact value.
  final Map<String, double> variables;
}

/// Translates the input tokens straight into `math_expressions` syntax
class CalcSerializer {
  const CalcSerializer();

  /// Throws a [FormatException] for unfinished input.
  SerializedExpression serialize(List<InputToken> tokens) {
    final parts = <String>[];
    final variables = <String, double>{};

    String bind(double value) {
      final name = 'n${variables.length}';
      variables[name] = value;
      return name;
    }

    // Index in [parts] where the most recent complete value starts, so a
    // following `%` can wrap it. Null when the last token was not a value.
    int? valueStart;
    final openGroups = <int>[];

    for (final token in tokens) {
      switch (token) {
        case NumberInput(isPendingSign: true):
          throw const FormatException('Expected a number after "(-"');

        case NumberInput(power: '-') || RightParenthesisInput(power: '-'):
          throw const FormatException('Expected a digit in the power');

        case final NumberInput number:
          valueStart = parts.length;
          parts.add(_number(number, bind));

        case OperatorInput(:final operator):
          parts.add(operator.parserSymbol);
          valueStart = null;

        case PercentInput():
          final start = valueStart;
          if (start == null) {
            throw const FormatException('Expected a value before "%"');
          }
          // valueStart stays: the wrapped value can take another `%`.
          parts
            ..insert(start, '$percentFunctionName(')
            ..add(')');

        case LeftParenthesisInput():
          openGroups.add(parts.length);
          parts.add('(');
          valueStart = null;

        case RightParenthesisInput(:final power):
          parts.add(power.isEmpty ? ')' : ')^${bind(double.parse(power))}');
          valueStart = openGroups.isEmpty ? null : openGroups.removeLast();
      }
    }

    return SerializedExpression(parts.join(), variables);
  }

  static String _number(NumberInput number, String Function(double) bind) {
    final value = bind(double.parse(_normalize(number.mantissa)));
    final base = number.hasPower
        ? '($value^${bind(double.parse(number.power))})'
        : value;
    return number.negative ? '(-$base)' : base;
  }

  /// "5." -> "5.0", ".5" -> "0.5".
  static String _normalize(String mantissa) {
    var result = mantissa;
    if (result.startsWith('.')) result = '0$result';
    if (result.endsWith('.')) result = '${result}0';
    return result;
  }
}
