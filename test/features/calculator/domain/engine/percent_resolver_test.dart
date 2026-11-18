import 'package:flutter_test/flutter_test.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:mechanix_calculator/features/calculator/domain/engine/calc_engine.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_reader.dart';

void main() {
  final engine = CalcEngine();

  const reader = ExpressionReader();

  Expression ast(String input) => engine.parse(reader.read(input)).ast;

  double value(String input) => engine.evaluate(reader.read(input));

  void expectValue(String input, double expected) {
    test('$input = $expected', () {
      expect(value(input), closeTo(expected, expected.abs() * 1e-12 + 1e-12));
    });
  }

  group('AST shape after resolving', () {
    test('plain percent becomes a division by 100', () {
      final node = ast('50%');
      expect(node, isA<Divide>());
      expect((node as Divide).second, isA<Number>());
    });

    test('a ± p% becomes a ± a×(p/100)', () {
      for (final input in ['200+10%', '200-10%']) {
        final node = ast(input) as BinaryOperator;
        expect(node.second, isA<Times>(), reason: input);
        expect((node.second as Times).second, isA<Divide>(), reason: input);
      }
    });

    test('percent inside a product on the right keeps the product', () {
      final node = ast('200+10%×2') as Plus;
      expect(node.second, isA<Times>());
      expect((node.second as Times).first, isA<Times>()); // 200×(10/100)
    });

    test('no pct function node is left anywhere in the tree', () {
      for (final input in [
        '10%',
        '200+10%',
        '100+10%+10%',
        '200+10%×2',
        '(200+10%)×2',
        '(-5)%+10%',
        '5%%',
        '200-(-5)%',
        '2×(-5)%',
        '200÷50%',
      ]) {
        expect(ast(input).toString(), isNot(contains('pct')), reason: input);
      }
    });

    test('expressions without percent are unchanged in meaning', () {
      expect(ast('2+3×4').toString(), isNot(contains('pct')));
      expect(value('2+3×4'), 14);
    });
  });

  group('percent after + or - is relative to the left value', () {
    expectValue('200+10%', 220);
    expectValue('200-10%', 180);
    expectValue('100+10%+10%', 121);
    expectValue('100-10%-10%', 81);
    expectValue('2×3+10%', 6.6);
    expectValue('100+50+10%', 165);
    expectValue('200+10%×2', 240);
    expectValue('200+10%÷2', 210);
    expectValue('(200+10%)×2', 440);
    expectValue('(-5)+10%', -5.5);
    expectValue('200×50%+10%', 110);
    expectValue('50%+10%', 0.55);
    expectValue('200+-10%', 180);
    expectValue('200-(-10)%', 220);
  });

  group('other percentages divide by 100', () {
    expectValue('50%', 0.5);
    expectValue('200×50%', 100);
    expectValue('200÷50%', 400);
    expectValue('200+5×10%', 200.5);
    expectValue('10%×10%', 0.01);
  });

  group('percent and powers', () {
    expectValue('(200+10%)^2', 48400);
    expectValue('10%^2', 0.01);
    expectValue('200+10%^2', 200.01);
    expectValue('2^50%', 1.4142135623730951);
  });

  group('repeated percent: only the outermost % takes the left value', () {
    expectValue('5%%', 0.0005);
    expectValue('200+10%%', 200.2);
  });

  group('percent after brackets', () {
    expectValue('(-5)%', -0.05);
    expectValue('2×(-5)%', -0.1);
    expectValue('200+(-5)%', 190);
    expectValue('200-(-5)%', 210);
    expectValue('(-5)%+10%', -0.055);
  });
}
