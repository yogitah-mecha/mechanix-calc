import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/expression_builder.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/button_grid.dart';
import 'package:widgets/widgets.dart';
import '../../bloc/calculator_bloc.dart';
import '../../bloc/calculator_event.dart';
import '../../bloc/calculator_state.dart';
import '../widgets/display_panel.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final FocusNode _focusNode = FocusNode();
  final ValueNotifier<bool> _isHistoryOpenNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> _expressionNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> _errorMessageNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _focusNode.dispose();
    _isHistoryOpenNotifier.dispose();
    _expressionNotifier.dispose();
    _errorMessageNotifier.dispose();
    super.dispose();
  }

  bool get _hasFatalError =>
      _errorMessageNotifier.value == invalidOperationsErrorMessage;

  void _onNumberPressed(String number) {
    if (_hasFatalError) {
      _errorMessageNotifier.value = '';
      _expressionNotifier.value = number == '.' ? '0.' : number;
      context.read<CalculatorBloc>().add(const ClearPressed());
      return;
    }
    final res = ExpressionBuilder.handleNumber(
      _expressionNotifier.value,
      number,
    );
    _expressionNotifier.value = res.expression;
    _errorMessageNotifier.value = res.errorMessage;
  }

  void _onOperatorPressed(String operator) {
    if (_hasFatalError) {
      _errorMessageNotifier.value = '';
      _expressionNotifier.value = operator == '-' ? '-' : '';
      context.read<CalculatorBloc>().add(const ClearPressed());
      return;
    }
    final previousResult = context.read<CalculatorBloc>().state.result;
    final res = ExpressionBuilder.handleOperator(
      _expressionNotifier.value,
      operator,
      previousResult: previousResult,
    );
    _expressionNotifier.value = res.expression;
    _errorMessageNotifier.value = res.errorMessage;
  }

  void _onClearPressed() {
    _expressionNotifier.value = '';
    _errorMessageNotifier.value = '';
    context.read<CalculatorBloc>().add(const ClearPressed());
  }

  void _onDeletePressed() {
    if (_hasFatalError) {
      _onClearPressed();
      return;
    }
    final res = ExpressionBuilder.handleDelete(_expressionNotifier.value);
    _expressionNotifier.value = res.expression;
    _errorMessageNotifier.value = res.errorMessage;
  }

  void _onToggleSignPressed() {
    if (_hasFatalError) {
      _onClearPressed();
      return;
    }
    final res = ExpressionBuilder.handleToggleSign(_expressionNotifier.value);
    _expressionNotifier.value = res.expression;
    _errorMessageNotifier.value = res.errorMessage;
  }

  void _onPercentagePressed() {
    if (_hasFatalError) {
      _onClearPressed();
      return;
    }
    final res = ExpressionBuilder.handlePercentage(_expressionNotifier.value);
    _expressionNotifier.value = res.expression;
    _errorMessageNotifier.value = res.errorMessage;
  }

  void _onCalculateResult() {
    if (_expressionNotifier.value.isNotEmpty) {
      final expr = _expressionNotifier.value;
      _expressionNotifier.value = '';
      context.read<CalculatorBloc>().add(CalculateResult(expr));
    }
  }

  void _handleButtonAction(CalculatorButtonData button) {
    switch (button.action) {
      case CalculatorActionType.number:
        _onNumberPressed(button.value ?? button.text ?? '');
      case CalculatorActionType.operator:
        _onOperatorPressed(button.value ?? button.text ?? '');
      case CalculatorActionType.clear:
        _onClearPressed();
      case CalculatorActionType.delete:
        _onDeletePressed();
      case CalculatorActionType.toggleSign:
        _onToggleSignPressed();
      case CalculatorActionType.percentage:
        _onPercentagePressed();
      case CalculatorActionType.calculate:
        _onCalculateResult();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (_isHistoryOpenNotifier.value &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _isHistoryOpenNotifier.value = false;
      return;
    }

    final key = event.logicalKey;

    // Special case: Shift + '=' => '+'
    if (key == LogicalKeyboardKey.equal &&
        HardwareKeyboard.instance.isShiftPressed) {
      _onOperatorPressed('+');
      return;
    }

    final action = logicalKeyboardKeyMap[key];
    if (action != null) {
      _handleButtonAction(action);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalculatorBloc, CalculatorState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty &&
            state.errorMessage == invalidOperationsErrorMessage) {
          _errorMessageNotifier.value = state.errorMessage;
        } else if (state.errorMessage.isEmpty &&
            _errorMessageNotifier.value == invalidOperationsErrorMessage) {
          _errorMessageNotifier.value = '';
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: _CalculatorAppBar(
          isHistoryOpenNotifier: _isHistoryOpenNotifier,
        ),
        body: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: BlocBuilder<CalculatorBloc, CalculatorState>(
                    buildWhen: (prev, curr) =>
                        prev.result != curr.result ||
                        prev.history != curr.history ||
                        prev.errorMessage != curr.errorMessage ||
                        prev.isCalculated != curr.isCalculated,
                    builder: (context, blocState) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _isHistoryOpenNotifier,
                        builder: (context, isHistoryOpen, _) {
                          return ValueListenableBuilder<String>(
                            valueListenable: _expressionNotifier,
                            builder: (context, expression, _) {
                              return ValueListenableBuilder<String>(
                                valueListenable: _errorMessageNotifier,
                                builder: (context, errorMessage, _) {
                                  final isOpen =
                                      isHistoryOpen &&
                                      blocState.history.isNotEmpty;
                                  final displayExpression =
                                      expression.isNotEmpty
                                      ? expression
                                      : blocState.expression;

                                  return DisplayPanel(
                                    expression: displayExpression,
                                    result: blocState.result,
                                    errorMessage: errorMessage,
                                    history: blocState.history,
                                    isHistoryOpen: isOpen,
                                    isCalculated: blocState.isCalculated,
                                    onDismissHistory: () {
                                      _isHistoryOpenNotifier.value = false;
                                    },
                                    onHistoryItemTap: (expr) {
                                      _expressionNotifier.value = expr;
                                      _errorMessageNotifier.value = '';
                                      _isHistoryOpenNotifier.value = false;
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Listener(
                    onPointerDown: (_) {
                      if (_isHistoryOpenNotifier.value) {
                        _isHistoryOpenNotifier.value = false;
                      }
                    },
                    child: ButtonGrid(onButtonPressed: _handleButtonAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ValueNotifier<bool> isHistoryOpenNotifier;

  const _CalculatorAppBar({required this.isHistoryOpenNotifier});

  @override
  Size get preferredSize => const MechanixAppBar().preferredSize;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CalculatorBloc, CalculatorState, bool>(
      selector: (state) => state.history.isNotEmpty,
      builder: (context, hasHistory) {
        return ValueListenableBuilder<bool>(
          valueListenable: isHistoryOpenNotifier,
          builder: (context, isHistoryOpen, _) {
            final isHistoryActive = isHistoryOpen && hasHistory;

            return MechanixAppBar.small(
              backgroundColor: isHistoryActive
                  ? Theme.of(context).colorScheme.surfaceContainerLow
                  : Colors.transparent,
              actions: [
                MechanixIconButton.standard(
                  key: const Key('history_button'),
                  onPressed: hasHistory
                      ? () {
                          isHistoryOpenNotifier.value =
                              !isHistoryOpenNotifier.value;
                        }
                      : null,
                  icon: Icon(isHistoryActive ? Icons.close : Icons.history),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
