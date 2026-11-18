import 'package:mechanix_calculator/features/calculator/domain/input/calc_operator.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_limits.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_renderer.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';

export 'package:mechanix_calculator/features/calculator/domain/input/input_limits.dart';

/// Result of an edit: the new tokens, or the unchanged tokens plus the limit
/// that stopped the edit.
class EditResult {
  const EditResult(this.tokens, [this.error]);

  final List<InputToken> tokens;
  final InputLimitError? error;
}

/// Handles key input based on the last token.
class ExpressionEditor {
  const ExpressionEditor({
    required this.renderer,
    this.limits = const InputLimits(),
  });

  /// Renders the tokens for the character limit.
  final InputRenderer renderer;
  final InputLimits limits;

  static const _times = OperatorInput(CalcOperator.multiply);

  EditResult appendDigit(List<InputToken> tokens, String digit) {
    assert(_isDigit(digit), 'Not a digit: $digit');
    return switch (tokens.lastOrNull) {
      null ||
      OperatorInput() ||
      LeftParenthesisInput() => _append(tokens, [NumberInput(digit)]),
      NumberInput(hasPower: true) ||
      RightParenthesisInput(hasPower: true) => EditResult(tokens),
      RightParenthesisInput() ||
      PercentInput() => _append(tokens, [_times, NumberInput(digit)]),
      final NumberInput number => _replaceLastChecked(
        tokens,
        number.copyWith(
          mantissa: number.mantissa == '0' ? digit : number.mantissa + digit,
        ),
      ),
    };
  }

  EditResult appendDecimalPoint(List<InputToken> tokens) =>
      switch (tokens.lastOrNull) {
        null ||
        OperatorInput() ||
        LeftParenthesisInput() => _append(tokens, [const NumberInput('0.')]),
        NumberInput(isPendingSign: true) => _replaceLastChecked(
          tokens,
          const NumberInput('0.', negative: true),
        ),
        NumberInput(hasPower: true) ||
        NumberInput(hasDecimalPoint: true) ||
        RightParenthesisInput(hasPower: true) => EditResult(tokens),
        RightParenthesisInput() ||
        PercentInput() => _append(tokens, [_times, const NumberInput('0.')]),
        final NumberInput number => _replaceLastChecked(
          tokens,
          number.copyWith(mantissa: '${number.mantissa}.'),
        ),
      };

  /// [previousResult] continues the last calculation when the input is
  /// empty: `42` then `+` gives `42+`.
  EditResult appendOperator(
    List<InputToken> tokens,
    CalcOperator operator, {
    List<InputToken>? previousResult,
  }) {
    final next = OperatorInput(operator);
    final startsNegative = operator == CalcOperator.subtract;

    return switch (tokens.lastOrNull) {
      null when startsNegative => _append(tokens, [
        const NumberInput.pendingSign(),
      ]),
      null when previousResult?.isNotEmpty ?? false => _checked(tokens, [
        ...?previousResult,
        next,
      ]),
      null => EditResult(tokens),
      LeftParenthesisInput() when startsNegative => _append(tokens, [
        const NumberInput.pendingSign(),
      ]),
      LeftParenthesisInput() => EditResult(tokens),
      NumberInput(isPendingSign: true) => EditResult(
        _withOperator(_withoutLast(tokens), next),
      ),
      NumberInput(power: '-') ||
      RightParenthesisInput(power: '-') => EditResult(tokens),
      OperatorInput(operator: final previous)
          when startsNegative && _takesNegativeOperand.contains(previous) =>
        _append(tokens, [const NumberInput.pendingSign()]),
      OperatorInput() => _replaceLastChecked(tokens, next),
      NumberInput() ||
      RightParenthesisInput() ||
      PercentInput() => _append(tokens, [next]),
    };
  }

