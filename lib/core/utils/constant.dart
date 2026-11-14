import 'package:flutter/services.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/button_grid.dart';

final Map<LogicalKeyboardKey, CalculatorButtonData> logicalKeyboardKeyMap = {
  LogicalKeyboardKey.digit0: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '0',
  ),
  LogicalKeyboardKey.numpad0: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '0',
  ),
  LogicalKeyboardKey.digit1: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '1',
  ),
  LogicalKeyboardKey.numpad1: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '1',
  ),
  LogicalKeyboardKey.digit2: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '2',
  ),
  LogicalKeyboardKey.numpad2: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '2',
  ),
  LogicalKeyboardKey.digit3: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '3',
  ),
  LogicalKeyboardKey.numpad3: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '3',
  ),
  LogicalKeyboardKey.digit4: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '4',
  ),
  LogicalKeyboardKey.numpad4: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '4',
  ),
  LogicalKeyboardKey.digit5: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '5',
  ),
  LogicalKeyboardKey.numpad5: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '5',
  ),
  LogicalKeyboardKey.digit6: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '6',
  ),
  LogicalKeyboardKey.numpad6: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '6',
  ),
  LogicalKeyboardKey.digit7: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '7',
  ),
  LogicalKeyboardKey.numpad7: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '7',
  ),
  LogicalKeyboardKey.digit8: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '8',
  ),
  LogicalKeyboardKey.numpad8: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '8',
  ),
  LogicalKeyboardKey.digit9: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '9',
  ),
  LogicalKeyboardKey.numpad9: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '9',
  ),

  LogicalKeyboardKey.period: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '.',
  ),
  LogicalKeyboardKey.numpadDecimal: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '.',
  ),

  LogicalKeyboardKey.add: const CalculatorButtonData(
    action: CalculatorActionType.operator,
    value: '+',
  ),
  LogicalKeyboardKey.numpadAdd: const CalculatorButtonData(
    action: CalculatorActionType.operator,
    value: '+',
  ),

  LogicalKeyboardKey.minus: const CalculatorButtonData(
    action: CalculatorActionType.operator,
    value: '-',
  ),
  LogicalKeyboardKey.numpadSubtract: const CalculatorButtonData(
    action: CalculatorActionType.operator,
    value: '-',
  ),

  LogicalKeyboardKey.asterisk: const CalculatorButtonData(
    action: CalculatorActionType.operator,
    value: '×',
  ),
  LogicalKeyboardKey.numpadMultiply: const CalculatorButtonData(
    action: CalculatorActionType.operator,
    value: '×',
  ),

  LogicalKeyboardKey.slash: const CalculatorButtonData(
    action: CalculatorActionType.operator,
    value: '÷',
  ),
  LogicalKeyboardKey.numpadDivide: const CalculatorButtonData(
    action: CalculatorActionType.operator,
    value: '÷',
  ),

  LogicalKeyboardKey.percent: const CalculatorButtonData(
    action: CalculatorActionType.percentage,
  ),

  LogicalKeyboardKey.enter: const CalculatorButtonData(
    action: CalculatorActionType.calculate,
  ),
  LogicalKeyboardKey.numpadEnter: const CalculatorButtonData(
    action: CalculatorActionType.calculate,
  ),
  LogicalKeyboardKey.equal: const CalculatorButtonData(
    action: CalculatorActionType.calculate,
  ),
  LogicalKeyboardKey.numpadEqual: const CalculatorButtonData(
    action: CalculatorActionType.calculate,
  ),

  LogicalKeyboardKey.backspace: const CalculatorButtonData(
    action: CalculatorActionType.delete,
  ),
  LogicalKeyboardKey.escape: const CalculatorButtonData(
    action: CalculatorActionType.clear,
  ),
};

const int maxCharacters = 100;
const int maxOperations = 20;
const int maxDigits = 15;

const String maxDigitsErrorMessage = "Can't enter more than 15 digits";
const String maxCharactersErrorMessage = "Can't enter more than 100 characters";
const String maxOperationsErrorMessage = "Can't enter more than 20 operations";

const String invalidOperationsErrorMessage = "Error";

const operationCharacters = {'+', '×', '÷', '%', '*', '/'};
