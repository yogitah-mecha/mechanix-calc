import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'calculator_event.dart';
import 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  CalculatorBloc() : super(const CalculatorState()) {
    on<CalculateResult>(_onCalculateResult);
    on<ClearPressed>(_onClearPressed);
  }

  static final _percentPattern = RegExp(r'(\d+(?:\.\d+)?)%');
  static final _numberFormattingPattern = RegExp(
    r'(\d{1,3})(?=(\d{3})+(?!\d))',
  );
  static final _leadingDecimalPattern = RegExp(r'(?<=[+\-*/])\.');

  void _onClearPressed(ClearPressed event, Emitter<CalculatorState> emit) {
    emit(
      state.copyWith(
        expression: '',
        result: '0',
        errorMessage: '',
        isCalculated: false,
      ),
    );
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
      String finalExpression = expressionToEvaluate
          .replaceAll(',', '')
          .replaceAll('×', '*')
          .replaceAll('÷', '/');

      // Convert leading decimal values to valid numeric expressions.
      // Example: 4*.2 -> 4*0.2
      finalExpression = finalExpression.replaceAllMapped(
        _leadingDecimalPattern,
        (_) => '0.',
      );

      // Convert percentage values to division by 100 for evaluation.
      finalExpression = finalExpression.replaceAllMapped(
        _percentPattern,
        (match) => '(${match[1]}/100)',
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
            isCalculated: false,
          ),
        );
        return;
      }

      String result;
      if (eval == 0) {
        result = '0';
      } else {
        result = double.parse(eval.toStringAsPrecision(10)).toString();
        if (result.endsWith('.0')) {
          result = result.substring(0, result.length - 2);
        }
      }

      // Formatting for whole numbers
      if (result.length > 3 && !result.contains('.')) {
        result = result.replaceAllMapped(
          _numberFormattingPattern,
          (match) => '${match[1]},',
        );
      }

      final updatedHistory = List<HistoryItem>.from(state.history)
        ..insert(
          0,
          HistoryItem(expression: expressionToEvaluate, result: result),
        );

      emit(
        state.copyWith(
          expression: '',
          result: result,
          history: updatedHistory,
          errorMessage: '',
          isCalculated: true,
        ),
      );
    } catch (e) {
      // Catch syntax errors (e.g., malformed expressions like "5++5")
      emit(
        state.copyWith(
          expression: expressionToEvaluate,
          result: '',
          errorMessage: invalidOperationsErrorMessage,
          isCalculated: false,
        ),
      );
    }
  }
}
