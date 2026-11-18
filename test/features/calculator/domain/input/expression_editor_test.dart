import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/domain/engine/calc_engine.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/calc_operator.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_editor.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_reader.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';
import 'package:mechanix_calculator/features/calculator/presentation/formatting/expression_renderer.dart';

/// Cases are written as display text for readability: the start text is read
/// into tokens, one edit is applied, and the tokens are rendered back.
void main() {
  const editor = ExpressionEditor(renderer: ExpressionRenderer());
  const reader = ExpressionReader();
  const renderer = ExpressionRenderer();

  String render(List<InputToken> tokens) => renderer.render(tokens);
  List<InputToken> read(String text) => reader.read(text);

  void table(
    String description,
    Map<String, String> cases,
    EditResult Function(List<InputToken>) edit,
  ) {
    group(description, () {
      cases.forEach((start, expected) {
        test('"$start" -> "$expected"', () {
          final result = edit(read(start));
          expect(result.error, isNull);
          expect(render(result.tokens), expected);
        });
      });
    });
  }

  table('digit 5', {
    '': '5',
    '0': '5',
    '1': '15',
    '10': '105',
    '0.': '0.5',
    '0.0': '0.05',
    '5+': '5+5',
    '5+0': '5+5',
    '2^': '2^5',
    '5^(-': '5^(-5)',
    '(': '(5',
    '2×(': '2×(5',
    '(-': '(-5)',
    '(-0)': '(-5)',
    '(-1)': '(-15)',
    '(-1.)': '(-1.5)',
    '2×(-': '2×(-5)',
    '((-': '((-5)',
    // ignored straight after a superscript power
    '5²': '5²',
    '9.9×10¹⁷': '9.9×10¹⁷',
    '(-5²)': '(-5²)',
    '(2+3)²': '(2+3)²',
    // after % or ) a new number is multiplied (as Google's calculator)
    '50%': '50%×5',
    '2+50%%': '2+50%%×5',
    '15×10%': '15×10%×5',
    '(2+3)': '(2+3)×5',
  }, (tokens) => editor.appendDigit(tokens, '5'));

  table('digit 0', {
    '': '0',
    '0': '0',
    '0.': '0.0',
    '5': '50',
  }, (tokens) => editor.appendDigit(tokens, '0'));

  table('decimal point', {
    '': '0.',
    '0': '0.',
    '5': '5.',
    '5.': '5.',
    '5.5': '5.5',
    '5.5+2': '5.5+2.',
    '5+': '5+0.',
    '(': '(0.',
    '(-': '(-0.)',
    '(-5)': '(-5.)',
    '(-5.)': '(-5.)',
    '5²': '5²',
    '9.9×10¹⁷': '9.9×10¹⁷',
    '50%': '50%×0.',
    '(2)': '(2)×0.',
  }, editor.appendDecimalPoint);

  group('operator', () {
    table('+', {
      '': '',
      '5': '5+',
      '5.': '5.+',
      '(-5)': '(-5)+',
      '5-': '5+',
      '5×': '5+',
      '5^': '5+',
      '50%': '50%+',
      '200+10%': '200+10%+',
      '9.9×10¹⁷': '9.9×10¹⁷+',
      '5²': '5²+',
      '(2+3)': '(2+3)+',
      '(2+3': '(2+3+',
      // nothing to apply it to after (
      '(': '(',
      '2×(': '2×(',
      // cancels a pending sign, then replaces the operator before it
      '(-': '',
      '5×(-': '5+',
      '((-': '(',
    }, (tokens) => editor.appendOperator(tokens, CalcOperator.add));

    table('-', {
      '': '(-',
      '5': '5-',
      '(': '((-',
      // replaces + and -
      '5+': '5-',
      '5-': '5-',
      // after ×, ÷ and ^ it starts a negative operand
      '5×': '5×(-',
      '5÷': '5÷(-',
      '5^': '5^(-',
      '(2+3)^': '(2+3)^(-',
      // a second - cancels the pending sign and replaces the operator
      '(-': '',
      '5×(-': '5-',
    }, (tokens) => editor.appendOperator(tokens, CalcOperator.subtract));

    table('operators wait for an unfinished power (only ⁻)', {
      '5⁻': '5⁻',
      '(2+3)⁻': '(2+3)⁻',
    }, (tokens) => editor.appendOperator(tokens, CalcOperator.add));

    table('^', {
      '': '',
      '2': '2^',
      '2+': '2^',
      '(2+3)': '(2+3)^',
      '5²': '5²^',
      '50%': '50%^',
      '(': '(',
    }, (tokens) => editor.appendOperator(tokens, CalcOperator.power));

    table('× and ÷ replace each other', {
      '9×': '9÷',
      '9-': '9÷',
    }, (tokens) => editor.appendOperator(tokens, CalcOperator.divide));

    test('continues the previous result when the input is empty', () {
      for (final (result, expected) in [
        ('42', '42+'),
        ('-42', '(-42)+'),
        ('9.99999998×10¹⁷', '9.99999998×10¹⁷+'),
        ('-1.2×10⁻⁷', '(-1.2)×10⁻⁷+'),
        ('0', '0+'),
      ]) {
        final edit = editor.appendOperator(
          const [],
          CalcOperator.add,
          previousResult: reader.readResult(result),
        );
        expect(render(edit.tokens), expected, reason: result);
      }
    });

    test('previous result is ignored when input is not empty', () {
      final edit = editor.appendOperator(
        read('5'),
        CalcOperator.add,
        previousResult: read('42'),
      );
      expect(render(edit.tokens), '5+');
    });

    test('minus on empty input starts a negative number, not the result', () {
      final edit = editor.appendOperator(
        const [],
        CalcOperator.subtract,
        previousResult: read('42'),
      );
      expect(render(edit.tokens), '(-');
    });
  });

  table('open bracket', {
    '': '(',
    '(': '((',
    '5+': '5+(',
    '2^': '2^(',
    // after a value the multiplication is written out
    '2': '2×(',
    '(-5)': '(-5)×(',
    '(2+3)': '(2+3)×(',
    '5²': '5²×(',
    '50%': '50%×(',
    // a pending sign takes a number, not a bracket
    '(-': '(-',
  }, editor.appendOpenBracket);

  table('close bracket', {
    '(5': '(5)',
    '(2+3': '(2+3)',
    '((2+3)': '((2+3))',
    '(5%': '(5%)',
    '(5²': '(5²)',
    '((-5)': '((-5))',
    '2×(3+(4': '2×(3+(4)',
    // nothing to close, or the bracket would be empty or end in an operator
    '': '',
    '5': '5',
    '(5)': '(5)',
    '(': '(',
    '(5+': '(5+',
    '((-': '((-',
  }, editor.appendCloseBracket);

  group('superscript (Ctrl+digit)', () {
    table('2', {
      '5': '5²',
      '5²': '5²²',
      '5.': '5.²',
      '10': '10²',
      '(-5)': '(-5²)',
      '(2+3)': '(2+3)²',
      '(2+3)²': '(2+3)²²',
      '9.9×10¹': '9.9×10¹²',
      '2+5': '2+5²',
      // no number or ) to raise
      '': '',
      '5+': '5+',
      '(': '(',
      '(-': '(-',
      '50%': '50%',
    }, (tokens) => editor.appendSuperscript(tokens, '2'));

    table('-', {
      '5': '5⁻',
      '(2+3)': '(2+3)⁻',
      '(-5)': '(-5⁻)',
      // only as the first character of the power
      '5²': '5²',
      '5⁻': '5⁻',
      '5⁻²': '5⁻²',
      // no number or ) to raise
      '': '',
      '5+': '5+',
      '(-': '(-',
    }, (tokens) => editor.appendSuperscript(tokens, '-'));

    table('2 after ⁻', {
      '5⁻': '5⁻²',
      '(2+3)⁻': '(2+3)⁻²',
    }, (tokens) => editor.appendSuperscript(tokens, '2'));

    group('an unfinished power (only ⁻) takes nothing else', () {
      for (final (name, edit)
          in <(String, EditResult Function(List<InputToken>))>[
            ('digit', (t) => editor.appendDigit(t, '5')),
            ('.', editor.appendDecimalPoint),
            ('(', editor.appendOpenBracket),
            (')', editor.appendCloseBracket),
            ('%', editor.appendPercent),
            ('×', (t) => editor.appendOperator(t, CalcOperator.multiply)),
          ]) {
        test(name, () {
          for (final start in ['5⁻', '(5⁻', '(2+3)⁻']) {
            expect(render(edit(read(start)).tokens), start, reason: start);
          }
        });
      }

      test('backspace removes the ⁻', () {
        expect(render(editor.backspace(read('5⁻'))), '5');
      });

      test('= leaves it for the engine to report', () {
        expect(render(editor.closeBrackets(read('(5⁻'))), '(5⁻');
        expect(editor.endsWithValue(read('5⁻')), isFalse);
      });
    });

    test('Ctrl+0 then digits builds a multi-digit power', () {
      var tokens = read('2');
      for (final digit in ['1', '0']) {
        tokens = editor.appendSuperscript(tokens, digit).tokens;
      }
      expect(render(tokens), '2¹⁰');
    });
  });

  table('toggle sign', {
    '': '(-',
    '(-': '',
    '2×': '2×(-',
    '2×(-': '2×',
    '(': '((-',
    '2^': '2^(-',
    '42': '(-42)',
    '(-42)': '42',
    '5.25': '(-5.25)',
    '(-5.25)': '5.25',
    '0.': '(-0.)',
    '2×2': '2×(-2)',
    '2×(-2)': '2×2',
    '(-2)×2': '(-2)×(-2)',
    '5+3': '5+(-3)',
    '5-3': '5-(-3)',
    '5-(-3)': '5-3',
    '5²': '(-5²)',
    '9.9×10¹⁷': '9.9×(-10¹⁷)',
    // flips the number the percent applies to
    '50%': '(-50)%',
    '(-50)%': '50%',
    '2+50%%': '2+(-50)%%',
    // a bracket's sign is not toggled
    '(2+3)': '(2+3)',
    '(2+3)%': '(2+3)%',
  }, editor.toggleSign);

  group('negate a previous result', () {
    for (final (result, expected) in [
      ('8', '(-8)'),
      ('-8', '8'),
      ('9.9×10¹⁷', '(-9.9)×10¹⁷'),
      ('-9.9×10¹⁷', '9.9×10¹⁷'),
      ('1.2×10⁻⁷', '(-1.2)×10⁻⁷'),
    ]) {
      test('"$result" -> "$expected"', () {
        final edit = editor.negateResult(reader.readResult(result)!);
        expect(render(edit.tokens), expected);
      });
    }
  });

  table('percent', {
    '': '',
    '50': '50%',
    '50.': '50.%',
    '(-5)': '(-5)%',
    '50%': '50%%',
    '(2+3)': '(2+3)%',
    // not straight after a superscript power
    '5²': '5²',
    '9.9×10¹⁷': '9.9×10¹⁷',
    '(2+3)²': '(2+3)²',
    // no value to apply to
    '5+': '5+',
    '(': '(',
    '(-': '(-',
    '5×(-': '5×(-',
  }, editor.appendPercent);

  group('backspace', () {
    final cases = {
      '': '',
      '123': '12',
      '5+12': '5+1',
      '5+': '5',
      '50%': '50',
      '50%%': '50%',
      '5.': '5',
      '0.': '0',
      '(-56)': '(-5)',
      '(-5.)': '(-5)',
      '(-5)': '',
      '2×(-5)': '2×',
      '(-': '',
      '5×(-': '5×',
      '(': '',
      '2×(': '2×',
      '(2+3)': '(2+3',
      // power digits first
      '5²³': '5²',
      '5²': '5',
      '(-5²)': '(-5)',
      '(2+3)²': '(2+3)',
      '1.2×10⁻⁷': '1.2×10',
      '1.2×10⁻¹⁷': '1.2×10⁻¹',
    };
    cases.forEach((start, expected) {
      test('"$start" -> "$expected"', () {
        expect(render(editor.backspace(read(start))), expected);
      });
    });

    List<String> steps(String start) {
      final result = [start];
      var tokens = read(start);
      while (tokens.isNotEmpty) {
        tokens = editor.backspace(tokens);
        result.add(render(tokens));
      }
      return result;
    }

    test('a scientific result to empty, one character at a time', () {
      expect(steps('9.9×10¹⁷'), [
        '9.9×10¹⁷',
        '9.9×10¹',
        '9.9×10',
        '9.9×1',
        '9.9×',
        '9.9',
        '9.',
        '9',
        '',
      ]);
    });

    test('a negated power keeps its brackets', () {
      expect(steps('2×(-10¹⁷)'), [
        '2×(-10¹⁷)',
        '2×(-10¹)',
        '2×(-10)',
        '2×(-1)',
        '2×',
        '2',
        '',
      ]);
    });
  });

  group('close brackets on =', () {
    final cases = {
      '': '',
      '5': '5',
      '(5': '(5)',
      '2×(3+(4': '2×(3+(4))',
      '(5)%': '(5)%',
      '((-5)': '((-5))',
      '(5²': '(5²)',
      // unfinished input is left for the engine to report
      '(5+': '(5+',
      '(': '(',
      '((-': '((-',
    };
    cases.forEach((start, expected) {
      test('"$start" -> "$expected"', () {
        expect(render(editor.closeBrackets(read(start))), expected);
      });
    });
  });

  group('limits', () {
    test('15 digits are allowed, the 16th is refused', () {
      final fifteen = editor.appendDigit(read('1' * 14), '1');
      expect(fifteen.error, isNull);
      expect(render(fifteen.tokens), '1' * 15);

      final sixteen = editor.appendDigit(fifteen.tokens, '1');
      expect(sixteen.error, InputLimitError.maxDigits);
      expect(sixteen.tokens, fifteen.tokens);
    });

    test('the decimal point and the power do not count as digits', () {
      expect(editor.appendDecimalPoint(read('1' * 15)).error, isNull);
      expect(editor.appendSuperscript(read('1' * 15), '9').error, isNull);
    });

    test('digit limit applies per number', () {
      expect(editor.appendDigit(read('${'1' * 15}+'), '1').error, isNull);
      expect(
        editor.appendDigit(read('(-${'1' * 15})'), '1').error,
        InputLimitError.maxDigits,
      );
    });

    test('20 operations are allowed, the 21st is refused', () {
      var tokens = <InputToken>[];
      for (var i = 0; i < 20; i++) {
        tokens = editor.appendDigit(tokens, '1').tokens;
        tokens = editor.appendOperator(tokens, CalcOperator.add).tokens;
      }
      expect(editor.countOperations(tokens), 20);

      tokens = editor.appendDigit(tokens, '1').tokens;
      for (final over in [
        editor.appendOperator(tokens, CalcOperator.add),
        editor.appendPercent(tokens),
        editor.appendSuperscript(tokens, '2'),
        editor.appendOpenBracket(tokens), // adds ×
      ]) {
        expect(over.error, InputLimitError.maxOperations);
        expect(over.tokens, tokens);
      }
    });

    test('replacing an operator does not count as a new operation', () {
      final tokens = read('${'1+' * 19}1×');
      expect(editor.countOperations(tokens), 20);
      expect(editor.appendOperator(tokens, CalcOperator.add).error, isNull);
    });

    test('a number started after % or ) counts the × it adds', () {
      final tokens = read('${'1+' * 19}50%');
      expect(editor.countOperations(tokens), 20);
      expect(
        editor.appendDigit(tokens, '5').error,
        InputLimitError.maxOperations,
      );
    });

    test('operations: operators, percents and powers count', () {
      expect(editor.countOperations(read('')), 0);
      expect(editor.countOperations(read('(-5)')), 0);
      expect(editor.countOperations(read('(5)')), 0);
      expect(editor.countOperations(read('5²')), 1);
      expect(editor.countOperations(read('5²³')), 1);
      expect(editor.countOperations(read('(2+3)²')), 2);
      expect(editor.countOperations(read('2^3')), 1);
      expect(editor.countOperations(read('9.9×10¹⁷')), 2);
      expect(editor.countOperations(read('5×10')), 1);
      expect(editor.countOperations(read('5-(-3)')), 1);
      expect(editor.countOperations(read('200+10%%')), 3);
    });

    test('more than 100 characters is refused', () {
      const custom = ExpressionEditor(
        renderer: ExpressionRenderer(),
        limits: InputLimits(maxDigits: 200),
      );
      final tokens = read('1' * 100);
      final over = custom.appendDigit(tokens, '2');
      expect(over.error, InputLimitError.maxCharacters);
      expect(over.tokens, tokens);
    });

    test('characters are checked before operations and digits', () {
      expect(
        editor.appendDigit(read('1' * 100), '2').error,
        InputLimitError.maxCharacters,
      );
    });

    test('toggling a sign can hit the character limit', () {
      const custom = ExpressionEditor(
        renderer: ExpressionRenderer(),
        limits: InputLimits(maxCharacters: 5),
      );
      expect(custom.toggleSign(read('12')).error, isNull); // "(-12)": 5
      expect(
        custom.toggleSign(read('123')).error,
        InputLimitError.maxCharacters,
      );
    });
  });

  group('any key sequence (seeded random walk)', () {
    final engine = CalcEngine();
    final previousResult = reader.readResult('9.9×10¹⁷');
    final actions = <String, EditResult Function(List<InputToken>)>{
      for (final digit in '0123456789'.split(''))
        digit: (t) => editor.appendDigit(t, digit),
      '.': editor.appendDecimalPoint,
      for (final operator in CalcOperator.values)
        operator.displaySymbol: (t) =>
            editor.appendOperator(t, operator, previousResult: previousResult),
      '(': editor.appendOpenBracket,
      ')': editor.appendCloseBracket,
      for (final char in ['0', '2', '7', '-'])
        'Ctrl+$char': (t) => editor.appendSuperscript(t, char),
      '±': editor.toggleSign,
      '%': editor.appendPercent,
      '⌫': (t) => EditResult(editor.backspace(t)),
    };
    final keys = actions.keys.toList();

    for (var seed = 0; seed < 50; seed++) {
      test('seed $seed', () {
        final random = Random(seed);
        var tokens = <InputToken>[];
        final pressed = <String>[];

        for (var step = 0; step < 200; step++) {
          final key = keys[random.nextInt(keys.length)];
          pressed.add(key);
          tokens = actions[key]!(tokens).tokens;
          final text = render(tokens);
          final reason = 'keys: ${pressed.join(' ')} -> "$text"';

          // The display text reads back into the same tokens.
          expect(read(text), tokens, reason: reason);
          // Limits are never exceeded.
          expect(editor.checkLimits(tokens), isNull, reason: reason);
          // Input ending in a value always evaluates once its brackets are
          // closed (the result may be NaN or infinite).
          if (editor.endsWithValue(tokens)) {
            final closed = editor.closeBrackets(tokens);
            expect(
              () => engine.evaluate(closed),
              returnsNormally,
              reason: '$reason, evaluated "${render(closed)}"',
            );
          }
        }
      });
    }
  });
}