  EditResult appendOpenBracket(List<InputToken> tokens) =>
      switch (tokens.lastOrNull) {
        null || OperatorInput() || LeftParenthesisInput() => _append(tokens, [
          const LeftParenthesisInput(),
        ]),
        NumberInput(isPendingSign: true) ||
        NumberInput(power: '-') ||
        RightParenthesisInput(power: '-') => EditResult(tokens),
        NumberInput() || RightParenthesisInput() || PercentInput() => _append(
          tokens,
          [_times, const LeftParenthesisInput()],
        ),
      };

  EditResult appendCloseBracket(List<InputToken> tokens) =>
      openBrackets(tokens) > 0 && _endsWithValue(tokens)
      ? _append(tokens, [const RightParenthesisInput()])
      : EditResult(tokens);

  /// Ctrl+digit or Ctrl+`-`: extends the superscript power of the last
  /// number or `)`: `5` -> `5²` -> `5²³`; `5` -> `5⁻` -> `5⁻²`.
  /// A `-` is only taken as the first character of a power.
  EditResult appendSuperscript(List<InputToken> tokens, String char) {
    assert(_isDigit(char) || char == '-', 'Not a digit or "-": $char');
    final power = switch (tokens.lastOrNull) {
      final NumberInput number when !number.isPendingSign => number.power,
      final RightParenthesisInput bracket => bracket.power,
      _ => null,
    };
    if (power == null || (char == '-' && power.isNotEmpty)) {
      return EditResult(tokens);
    }
    return _replaceLastChecked(tokens, switch (tokens.last) {
      final NumberInput number => number.copyWith(power: power + char),
      _ => RightParenthesisInput(power: power + char),
    });
  }

  EditResult toggleSign(List<InputToken> tokens) => switch (tokens.lastOrNull) {
    null || OperatorInput() || LeftParenthesisInput() => _append(tokens, [
      const NumberInput.pendingSign(),
    ]),
    NumberInput(isPendingSign: true) => EditResult(_withoutLast(tokens)),
    final NumberInput number => _replaceLastChecked(
      tokens,
      number.copyWith(negative: !number.negative),
    ),
    RightParenthesisInput() => EditResult(tokens),
    PercentInput() => _toggleNumberBeforePercent(tokens),
  };

  /// +/- on a previous result (a number, or a number×10ⁿ): flipping the sign
  /// of its first number negates the whole result.
  /// `8` -> `(-8)`, `9.9×10¹⁷` -> `(-9.9)×10¹⁷`.
  EditResult negateResult(List<InputToken> result) =>
      switch (result.firstOrNull) {
        final NumberInput number => _checked(result, [
          number.copyWith(negative: !number.negative),
          ...result.skip(1),
        ]),
        _ => EditResult(result),
      };

  EditResult appendPercent(List<InputToken> tokens) =>
      switch (tokens.lastOrNull) {
        NumberInput(isPendingSign: false, hasPower: false) ||
        RightParenthesisInput(hasPower: false) ||
        PercentInput() => _append(tokens, [const PercentInput()]),
        _ => EditResult(tokens),
      };

  List<InputToken> backspace(List<InputToken> tokens) {
    final rest = _withoutLast(tokens);
    return switch (tokens.lastOrNull) {
      null => tokens,
      final NumberInput number when number.hasPower => [
        ...rest,
        number.copyWith(power: _dropLastPowerChar(number.power)),
      ],
      final RightParenthesisInput bracket when bracket.hasPower => [
        ...rest,
        RightParenthesisInput(power: _dropLastPowerChar(bracket.power)),
      ],
      final NumberInput number when number.mantissa.length > 1 => [
        ...rest,
        number.copyWith(
          mantissa: number.mantissa.substring(0, number.mantissa.length - 1),
        ),
      ],
      _ => rest,
    };
  }

  /// Whether [tokens] end with a finished value, so `)` or `=` can follow.
  bool endsWithValue(List<InputToken> tokens) => _endsWithValue(tokens);

