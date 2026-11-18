import 'package:mechanix_calculator/features/calculator/domain/input/input_renderer.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/superscript.dart';

/// Renders [InputToken]s as the display text: `2×(-5)+(1+2)²^3+10%`.
///
/// The output is what `ExpressionReader` reads back and what `CalcEngine`
/// evaluates.
class ExpressionRenderer implements InputRenderer {
  const ExpressionRenderer();

  @override
  String render(List<InputToken> tokens) => tokens.map(renderToken).join();

  String renderToken(InputToken token) => switch (token) {
    NumberInput(isPendingSign: true) => '(-',
    final NumberInput number when number.negative => '(-${_number(number)})',
    final NumberInput number => _number(number),
    OperatorInput(:final operator) => operator.displaySymbol,
    PercentInput() => '%',
    LeftParenthesisInput() => '(',
    RightParenthesisInput(:final power) => ')${Superscript.fromPlain(power)}',
  };

  static String _number(NumberInput number) =>
      '${number.mantissa}${Superscript.fromPlain(number.power)}';
}
