import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/calc_operator.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_reader.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';
import 'package:mechanix_calculator/features/calculator/presentation/formatting/expression_renderer.dart';

void main() {
  const reader = ExpressionReader();
  const renderer = ExpressionRenderer();

  const add = OperatorInput(CalcOperator.add);
  const subtract = OperatorInput(CalcOperator.subtract);
  const multiply = OperatorInput(CalcOperator.multiply);
  const divide = OperatorInput(CalcOperator.divide);
  const power = OperatorInput(CalcOperator.power);
  const percent = PercentInput();
  const pending = NumberInput.pendingSign();
  const open = LeftParenthesisInput();
  const close = RightParenthesisInput();
  NumberInput n(String mantissa, {String power = ''}) =>
      NumberInput(mantissa, power: power);
  NumberInput neg(String mantissa, {String power = ''}) =>
      NumberInput(mantissa, power: power, negative: true);

  group('ExpressionReader.read', () {
    final cases = <String, List<InputToken>>{
      '': [],
      '5': [n('5')],
      '5.': [n('5.')],
      '0.50': [n('0.50')],
      '5+3': [n('5'), add, n('3')],
      '5-3': [n('5'), subtract, n('3')],
      '2×3÷4': [n('2'), multiply, n('3'), divide, n('4')],
      '2*3/4': [n('2'), multiply, n('3'), divide, n('4')],
      '2^10': [n('2'), power, n('10')],
      '5+': [n('5'), add],
      '50%': [n('50'), percent],
      '50%%+1': [n('50'), percent, percent, add, n('1')],
      '(-5)': [neg('5')],
      '(-5.25)': [neg('5.25')],
      '2×(-5)%': [n('2'), multiply, neg('5'), percent],
      '(-': [pending],
      '2×(-': [n('2'), multiply, pending],
      // brackets, complete or still open
      '(': [open],
      '(5)': [open, n('5'), close],
      '2×(3+4)': [n('2'), multiply, open, n('3'), add, n('4'), close],
      '2×(3+4': [n('2'), multiply, open, n('3'), add, n('4')],
      '((-': [open, pending],
      '((-5)': [open, neg('5')],
      '(-5+3)': [open, neg('5'), add, n('3'), close],
      // superscript powers
      '5²': [n('5', power: '2')],
      '5²³': [n('5', power: '23')],
      '(-5²)': [neg('5', power: '2')],
      '(2+3)²': [open, n('2'), add, n('3'), RightParenthesisInput(power: '2')],
      '9.9×10¹⁷': [n('9.9'), multiply, n('10', power: '17')],
      '1.2×10⁻⁷': [n('1.2'), multiply, n('10', power: '-7')],
      // a negative power being typed
      '5⁻': [n('5', power: '-')],
      '(2+3)⁻': [open, n('2'), add, n('3'), RightParenthesisInput(power: '-')],
      '9.9×10⁻': [n('9.9'), multiply, n('10', power: '-')],
      '9.9×10': [n('9.9'), multiply, n('10')],
      // forms from results and older versions
      '-5': [neg('5')],
      '-': [pending],
      '-9.9×10¹⁷': [neg('9.9'), multiply, n('10', power: '17')],
      '5×-3': [n('5'), multiply, neg('3')],
      '5--3': [n('5'), subtract, neg('3')],
      '(-0.': [neg('0.')],
      '(-5': [neg('5')],
      '1,234,567': [n('1234567')],
    };

    cases.forEach((text, expected) {
      test('"$text"', () => expect(reader.read(text), expected));
    });
  });

  group('rejects text that is not calculator input', () {
    for (final text in [
      '(5)6',
      '2(3)',
      '()',
      '(-)',
      ')',
      '5)',
      '(5))',
      '(-5)(-5)',
      '(-5)5',
      '5(-3)',
      '50%5',
      '+5',
      '×5',
      '^5',
      '%',
      '5++3',
      '5+%',
      '(-%',
      '²',
      '5+²',
      '.',
      ',',
      'abc',
      '5 + 3',
      '⁻',
    ]) {
      test('"$text"', () {
        expect(() => reader.read(text), throwsFormatException);
      });
    }
  });

  group('readResult', () {
    test('reads formatted results', () {
      expect(reader.readResult('42'), [n('42')]);
      expect(reader.readResult('-42'), [neg('42')]);
      expect(reader.readResult('1,234.5'), [n('1234.5')]);
      expect(reader.readResult('9.99999998×10¹⁷'), [
        n('9.99999998'),
        multiply,
        n('10', power: '17'),
      ]);
      expect(reader.readResult('-1.2×10⁻⁷'), [
        neg('1.2'),
        multiply,
        n('10', power: '-7'),
      ]);
    });

    test('returns null for anything but a finished value', () {
      for (final text in ['', '-', '(-', '5+', '(', 'Error', 'abc']) {
        expect(reader.readResult(text), isNull, reason: text);
      }
    });
  });

  group('render(read(text)) == text for rendered text', () {
    for (final text in [
      '',
      '5',
      '0.',
      '5.5+2.',
      '(-5)',
      '(-0.)',
      '(-',
      '2×(-',
      '2×(-5)%%-3÷4',
      '(',
      '((-',
      '2×((-5)+3)',
      '2^(1+2)',
      '5²×(2+3)²%',
      '(-5²)',
      '5⁻',
      '5^(-2)',
      '9.9×10¹⁷',
      '(-1.2)×10⁻⁷',
      '200+10%+',
    ]) {
      test('"$text"', () => expect(renderer.render(reader.read(text)), text));
    }
  });

  test('older forms are rendered in the current form', () {
    expect(renderer.render(reader.read('-5')), '(-5)');
    expect(renderer.render(reader.read('-')), '(-');
    expect(renderer.render(reader.read('(-0.')), '(-0.)');
    expect(renderer.render(reader.read('2*3/4')), '2×3÷4');
    expect(renderer.render(reader.read('(-9.9×10¹⁷)')), '((-9.9)×10¹⁷)');
  });
}
