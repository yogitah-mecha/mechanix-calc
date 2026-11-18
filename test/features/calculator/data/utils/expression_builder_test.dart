import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/expression_builder.dart';

/// String-level tests of the adapter the screen uses. Token-level rules are
/// in test/features/calculator/domain/input/expression_editor_test.dart.
void main() {
  group('ExpressionBuilder', () {
    group('Number handling', () {
      test('typing digit on empty expression returns the digit', () {
        final res = ExpressionBuilder.handleNumber('', '5');
        expect(res.expression, '5');
        expect(res.errorMessage, '');
      });

      test('typing non-zero replaces existing standalone 0', () {
        final res = ExpressionBuilder.handleNumber('0', '7');
        expect(res.expression, '7');
        expect(res.errorMessage, '');
      });

      test('decimal on empty expression produces 0.', () {
        final res = ExpressionBuilder.handleNumber('', '.');
        expect(res.expression, '0.');
        expect(res.errorMessage, '');
      });

      test('decimal when expression is 0 produces 0.', () {
        final res = ExpressionBuilder.handleNumber('0', '.');
        expect(res.expression, '0.');
        expect(res.errorMessage, '');
      });

      test('decimal when number has no decimal appends dot', () {
        final res = ExpressionBuilder.handleNumber('5', '.');
        expect(res.expression, '5.');
        expect(res.errorMessage, '');
      });

      test('decimal ignored if current segment already has decimal', () {
        final res = ExpressionBuilder.handleNumber('5.5', '.');
        expect(res.expression, '5.5');
        expect(res.errorMessage, '');
      });

      test('decimal allowed in second segment after operator', () {
        final res = ExpressionBuilder.handleNumber('5.5+2', '.');
        expect(res.expression, '5.5+2.');
        expect(res.errorMessage, '');
      });

      test('decimal after negative sign starts negative decimal', () {
        final res = ExpressionBuilder.handleNumber('(-', '.');

        expect(res.expression, '(-0.)');
        expect(res.errorMessage, '');
      });

      test('decimal inside parenthesized negative number is appended', () {
        final res = ExpressionBuilder.handleNumber('(-5)', '.');

        expect(res.expression, '(-5.)');
        expect(res.errorMessage, '');
      });

      test('decimal after operator produces 0.', () {
        final res = ExpressionBuilder.handleNumber('5+', '.');

        expect(res.expression, '5+0.');
        expect(res.errorMessage, '');
      });

      test('digit after negative sign closes parenthesized number', () {
        final res = ExpressionBuilder.handleNumber('(-', '5');

        expect(res.expression, '(-5)');
        expect(res.errorMessage, '');
      });

      test('digit inside parenthesized negative number is appended', () {
        final res = ExpressionBuilder.handleNumber('(-5)', '6');

        expect(res.expression, '(-56)');
        expect(res.errorMessage, '');
      });

      test('digit replaces zero inside parenthesized negative number', () {
        final res = ExpressionBuilder.handleNumber('(-0)', '5');

        expect(res.expression, '(-5)');
        expect(res.errorMessage, '');
      });

      test('text that is not calculator input is left unchanged', () {
        final res = ExpressionBuilder.handleNumber('2(3)', '6');

        expect(res.expression, '2(3)');
        expect(res.errorMessage, '');
      });

      test('digit after ) starts a multiplied number', () {
        expect(ExpressionBuilder.handleNumber('(5)', '6').expression, '(5)×6');
      });

      test('digit after % starts a multiplied number', () {
        expect(
          ExpressionBuilder.handleNumber('15×10%', '1').expression,
          '15×10%×1',
        );
      });

      test('a typed leading - is shown bracketed once a digit follows', () {
        expect(ExpressionBuilder.handleNumber('-', '5').expression, '(-5)');
      });
    });

    group('Operator handling', () {
      test('first pressed minus on empty expression sets negative sign', () {
        final res = ExpressionBuilder.handleOperator('', '-');
        expect(res.expression, '(-');
        expect(res.errorMessage, '');
      });

      test('consecutive operators replace the last operator', () {
        var res = ExpressionBuilder.handleOperator('9+', '-');
        expect(res.expression, '9-');

        res = ExpressionBuilder.handleOperator('9-', '×');
        expect(res.expression, '9×');

        res = ExpressionBuilder.handleOperator('9×', '÷');
        expect(res.expression, '9÷');
      });

      test('appends operator to previous result when expression is empty', () {
        final res = ExpressionBuilder.handleOperator(
          '',
          '+',
          previousResult: '42',
        );
        expect(res.expression, '42+');
        expect(res.errorMessage, '');
      });

      test(
        'operator on empty expression without previous result does nothing',
        () {
          final res = ExpressionBuilder.handleOperator('', '+');

          expect(res.expression, '');
          expect(res.errorMessage, '');
        },
      );

      test('minus on empty expression starts negative expression', () {
        final res = ExpressionBuilder.handleOperator('', '-');

        expect(res.expression, '(-');
      });

      test('operator after incomplete negative expression clears it', () {
        var res = ExpressionBuilder.handleOperator('(-', '+');
        expect(res.expression, '');

        res = ExpressionBuilder.handleOperator('-', '+');
        expect(res.expression, '');
      });

      test(
        'operator after incomplete negative number replaces trailing operator',
        () {
          final res = ExpressionBuilder.handleOperator('5+(-', '×');

          expect(res.expression, '5×');
          expect(res.errorMessage, '');
        },
      );

      test('operator after previous negative result wraps result', () {
        final res = ExpressionBuilder.handleOperator(
          '',
          '+',
          previousResult: '-42',
        );

        expect(res.expression, '(-42)+');
        expect(res.errorMessage, '');
      });

      test(
        'operator with empty expression and empty previous result does nothing',
        () {
          final res = ExpressionBuilder.handleOperator(
            '',
            '+',
            previousResult: '',
          );

          expect(res.expression, '');
        },
      );
    });

    group('Delete, Clear, Sign toggle, Percentage', () {
      test('handleDelete removes last character', () {
        final res = ExpressionBuilder.handleDelete('123');
        expect(res.expression, '12');
      });

      test('handleDelete on empty returns empty', () {
        final res = ExpressionBuilder.handleDelete('');
        expect(res.expression, '');
      });

      test('handleDelete removes digit from parenthesized negative number', () {
        var res = ExpressionBuilder.handleDelete('(-56)');
        expect(res.expression, '(-5)');

        res = ExpressionBuilder.handleDelete('(-5)');
        expect(res.expression, '');
      });

      test('handleDelete removes incomplete negative sign', () {
        final res = ExpressionBuilder.handleDelete('5×(-');

        expect(res.expression, '5×');
      });

      test('handleDelete removes last character from normal expression', () {
        final res = ExpressionBuilder.handleDelete('5+12');

        expect(res.expression, '5+1');
      });
      test('handleClear returns empty', () {
        final res = ExpressionBuilder.handleClear();
        expect(res.expression, '');
      });

      test(
        'handleToggleSign adds and removes negative sign on simple number',
        () {
          var res = ExpressionBuilder.handleToggleSign('42');
          expect(res.expression, '(-42)');

          res = ExpressionBuilder.handleToggleSign('(-42)');
          expect(res.expression, '42');
        },
      );

      test(
        'handleToggleSign toggles sign of current added number in multi-number expression',
        () {
          // e.g. 2×2 -> 2×(-2)
          var res = ExpressionBuilder.handleToggleSign('2×2');
          expect(res.expression, '2×(-2)');

          // 2×(-2) -> 2×2
          res = ExpressionBuilder.handleToggleSign('2×(-2)');
          expect(res.expression, '2×2');

          // (-2)×2 -> (-2)×(-2)
          res = ExpressionBuilder.handleToggleSign('(-2)×2');
          expect(res.expression, '(-2)×(-2)');

          // (-2)×(-2) -> (-2)×2
          res = ExpressionBuilder.handleToggleSign('(-2)×(-2)');
          expect(res.expression, '(-2)×2');

          // 5+3 -> 5+(-3)
          res = ExpressionBuilder.handleToggleSign('5+3');
          expect(res.expression, '5+(-3)');

          // 5+(-3) -> 5+3
          res = ExpressionBuilder.handleToggleSign('5+(-3)');
          expect(res.expression, '5+3');

          // 5-3 -> 5-(-3)
          res = ExpressionBuilder.handleToggleSign('5-3');
          expect(res.expression, '5-(-3)');

          // 5-(-3) -> 5-3
          res = ExpressionBuilder.handleToggleSign('5-(-3)');
          expect(res.expression, '5-3');
        },
      );

      test(
        'handleToggleSign after operator toggles trailing negative sign',
        () {
          // 2× -> 2×(-
          var res = ExpressionBuilder.handleToggleSign('2×');
          expect(res.expression, '2×(-');

          // 2×(- -> 2×
          res = ExpressionBuilder.handleToggleSign('2×(-');
          expect(res.expression, '2×');
        },
      );

      test('handleToggleSign on empty expression starts negative number', () {
        final res = ExpressionBuilder.handleToggleSign('');

        expect(res.expression, '(-');
      });

      test('handleToggleSign removes incomplete negative sign', () {
        var res = ExpressionBuilder.handleToggleSign('(-');
        expect(res.expression, '');

        res = ExpressionBuilder.handleToggleSign('-');
        expect(res.expression, '');
      });

      test(
        'handleToggleSign removes incomplete parenthesized negative sign',
        () {
          final res = ExpressionBuilder.handleToggleSign('5×(-');

          expect(res.expression, '5×');
        },
      );

      test('handleToggleSign toggles standalone negative number', () {
        final res = ExpressionBuilder.handleToggleSign('-5');

        expect(res.expression, '5');
      });

      test('handleToggleSign adds parentheses to decimal number', () {
        final res = ExpressionBuilder.handleToggleSign('5.25');

        expect(res.expression, '(-5.25)');
      });

      test('handleToggleSign toggles negative decimal number', () {
        final res = ExpressionBuilder.handleToggleSign('(-5.25)');

        expect(res.expression, '5.25');
      });

      test('handlePercentage appends % after a bracketed number', () {
        expect(ExpressionBuilder.handlePercentage('(-5)').expression, '(-5)%');
      });

      test('handlePercentage appends %', () {
        final res = ExpressionBuilder.handlePercentage('50');
        expect(res.expression, '50%');
      });

      test('operator after % keeps the % and appends the operator', () {
        expect(
          ExpressionBuilder.handleOperator('200+10%', '+').expression,
          '200+10%+',
        );
        expect(ExpressionBuilder.handleOperator('50%', '×').expression, '50%×');
      });

      test('operator after a normal operator still replaces it', () {
        expect(
          ExpressionBuilder.handleOperator('200+', '-').expression,
          '200-',
        );
      });
    });

    group('Limits validation', () {
      test('blocks exceeding 15 digits in a number segment', () {
        final res15 = ExpressionBuilder.handleNumber('11111111111111', '1');
        expect(res15.expression, '111111111111111');
        expect(res15.errorMessage, '');

        final res16 = ExpressionBuilder.handleNumber('111111111111111', '1');
        expect(res16.expression, '111111111111111');
        expect(res16.errorMessage, maxDigitsErrorMessage);
      });

      test('blocks exceeding 20 operations', () {
        String expr = '';
        for (int i = 0; i < 20; i++) {
          expr = ExpressionBuilder.handleNumber(expr, '1').expression;
          final res = ExpressionBuilder.handleOperator(expr, '+');
          expect(res.errorMessage, '');
          expr = res.expression;
        }

        expr = ExpressionBuilder.handleNumber(expr, '1').expression;
        final resOver = ExpressionBuilder.handleOperator(expr, '+');
        expect(resOver.errorMessage, maxOperationsErrorMessage);
        expect(resOver.expression, expr);
      });

      test('blocks exceeding 100 characters', () {
        final expr100 = '1' * 100;
        final res = ExpressionBuilder.handleNumber(expr100, '2');
        expect(res.errorMessage, maxCharactersErrorMessage);
      });
    });

    group('scientific results', () {
      test('operator after a scientific result is appended', () {
        expect(
          ExpressionBuilder.handleOperator(
            '',
            '+',
            previousResult: '9.99999998×10¹⁷',
          ).expression,
          '9.99999998×10¹⁷+',
        );
      });

      test('digits cannot be typed straight after a power', () {
        expect(
          ExpressionBuilder.handleNumber('9.99999998×10¹⁷', '5').expression,
          '9.99999998×10¹⁷',
        );
      });

      test('+/- negates a previous result', () {
        for (final (result, expected) in [
          ('8', '(-8)'),
          ('9.9×10¹⁷', '(-9.9)×10¹⁷'),
          ('-9.9×10¹⁷', '9.9×10¹⁷'),
        ]) {
          expect(
            ExpressionBuilder.handleToggleSign(
              '',
              previousResult: result,
            ).expression,
            expected,
            reason: result,
          );
        }
      });

      test('+/- on typed input flips the last number', () {
        expect(
          ExpressionBuilder.handleToggleSign('9.9×10¹⁷').expression,
          '9.9×(-10¹⁷)',
        );
        expect(
          ExpressionBuilder.handleToggleSign('9.9×(-10¹⁷)').expression,
          '9.9×10¹⁷',
        );
      });

      List<String> backspaceSteps(String expression) {
        final steps = [expression];
        while (steps.last.isNotEmpty) {
          steps.add(ExpressionBuilder.handleDelete(steps.last).expression);
        }
        return steps;
      }

      test('backspace removes power digits one by one, then the rest', () {
        expect(backspaceSteps('9.9×10¹⁷'), [
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

      test('backspace drops a lone power sign', () {
        expect(ExpressionBuilder.handleDelete('1.2×10⁻⁷').expression, '1.2×10');
      });

      test('% cannot follow a power', () {
        expect(
          ExpressionBuilder.handlePercentage('9.9×10¹⁷').expression,
          '9.9×10¹⁷',
        );
      });

      test('older "(-9.9×10¹⁷)" text is read as a bracket and takes %', () {
        expect(
          ExpressionBuilder.handlePercentage('(-9.9×10¹⁷)').expression,
          '((-9.9)×10¹⁷)%',
        );
      });
    });

    group('brackets, ^ and superscript powers', () {
      test('( and ) with the multiplication written out', () {
        var expression = '2';
        expression = ExpressionBuilder.handleOpenBracket(expression).expression;
        expect(expression, '2×(');
        expression = ExpressionBuilder.handleNumber(expression, '3').expression;
        expression = ExpressionBuilder.handleOperator(
          expression,
          '+',
        ).expression;
        expression = ExpressionBuilder.handleNumber(expression, '4').expression;
        expression = ExpressionBuilder.handleCloseBracket(
          expression,
        ).expression;
        expect(expression, '2×(3+4)');
        expect(
          ExpressionBuilder.handleCloseBracket(expression).expression,
          '2×(3+4)',
        );
      });

      test('= closes open brackets', () {
        expect(ExpressionBuilder.closeBrackets('2×(3+(4'), '2×(3+(4))');
        expect(ExpressionBuilder.closeBrackets('5+'), '5+');
      });

      test('^ is an operator', () {
        expect(ExpressionBuilder.handleOperator('2', '^').expression, '2^');
        expect(ExpressionBuilder.handleOperator('2^', '+').expression, '2+');
      });

      test('superscript digits build a power', () {
        var expression = '5';
        for (final digit in ['1', '0']) {
          expression = ExpressionBuilder.handleSuperscript(
            expression,
            digit,
          ).expression;
        }
        expect(expression, '5¹⁰');
        expect(ExpressionBuilder.handleSuperscript('5+', '2').expression, '5+');
        expect(
          ExpressionBuilder.handleSuperscript('(2+3)', '2').expression,
          '(2+3)²',
        );
      });
    });
  });
}
