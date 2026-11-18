import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/domain/engine/calc_engine.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_reader.dart';

/// Cases are written as display text and read into tokens first, the way
/// the Bloc evaluates the screen's expression and history entries.
void main() {
  final engine = CalcEngine();
  const reader = ExpressionReader();

  double evaluate(String text) => engine.evaluate(reader.read(text));

  void expectValue(String expression, double expected) {
    test('$expression = $expected', () {
      expect(
        evaluate(expression),
        closeTo(expected, expected.abs() * 1e-12 + 1e-12),
      );
    });
  }

  group('CalcEngine', () {
    group('arithmetic', () {
      expectValue('7', 7);
      expectValue('3+5', 8);
      expectValue('5-8', -3);
      expectValue('2×3÷4', 1.5);
      expectValue('2*3/4', 1.5);
      expectValue('7÷2', 3.5);
      expectValue('0÷5', 0);
      expectValue('0.1+0.2', 0.3);
      expectValue('4×.2', 0.8);
      expectValue('5.+1', 6);
      expectValue('.5+.5', 1);
      expectValue('1,000+2', 1002);
      expectValue('1,234,567×2', 2469134);
    });

    group('precedence', () {
      expectValue('2+3×4', 14);
      expectValue('2×3+4', 10);
      expectValue('2+3×4-5', 9);
      expectValue('1-2×3÷4', -0.5);
      expectValue('10-6÷3', 8);
    });

    group('left associativity', () {
      expectValue('8÷4÷2', 1);
      expectValue('10-3-2', 5);
      expectValue('100÷10×2', 20);
      expectValue('2×3÷6×4', 4);
    });

    group('brackets', () {
      expectValue('(2+3)×4', 20);
      expectValue('2×(3+4)', 14);
      expectValue('((2+3))×4', 20);
      expectValue('(((1+1)×(2+2))÷(4))', 2);
    });

    group('powers', () {
      expectValue('2^10', 1024);
      expectValue('5²', 25);
      expectValue('2¹⁰', 1024);
      expectValue('10⁻²', 0.01);
      expectValue('5⁻²', 0.04);
      expectValue('5^(-2)', 0.04);
      expectValue('(2+3)⁻¹', 0.2);
      expectValue('5×(-2)', -10);
      expectValue('6÷(-2)', -3);
      expectValue('2^(-1)', 0.5);
      expectValue('2^0.5', 1.4142135623730951);
      expectValue('4^0.5×3', 6);
      // right associative, above × and unary minus
      expectValue('2^3^2', 512);
      expectValue('2×3^2', 18);
      // A typed leading - belongs to the number, as the display shows it:
      // "-2^2" is read as (-2)^2.
      expectValue('-2^2', 4);
      expectValue('(-2²)', -4);
      expectValue('(-2)^2', 4);
      expectValue('(-5²)', -25);
      expectValue('(2+3)²', 25);
      expectValue('(2+3)^2×2', 50);
      expectValue('2^(1+2)', 8);
      expectValue('3²+4²', 25);
    });

    group('negative base', () {
      expectValue('(-2)^3', -8);
      expectValue('(-2)^(-1)', -0.5);
      expectValue('(-2)^(4÷2)', 4);
      // Regression: math_expressions' own rewrite of x^(a/b) for a negative
      // x recursed until the stack overflowed (random-walk seeds 12, 43).
      expectValue('(-1)^(1÷1)', -1);
      expectValue('(-8)^(3÷1)', -512);

      test('a non-integer power of a negative base is undefined (NaN)', () {
        for (final input in ['(-8)^(1÷3)', '(-84)^7%', '(-2)^0.5']) {
          expect(evaluate(input), isNaN, reason: input);
        }
      });

      test('0^0 is undefined (NaN)', () {
        expect(evaluate('0^0'), isNaN);
      });

      test('the random-walk expressions that overflowed now evaluate', () {
        for (final input in [
          '(-1)^(1÷1)',
          '8013%×9÷9⁰⁷⁰²^(-2)-(-2)%×(-84)^7%',
        ]) {
          expect(() => evaluate(input), returnsNormally, reason: input);
        }
      });
    });

    group('brackets with powers and percent', () {
      expectValue('(200+10%)^2', 48400);
      expectValue('200+(10%)', 220);
      expectValue('2×(3+4)', 14);
      expectValue('((2))', 2);
    });

    group('negative numbers', () {
      expectValue('(-2)×(-2)', 4);
      expectValue('5-(-3)', 8);
      expectValue('10÷(-2)', -5);
      expectValue('-5+2', -3);
      expectValue('-5×2', -10);
      expectValue('5×-3', -15);
      expectValue('5--3', 8);
      expectValue('5-(-5)', 10);
      expectValue('(-5)×(-5)', 25);
      expectValue('(-0)', 0);
    });

    group('percent', () {
      // Full table in percent_resolver_test.dart.
      expectValue('200+10%', 220);
      expectValue('200×50%', 100);
      expectValue('(-5)%', -0.05);
    });

    group('scientific numbers', () {
      expectValue('9.99999998×10¹⁷+1', 9.99999998e17 + 1);
      expectValue('(-9.9×10¹⁷)÷2', -4.95e17);
      expectValue('(-9.9×10¹⁷)%', -9.9e15);
      expectValue('1.2×10⁻⁷×2', 2.4e-7);
      expectValue('1×10¹⁵-1', 999999999999999);
      // After backspacing the exponent away it is a plain multiplication.
      expectValue('9.9×10', 99);
    });

    group('large and small values', () {
      expectValue('999999999999999+1', 1e15);
      expectValue('999999999999999×999999999999999', 9.99999999999998e29);
      expectValue('0.000001÷1000', 1e-9);
    });

    test('chained percentages stay exact', () {
      expect(
        evaluate('1${'+1%' * 10}'),
        closeTo(1.1046221254112045, 1e-12),
      );
    });

    test('maximum-length chain (20 operations) evaluates', () {
      expect(evaluate('1${'+1' * 20}'), 21);
    });

    group('undefined and overflowing results (shown as Error)', () {
      test('division by zero is NaN', () {
        expect(evaluate('5÷0'), isNaN);
      });

      test('zero divided by zero is NaN', () {
        expect(evaluate('0÷0'), isNaN);
      });

      test('division by a zero-valued expression is NaN', () {
        expect(evaluate('5÷(2-2)'), isNaN);
      });

      test('overflow is infinity', () {
        expect(evaluate('9.9×10³⁰⁷×100'), double.infinity);
        expect(evaluate('(-9.9×10³⁰⁷)×100'), double.negativeInfinity);
      });
    });

    group('malformed input throws FormatException', () {
      for (final expression in [
        '',
        '5×',
        '5+',
        '5++5',
        '5+%',
        '%',
        '×5',
        '((5)',
        '5)',
        '()',
        '(-)',
        '(-5)5',
        '5(',
        '.',
        '5..5',
        '9.9×10⁻',
        'abc',
        '5 5',
        '2^',
        '^2',
        '2^^2',
        '²',
        '5+²',
        '5⁻',
        '(5⁻)',
        '(-',
        '--5',
      ]) {
        test('"$expression"', () {
          expect(() => evaluate(expression), throwsFormatException);
        });
      }
    });

    test('is reusable across evaluations', () {
      expect(evaluate('2+2'), 4);
      expect(evaluate('200+10%'), closeTo(220, 1e-9));
      expect(evaluate('2+2'), 4);
    });
  });
}
