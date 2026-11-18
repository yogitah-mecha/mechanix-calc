import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/domain/engine/calc_engine.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_reader.dart';
import 'package:mechanix_calculator/features/calculator/presentation/formatting/result_formatter.dart';
import 'calculator_event.dart';
import 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  CalculatorBloc({
    CalcEngine? engine,
    ExpressionReader reader = const ExpressionReader(),
  }) : _engine = engine ?? CalcEngine(),
       _reader = reader,
       super(const CalculatorState()) {
    on<CalculateResult>(_onCalculateResult);
    on<ClearPressed>(_onClearPressed);
  }

  final CalcEngine _engine;
  final ExpressionReader _reader;

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
      final eval = _engine.evaluate(_reader.read(expressionToEvaluate));

      // NaN: undefined (e.g. division by zero); infinity: overflow.
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
    } catch (_) {
      // Malformed expression (FormatException), e.g. "5++5" or "5×".
      // Narrowed to typed errors in the CalcError refactor.
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
