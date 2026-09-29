import 'package:equatable/equatable.dart';

class HistoryItem extends Equatable {
  final String expression;
  final String result;
  final String displayResult; // pre-built, zero alloc during build()
  final String? errorMessage;

  const HistoryItem({
    required this.expression,
    required this.result,
    this.errorMessage,
  }) : displayResult = errorMessage ?? '= $result';

  @override
  List<Object?> get props => [expression, result];
}

class CalculatorState extends Equatable {
  final String expression;
  final String result;
  final String errorMessage;
  final List<HistoryItem> history;
  final bool isCalculated;

  const CalculatorState({
    this.expression = '',
    this.result = '0',
    this.errorMessage = '',
    this.history = const [],
    this.isCalculated = false,
  });

  CalculatorState copyWith({
    String? expression,
    String? result,
    String? errorMessage,
    List<HistoryItem>? history,
    bool? isCalculated,
  }) {
    return CalculatorState(
      expression: expression ?? this.expression,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      history: history ?? this.history,
      isCalculated: isCalculated ?? this.isCalculated,
    );
  }

  @override
  List<Object> get props => [
    expression,
    result,
    errorMessage,
    history,
    isCalculated,
  ];
}
