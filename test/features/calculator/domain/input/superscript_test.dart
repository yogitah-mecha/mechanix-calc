import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/superscript.dart';

void main() {
  group('Superscript', () {
    test('fromPlain', () {
      expect(Superscript.fromPlain(''), '');
      expect(Superscript.fromPlain('0'), '⁰');
      expect(Superscript.fromPlain('17'), '¹⁷');
      expect(Superscript.fromPlain('-7'), '⁻⁷');
      expect(Superscript.fromPlain('1234567890'), '¹²³⁴⁵⁶⁷⁸⁹⁰');
    });

    test('toPlain is the inverse and keeps other characters', () {
      for (final text in ['0', '7', '17', '-7', '-20', '308', '-324']) {
        expect(Superscript.toPlain(Superscript.fromPlain(text)), text);
      }
      expect(Superscript.toPlain('9.9×10¹⁷'), '9.9×1017');
    });

    test('chars covers every character fromPlain writes', () {
      for (final char in Superscript.fromPlain('-1234567890').split('')) {
        expect(Superscript.chars, contains(char));
      }
    });

    group('powerPattern', () {
      final pattern = Superscript.powerPattern;

      test('matches a power with at least one digit', () {
        expect(pattern.firstMatch('5²')![0], '²');
        expect(pattern.firstMatch('9.9×10¹⁷')![0], '¹⁷');
        expect(pattern.firstMatch('1.2×10⁻⁷')![0], '⁻⁷');
      });

      test('does not match a lone minus or plain digits', () {
        expect(pattern.hasMatch('⁻'), isFalse);
        expect(pattern.hasMatch('9.9×10'), isFalse);
      });
    });
  });
}
