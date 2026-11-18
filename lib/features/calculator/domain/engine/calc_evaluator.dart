import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart';

/// [RealEvaluator] with the calculator's power rule.
class CalcEvaluator extends RealEvaluator {
  CalcEvaluator(ContextModel context) : super(context, true);

  @override
  void visitPower(Power op) {
    final (exponent, base) = pop2();
    push1(base == 0 && exponent == 0 ? double.nan : math.pow(base, exponent));
  }
}
