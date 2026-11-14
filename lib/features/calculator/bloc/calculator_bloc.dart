import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/result_formatter.dart';
import 'calculator_event.dart';
import 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  CalculatorBloc() : super(const CalculatorState()) {
    on<CalculateResult>(_onCalculateResult);
    on<ClearPressed>(_onClearPressed);
  }

  static final _percentPattern = RegExp(r'(\d+(?:\.\d+)?)%');
  static final _leadingDecimalPattern = RegExp(r'(?<=[+\-*/])\.');
  static final _negativeNumberPattern = RegExp(
    r'(?<=[+\-*/])-(?:\d+(?:\.\d+)?|\.\d+)',
  );

  /// Rewrites binary `+%` and `-%` as a percentage of the preceding
  /// operand within the same parenthesis group. Multiplication,
  /// division, and unary minus retain the plain `/100` conversion.
  static String resolvePercentageExpressions(String expression) {
    var result = expression;
    var searchFrom = 0;
    while (true) {
      final match = _percentPattern.allMatches(result, searchFrom).firstOrNull;
      if (match == null) break;

      final opIndex = match.start - 1;
      final op = opIndex >= 0 ? result[opIndex] : '';
      final isBinaryAdditive =
          (op == '+' || op == '-') &&
          opIndex > 0 &&
          RegExp(r'[0-9.)]').hasMatch(result[opIndex - 1]);

      if (!isBinaryAdditive) {
        searchFrom = match.end;
        continue;
      }

      // Walk left to the start of the enclosing parenthesis group.
      var depth = 0;
      var i = opIndex - 1;
      for (; i >= 0; i--) {
        final c = result[i];
        if (c == ')') {
          depth++;
        } else if (c == '(') {
          if (depth == 0) break;
          depth--;
        }
      }
      final base = result.substring(i + 1, opIndex);

      final replacement = '(($base)*${match[1]}/100)';
      result = result.replaceRange(match.start, match.end, replacement);
      searchFrom = match.start + replacement.length;
    }
    return result;
  }

  void _onClearPressed(ClearPressed event, Emitter<CalculatorState> emit) {
    emit(state.copyWith(expression: '', result: '0', errorMessage: ''));
  }

  void _onCalculateResult(
    CalculateResult event,
    Emitter<CalculatorState> emit,
  ) {
    final expressionToEvaluate = event.expression.isNotEmpty
        ? event.expression
        : state.expression;

    if (expressionToEvaluate.isEmpty) return;

    try {
      // Scientific results reused in a new calculation: 9.9×10¹⁷ -> 9.9*10^(17)
      String finalExpression = ResultFormatter.toEvaluable(
        expressionToEvaluate,
      ).replaceAll(',', '').replaceAll('×', '*').replaceAll('÷', '/');

      // Convert leading decimal values to valid numeric expressions.
      // Example: 4*.2 -> 4*0.2
      finalExpression = finalExpression.replaceAllMapped(
        _leadingDecimalPattern,
        (_) => '0.',
      );

      // Percent after a binary + or - is relative to the left operand,
      // matching common calculators: 200+10% -> 200+(200*10/100) = 220.
      finalExpression = resolvePercentageExpressions(finalExpression);

      // Remaining percentages (e.g. 200*50%, 50%) are division by 100.
      finalExpression = finalExpression.replaceAllMapped(
        _percentPattern,
        (match) => '(${match[1]}/100)',
      );

      // Wrap negative numbers that follow an operator in parentheses for evaluation.
      // E.g., -2*-2 -> -2*(-2), 5+-3 -> 5+(-3), 10/-2 -> 10/(-2), 5--3 -> 5-(-3)
      finalExpression = finalExpression.replaceAllMapped(
        _negativeNumberPattern,
        (match) => '(${match.group(0)})',
      );

      GrammarParser p = GrammarParser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Handle Division by Zero or other invalid mathematical results
      if (eval.isInfinite || eval.isNaN) {
        emit(
          state.copyWith(
            expression: expressionToEvaluate,
            result: '',
            errorMessage: invalidOperationsErrorMessage,
          ),
        );
        return;
      }

      // Plain up to 15 significant digits; scientific (e.g. 9.99999998×10¹⁷)
      // beyond that, so rounded digits are never shown as exact zeros.
      final result = ResultFormatter.format(eval);

      final updatedHistory = List<HistoryItem>.from(state.history)
        ..insert(
          0,
          HistoryItem(expression: expressionToEvaluate, result: result),
        );

      emit(
        state.copyWith(
          expression: expressionToEvaluate,
          result: result,
          history: updatedHistory,
          errorMessage: '',
        ),
      );
    } catch (e) {
      // Catch syntax errors (e.g., malformed expressions like "5++5")
      emit(
        state.copyWith(
          expression: expressionToEvaluate,
          result: '',
          errorMessage: invalidOperationsErrorMessage,
        ),
      );
    }
  }
}
