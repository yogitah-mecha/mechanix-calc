import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/calc_serializer.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_reader.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';

/// Cases are written as display text and read into tokens first.
void main() {
  const reader = ExpressionReader();
  const serializer = CalcSerializer();

  SerializedExpression serialize(String input) =>
      serializer.serialize(reader.read(input));

  group('CalcSerializer source', () {
    final cases = <String, String>{
      '': '',
      '7': 'n0',
      '3+5': 'n0+n1',
      '2×3÷4': 'n0*n1/n2',
      '2*3/4': 'n0*n1/n2',
      '5-3': 'n0-n1',
      '2^10': 'n0^n1',
      // negative numbers
      '(-5)': '(-n0)',
      '2×(-5)': 'n0*(-n1)',
      '5-(-3)': 'n0-(-n1)',
      '-5+2': '(-n0)+n1',
      // superscript powers bind to their number, inside its sign
      '5²': '(n0^n1)',
      '(-5²)': '(-(n0^n1))',
      '10⁻⁷': '(n0^n1)',
      '9.9×10¹⁷': 'n0*(n1^n2)',
      '(2+3)²': '(n0+n1)^n2',
      // brackets
      '(2+3)×4': '(n0+n1)*n2',
      '2×((-5)+3)': 'n0*((-n1)+n2)',
      // percent wraps the value directly on its left
      '10%': 'pct(n0)',
      '200+10%': 'n0+pct(n1)',
      '200×50%+10%': 'n0*pct(n1)+pct(n2)',
      '5%%': 'pct(pct(n0))',
      '(-5)%': 'pct((-n0))',
      '2×(-5)%': 'n0*pct((-n1))',
      '(2+3)%': 'pct((n0+n1))',
      '((2+3))%': 'pct(((n0+n1)))',
      '50%×5': 'pct(n0)*n1',
      // incomplete input passes through; the parser rejects it
      '5×': 'n0*',
      '(5+3': '(n0+n1',
    };

    cases.forEach((input, expected) {
      test('"$input" -> "$expected"', () {
        expect(serialize(input).source, expected);
      });
    });
  });

  group('binds each number and power to its own variable, in order', () {
    test('mantissa before its power', () {
      expect(serialize('9.9×10¹⁷+0.5×.5').variables, {
        'n0': 9.9,
        'n1': 10.0,
        'n2': 17.0,
        'n3': 0.5,
        'n4': 0.5,
      });
    });

    test('typed forms are normalized', () {
      expect(serialize('5.+.5+1,000').variables, {
        'n0': 5.0,
        'n1': 0.5,
        'n2': 1000.0,
      });
    });

    test('negative and leading-zero powers', () {
      expect(serialize('10⁻⁷').variables, {'n0': 10.0, 'n1': -7.0});
      expect(serialize('5⁰⁴⁵').variables, {'n0': 5.0, 'n1': 45.0});
      expect(serialize('(2+3)⁻²').variables, {
        'n0': 2.0,
        'n1': 3.0,
        'n2': -2.0,
      });
    });
  });

  group('rejects unfinished input', () {
    for (final input in ['(-', '2×(-', '5⁻', '(2+3)⁻', '((-']) {
      test('"$input"', () {
        expect(() => serialize(input), throwsFormatException);
      });
    }

    test('a percent with no value before it', () {
      expect(
        () => serializer.serialize(const [PercentInput()]),
        throwsFormatException,
      );
    });
  });
}