  /// Closes every open bracket, for `=`: `2×(3+4` -> `2×(3+4)`. Input that
  /// does not end with a value is returned unchanged.
  List<InputToken> closeBrackets(List<InputToken> tokens) =>
      _endsWithValue(tokens)
      ? [
          ...tokens,
          for (var i = 0; i < openBrackets(tokens); i++)
            const RightParenthesisInput(),
        ]
      : tokens;

  int openBrackets(List<InputToken> tokens) =>
      tokens.whereType<LeftParenthesisInput>().length -
      tokens.whereType<RightParenthesisInput>().length;

  /// Operators (including the `×` added before a value), percents and
  /// powers count; brackets and the sign of a negative number do not.
  int countOperations(List<InputToken> tokens) => tokens
      .where(
        (t) => switch (t) {
          OperatorInput() || PercentInput() => true,
          NumberInput(:final hasPower) ||
          RightParenthesisInput(:final hasPower) => hasPower,
          LeftParenthesisInput() => false,
        },
      )
      .length;

  /// The first limit [tokens] break, checked in display order.
  InputLimitError? checkLimits(List<InputToken> tokens) {
    if (renderer.render(tokens).length > limits.maxCharacters) {
      return InputLimitError.maxCharacters;
    }
    if (countOperations(tokens) > limits.maxOperations) {
      return InputLimitError.maxOperations;
    }
    if (tokens.any(
      (t) => t is NumberInput && t.digitCount > limits.maxDigits,
    )) {
      return InputLimitError.maxDigits;
    }
    return null;
  }

  EditResult _checked(List<InputToken> before, List<InputToken> after) {
    final error = checkLimits(after);
    return error == null ? EditResult(after) : EditResult(before, error);
  }

  EditResult _append(List<InputToken> tokens, List<InputToken> added) =>
      _checked(tokens, [...tokens, ...added]);

  EditResult _replaceLastChecked(List<InputToken> tokens, InputToken token) =>
      _checked(tokens, [..._withoutLast(tokens), token]);

  EditResult _toggleNumberBeforePercent(List<InputToken> tokens) {
    final index = tokens.lastIndexWhere((t) => t is! PercentInput);
    if (index < 0 || tokens[index] is! NumberInput) return EditResult(tokens);
    final number = tokens[index] as NumberInput;
    return _checked(tokens, [
      ...tokens.sublist(0, index),
      number.copyWith(negative: !number.negative),
      ...tokens.sublist(index + 1),
    ]);
  }

  /// After a pending sign is cancelled: the new operator replaces the one
  /// before it; after `(` or on empty input nothing is added.
  static List<InputToken> _withOperator(
    List<InputToken> tokens,
    OperatorInput operator,
  ) => switch (tokens.lastOrNull) {
    null || LeftParenthesisInput() => tokens,
    OperatorInput() => [..._withoutLast(tokens), operator],
    _ => [...tokens, operator],
  };

  static bool _endsWithValue(List<InputToken> tokens) =>
      switch (tokens.lastOrNull) {
        NumberInput(power: '-') || RightParenthesisInput(power: '-') => false,
        NumberInput(isPendingSign: false) ||
        RightParenthesisInput() ||
        PercentInput() => true,
        _ => false,
      };

  /// Operators after which `-` starts a negative operand instead of
  /// replacing them: `5×-3`, `6÷-2`, `5^-2`.
  static const _takesNegativeOperand = {
    CalcOperator.multiply,
    CalcOperator.divide,
    CalcOperator.power,
  };

  /// `17` -> `1`, `-7` -> `` (a lone minus is not a power).
  static String _dropLastPowerChar(String power) {
    final shorter = power.substring(0, power.length - 1);
    return shorter == '-' ? '' : shorter;
  }

  static List<InputToken> _withoutLast(List<InputToken> tokens) =>
      tokens.isEmpty ? tokens : tokens.sublist(0, tokens.length - 1);

  static bool _isDigit(String text) => RegExp(r'^[0-9]$').hasMatch(text);
}
