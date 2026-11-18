import 'package:equatable/equatable.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/calc_operator.dart';

/// A token of the expression the user is typing.
sealed class InputToken extends Equatable {
  const InputToken();
}

/// A number, optionally negative and/or raised to a superscript power.
final class NumberInput extends InputToken {
  const NumberInput(this.mantissa, {this.power = '', this.negative = false})
    : assert(power == '' || mantissa != ''),
      assert(mantissa != '' || negative);

  /// The sign typed before any digit: `(-`.
  const NumberInput.pendingSign() : this('', negative: true);

  /// Digits as typed, with at most one `.`: `5`, `5.`, `0.25`.
  /// Empty only for [NumberInput.pendingSign].
  final String mantissa;

  /// The superscript power in plain digits, optionally starting with `-`:
  /// `2`, `17`, `-7`. Empty when the number has no power.
  final String power;

  final bool negative;

  bool get isPendingSign => mantissa.isEmpty;
  bool get hasPower => power.isNotEmpty;
  bool get hasDecimalPoint => mantissa.contains('.');

  /// Digits that count towards the digit limit (the power does not).
  int get digitCount => mantissa.replaceAll('.', '').length;

  NumberInput copyWith({String? mantissa, String? power, bool? negative}) =>
      NumberInput(
        mantissa ?? this.mantissa,
        power: power ?? this.power,
        negative: negative ?? this.negative,
      );

  @override
  List<Object?> get props => [mantissa, power, negative];
}

/// `+ - × ÷ ^`.
final class OperatorInput extends InputToken {
  const OperatorInput(this.operator);

  final CalcOperator operator;

  @override
  List<Object?> get props => [operator];
}

/// Postfix percent applied to the value before it.
final class PercentInput extends InputToken {
  const PercentInput();

  @override
  List<Object?> get props => const [];
}

final class LeftParenthesisInput extends InputToken {
  const LeftParenthesisInput();

  @override
  List<Object?> get props => const [];
}

/// `)`, optionally raised to a superscript power: `(2+3)²`.
final class RightParenthesisInput extends InputToken {
  const RightParenthesisInput({this.power = ''});

  /// Same form as [NumberInput.power].
  final String power;

  bool get hasPower => power.isNotEmpty;

  @override
  List<Object?> get props => [power];
}
