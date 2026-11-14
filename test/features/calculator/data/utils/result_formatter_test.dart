import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/result_formatter.dart';

void main() {
  group('ResultFormatter.format', () {
    var cases = <double, String>{
      0: '0',
      3000: '3,000',
      0.30000000000000004: '0.3',
      99998900001: '99,998,900,001',
      123456789012345: '123,456,789,012,345',
      999999999999999: '999,999,999,999,999',
      1e15: '1×10¹⁵',
      999999998000000000: '9.99999998×10¹⁷',
      1152921504606846976: '1.152921505×10¹⁸',
      -1152921504606846976: '-1.152921505×10¹⁸',
      0.0000001234: '1.234×10⁻⁷',
    };

    cases.forEach((value, expected) {
      test('$value -> $expected', () {
        expect(ResultFormatter.format(value), expected);
      });
    });
  });

  group('ResultFormatter.toEvaluable', () {
    test('converts superscript exponents', () {
      expect(
        ResultFormatter.toEvaluable('9.99999998×10¹⁷+1'),
        '9.99999998*10^(17)+1',
      );
      expect(ResultFormatter.toEvaluable('1.234×10⁻⁷'), '1.234*10^(-7)');
    });

    test('leaves normal multiplication alone', () {
      expect(ResultFormatter.toEvaluable('5×10'), '5×10');
    });
  });
}
