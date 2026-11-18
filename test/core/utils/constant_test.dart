import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/button_grid.dart';

void main() {
  group('keyboard map', () {
    const digitRow = [
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
    const numpad = [
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

    void expectButton(
      LogicalKeyboardKey key,
      CalculatorActionType action, [
      String? value,
      bool shift = false,
      bool control = false,
    ]) {
      final button = buttonForKey(key, shift: shift, control: control);
      expect(button, isNotNull, reason: key.debugName);
      expect(button!.action, action, reason: key.debugName);
      expect(button.value, value, reason: key.debugName);
    }

    test('every digit-row and numpad digit types its digit', () {
      for (var digit = 0; digit <= 9; digit++) {
        expectButton(digitRow[digit], CalculatorActionType.number, '$digit');
        expectButton(numpad[digit], CalculatorActionType.number, '$digit');
      }
    });

    test('decimal point, operators and commands', () {
      expectButton(LogicalKeyboardKey.period, CalculatorActionType.number, '.');
      expectButton(
        LogicalKeyboardKey.numpadDecimal,
        CalculatorActionType.number,
        '.',
      );
      for (final (key, value) in [
        (LogicalKeyboardKey.add, '+'),
        (LogicalKeyboardKey.numpadAdd, '+'),
        (LogicalKeyboardKey.minus, '-'),
        (LogicalKeyboardKey.numpadSubtract, '-'),
        (LogicalKeyboardKey.asterisk, '×'),
        (LogicalKeyboardKey.numpadMultiply, '×'),
        (LogicalKeyboardKey.slash, '÷'),
        (LogicalKeyboardKey.numpadDivide, '÷'),
        (LogicalKeyboardKey.caret, '^'),
      ]) {
        expectButton(key, CalculatorActionType.operator, value);
      }
      expectButton(LogicalKeyboardKey.percent, CalculatorActionType.percentage);
      for (final key in [
        LogicalKeyboardKey.parenthesisLeft,
        LogicalKeyboardKey.numpadParenLeft,
      ]) {
        expectButton(key, CalculatorActionType.openBracket);
      }
      for (final key in [
        LogicalKeyboardKey.parenthesisRight,
        LogicalKeyboardKey.numpadParenRight,
      ]) {
        expectButton(key, CalculatorActionType.closeBracket);
      }
      for (final key in [
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.numpadEnter,
        LogicalKeyboardKey.equal,
        LogicalKeyboardKey.numpadEqual,
      ]) {
        expectButton(key, CalculatorActionType.calculate);
      }
      expectButton(LogicalKeyboardKey.backspace, CalculatorActionType.delete);
      expectButton(LogicalKeyboardKey.escape, CalculatorActionType.clear);
    });

    test('Shift+= is +, = alone calculates', () {
      expectButton(
        LogicalKeyboardKey.equal,
        CalculatorActionType.operator,
        '+',
        true,
      );
      expectButton(LogicalKeyboardKey.equal, CalculatorActionType.calculate);
    });

    test('Shift+6 is ^, Shift+9 and Shift+0 are brackets', () {
      expectButton(
        LogicalKeyboardKey.digit6,
        CalculatorActionType.operator,
        '^',
        true,
      );
      expectButton(
        LogicalKeyboardKey.digit9,
        CalculatorActionType.openBracket,
        null,
        true,
      );
      expectButton(
        LogicalKeyboardKey.digit0,
        CalculatorActionType.closeBracket,
        null,
        true,
      );
    });

    test('Ctrl+digit types a superscript digit, row and numpad', () {
      for (var digit = 0; digit <= 9; digit++) {
        for (final key in [digitRow[digit], numpad[digit]]) {
          expectButton(
            key,
            CalculatorActionType.superscript,
            '$digit',
            false,
            true,
          );
          expectButton(
            key,
            CalculatorActionType.superscript,
            '$digit',
            true,
            true,
          );
        }
      }
    });

    test('Ctrl+- starts a negative superscript power', () {
      for (final key in [
        LogicalKeyboardKey.minus,
        LogicalKeyboardKey.numpadSubtract,
      ]) {
        expectButton(key, CalculatorActionType.superscript, '-', false, true);
      }
    });

    test('other Ctrl combinations are ignored', () {
      for (final key in [
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.equal,
        LogicalKeyboardKey.add,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.backspace,
      ]) {
        expect(buttonForKey(key, control: true), isNull, reason: key.debugName);
      }
    });

    test('Alt and Meta combinations are ignored', () {
      for (final key in [
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.numpad5,
        LogicalKeyboardKey.add,
        LogicalKeyboardKey.enter,
      ]) {
        expect(buttonForKey(key, alt: true), isNull, reason: key.debugName);
        expect(buttonForKey(key, meta: true), isNull, reason: key.debugName);
      }
    });

    test(
      'Shift falls back to the plain key when it has no shifted meaning',
      () {
        expectButton(
          LogicalKeyboardKey.digit5,
          CalculatorActionType.number,
          '5',
          true,
        );
        expectButton(
          LogicalKeyboardKey.percent,
          CalculatorActionType.percentage,
          null,
          true,
        );
      },
    );

    test('other keys are ignored', () {
      for (final key in [
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyZ,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.f1,
        LogicalKeyboardKey.arrowLeft,
      ]) {
        expect(buttonForKey(key, shift: false), isNull, reason: key.debugName);
        expect(buttonForKey(key, shift: true), isNull, reason: key.debugName);
      }
    });
  });
}
