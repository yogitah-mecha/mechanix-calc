import 'package:flutter/services.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/button_grid.dart';

const _digitRowKeys = [
  LogicalKeyboardKey.digit0,
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

const _numpadDigitKeys = [
  LogicalKeyboardKey.numpad0,
  LogicalKeyboardKey.numpad1,
  LogicalKeyboardKey.numpad2,
  LogicalKeyboardKey.numpad3,
  LogicalKeyboardKey.numpad4,
  LogicalKeyboardKey.numpad5,
  LogicalKeyboardKey.numpad6,
  LogicalKeyboardKey.numpad7,
  LogicalKeyboardKey.numpad8,
  LogicalKeyboardKey.numpad9,
];

CalculatorButtonData _digit(int digit) =>
    CalculatorButtonData(action: CalculatorActionType.number, value: '$digit');

CalculatorButtonData _superscript(String char) =>
    CalculatorButtonData(action: CalculatorActionType.superscript, value: char);

const _operator = CalculatorActionType.operator;

/// Hardware keys and the button each one presses.
final Map<LogicalKeyboardKey, CalculatorButtonData> logicalKeyboardKeyMap = {
  for (var digit = 0; digit <= 9; digit++) ...{
    _digitRowKeys[digit]: _digit(digit),
    _numpadDigitKeys[digit]: _digit(digit),
  },

  LogicalKeyboardKey.period: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '.',
  ),
  LogicalKeyboardKey.numpadDecimal: const CalculatorButtonData(
    action: CalculatorActionType.number,
    value: '.',
  ),

  LogicalKeyboardKey.add: const CalculatorButtonData(
    action: _operator,
    value: '+',
  ),
  LogicalKeyboardKey.numpadAdd: const CalculatorButtonData(
    action: _operator,
    value: '+',
  ),
  LogicalKeyboardKey.minus: const CalculatorButtonData(
    action: _operator,
    value: '-',
  ),
  LogicalKeyboardKey.numpadSubtract: const CalculatorButtonData(
    action: _operator,
    value: '-',
  ),
  LogicalKeyboardKey.asterisk: const CalculatorButtonData(
    action: _operator,
    value: '×',
  ),
  LogicalKeyboardKey.numpadMultiply: const CalculatorButtonData(
    action: _operator,
    value: '×',
  ),
  LogicalKeyboardKey.slash: const CalculatorButtonData(
    action: _operator,
    value: '÷',
  ),
  LogicalKeyboardKey.numpadDivide: const CalculatorButtonData(
    action: _operator,
    value: '÷',
  ),
  LogicalKeyboardKey.caret: const CalculatorButtonData(
    action: _operator,
    value: '^',
  ),

  LogicalKeyboardKey.parenthesisLeft: const CalculatorButtonData(
    action: CalculatorActionType.openBracket,
  ),
  LogicalKeyboardKey.numpadParenLeft: const CalculatorButtonData(
    action: CalculatorActionType.openBracket,
  ),
  LogicalKeyboardKey.parenthesisRight: const CalculatorButtonData(
    action: CalculatorActionType.closeBracket,
  ),
  LogicalKeyboardKey.numpadParenRight: const CalculatorButtonData(
    action: CalculatorActionType.closeBracket,
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

/// Keys pressed with Shift, looked up before [logicalKeyboardKeyMap].
///
/// For keys whose logical key does not change with Shift (US layout):
/// Shift+= is `+`, Shift+6 is `^`, Shift+9 and Shift+0 are brackets. Keys
/// whose logical key does change (Shift+5 arrives as `percent`) are in
/// [logicalKeyboardKeyMap] already.
final Map<LogicalKeyboardKey, CalculatorButtonData> shiftedKeyboardKeyMap = {
  LogicalKeyboardKey.equal: const CalculatorButtonData(
    action: _operator,
    value: '+',
  ),
  LogicalKeyboardKey.digit6: const CalculatorButtonData(
    action: _operator,
    value: '^',
  ),
  LogicalKeyboardKey.digit9: const CalculatorButtonData(
    action: CalculatorActionType.openBracket,
  ),
  LogicalKeyboardKey.digit0: const CalculatorButtonData(
    action: CalculatorActionType.closeBracket,
  ),
};

/// Keys pressed with Ctrl: digits type a superscript power (`5` then Ctrl+2
/// gives `5²`) and `-` starts a negative one (`5⁻²`), as in GNOME
/// Calculator. Other Ctrl combinations are ignored.
final Map<LogicalKeyboardKey, CalculatorButtonData> controlKeyboardKeyMap = {
  for (var digit = 0; digit <= 9; digit++) ...{
    _digitRowKeys[digit]: _superscript('$digit'),
    _numpadDigitKeys[digit]: _superscript('$digit'),
  },
  LogicalKeyboardKey.minus: _superscript('-'),
  LogicalKeyboardKey.numpadSubtract: _superscript('-'),
};

/// The button a key press means, or null for keys the calculator ignores.
///
/// Ctrl uses only [controlKeyboardKeyMap]; Alt and Meta combinations are
/// shortcuts for the system, never input.
CalculatorButtonData? buttonForKey(
  LogicalKeyboardKey key, {
  bool shift = false,
  bool control = false,
  bool alt = false,
  bool meta = false,
}) {
  if (alt || meta) return null;
  if (control) return controlKeyboardKeyMap[key];
  return (shift ? shiftedKeyboardKeyMap[key] : null) ??
      logicalKeyboardKeyMap[key];
}

// Limits themselves: InputLimits (domain/input/input_limits.dart).
const String maxDigitsErrorMessage = "Can't enter more than 15 digits";
const String maxCharactersErrorMessage = "Can't enter more than 100 characters";
const String maxOperationsErrorMessage = "Can't enter more than 20 operations";

const String invalidOperationsErrorMessage = "Error";
