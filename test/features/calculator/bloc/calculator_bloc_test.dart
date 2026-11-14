import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_bloc.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_event.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_state.dart';

void main() {
  group('CalculatorBloc', () {
    late CalculatorBloc calculatorBloc;

    setUp(() {
      calculatorBloc = CalculatorBloc();
    });

    tearDown(() {
      calculatorBloc.close();
    });

    test('initial state should be empty expression and result 0', () {
      expect(
        calculatorBloc.state,
        const CalculatorState(expression: '', result: '0', history: []),
      );
    });

    test('CalculateResult performs addition correctly', () {
      final expectedStates = [
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '5+3')
            .having((s) => s.result, 'result', '8')
            .having((s) => s.history.length, 'history length', 1)
            .having((s) => s.history.first.expression, 'history expr', '5+3')
            .having((s) => s.history.first.result, 'history result', '8'),
      ];

      expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

      calculatorBloc.add(const CalculateResult('5+3'));
    });

    test('ClearPressed should NOT clear history', () async {
      final expectedStates = [
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '5+3')
            .having((s) => s.result, 'result', '8')
            .having((s) => s.history.length, 'history length', 1),
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '')
            .having((s) => s.result, 'result', '0')
            .having((s) => s.history.length, 'history length', 1),
      ];

      expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

      // 1. Calculate something to add to history
      calculatorBloc.add(const CalculateResult('5+3'));

      // 2. Clear current calculation
      calculatorBloc.add(const ClearPressed());
    });

    test('Multiple calculations should be added to history in LIFO order', () {
      final expectedStates = [
        isA<CalculatorState>()
            .having((s) => s.result, 'result', '8')
            .having((s) => s.history.length, 'history length', 1),
        isA<CalculatorState>()
            .having((s) => s.result, 'result', '25')
            .having((s) => s.history.length, 'history length', 2)
            .having((s) => s.history.first.expression, 'history expr', '15+10')
            .having((s) => s.history.first.result, 'history result', '25'),
      ];

      expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

      // 1. First calculation
      calculatorBloc.add(const CalculateResult('5+3'));

      // 2. Second calculation
      calculatorBloc.add(const CalculateResult('15+10'));
    });

    test('Division by zero should show error message', () {
      final expectedStates = [
        const CalculatorState(
          expression: '5÷0',
          result: '',
          errorMessage: invalidOperationsErrorMessage,
          history: [],
        ),
        const CalculatorState(
          expression: '',
          result: '0',
          errorMessage: '',
          history: [],
        ),
      ];

      expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

      calculatorBloc.add(const CalculateResult('5÷0'));

      // Clear the error and state
      calculatorBloc.add(const ClearPressed());
    });

    test('Malformed expression should show error message', () {
      final expectedStates = [
        const CalculatorState(
          expression: '5+',
          result: '',
          errorMessage: invalidOperationsErrorMessage,
          history: [],
        ),
        const CalculatorState(
          expression: '',
          result: '0',
          errorMessage: '',
          history: [],
        ),
      ];

      expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

      calculatorBloc.add(const CalculateResult('5+'));

      // Pressing AC should clear error message
      calculatorBloc.add(const ClearPressed());
    });

    test(
      'Multiplying a negative result by zero should yield 0 instead of -0',
      () {
        final expectedStates = [
          // 1. First calculation: 10 - 20 = -10
          isA<CalculatorState>()
              .having((s) => s.result, 'result', '-10')
              .having((s) => s.history.length, 'history length', 1),

          // 2. Second calculation: -10 × 0 = 0
          isA<CalculatorState>()
              .having((s) => s.result, 'result', '0')
              .having((s) => s.history.length, 'history length', 2)
              .having((s) => s.history.first.expression, 'history expr', '-10×0')
              .having((s) => s.history.first.result, 'history result', '0'),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        // Execute sequence for '10-20'
        calculatorBloc.add(const CalculateResult('10-20'));

        // Execute sequence for '-10×0'
        calculatorBloc.add(const CalculateResult('-10×0'));
      },
    );

    test('calculates expression with percentage correctly', () {
      final expectedStates = [
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '200×50%')
            .having((s) => s.result, 'result', '100')
            .having((s) => s.history.length, 'history length', 1),
      ];

      expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

      calculatorBloc.add(const CalculateResult('200×50%'));
    });

    group('percentage after + / - is relative to the left operand', () {
      const cases = {
        '200+10%': '220',
        '200-10%': '180',
        '100+10%+10%': '121',
        '2×3+10%': '6.6',
        '(200+10%)×2': '440',
        '(-5)+10%': '-5.5',
        '50%': '0.5',
        '200÷50%': '400',
      };

      cases.forEach((expression, expected) {
        test('$expression = $expected', () async {
          final expectation = expectLater(
            calculatorBloc.stream,
            emits(
              isA<CalculatorState>().having(
                (s) => s.result,
                'result',
                expected,
              ),
            ),
          );
          calculatorBloc.add(CalculateResult(expression));
          await expectation;
        });
      });
    });

    group('CalculateResult edge cases', () {
      test('does nothing when expression is empty', () {
        calculatorBloc.add(const CalculateResult(''));
        expect(calculatorBloc.state.expression, '');
        expect(calculatorBloc.state.result, '0');
      });

      test('formats large whole numbers with comma separators', () {
        final expectedStates = [
          isA<CalculatorState>()
              .having((s) => s.expression, 'expression', '1000+2000')
              .having((s) => s.result, 'result', '3,000')
              .having((s) => s.history.first.result, 'history result', '3,000'),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const CalculateResult('1000+2000'));
      });

      test('calculates expressions with negative operands without brackets correctly', () {
        final expectedStates = [
          // 1. -2×-2 = 4
          isA<CalculatorState>()
              .having((s) => s.result, 'result', '4')
              .having((s) => s.history.first.expression, 'expr', '-2×-2')
              .having((s) => s.history.first.result, 'result', '4'),
          // 2. 5+-3 = 2
          isA<CalculatorState>()
              .having((s) => s.result, 'result', '2')
              .having((s) => s.history.first.expression, 'expr', '5+-3')
              .having((s) => s.history.first.result, 'result', '2'),
          // 3. 10--20 = 30
          isA<CalculatorState>()
              .having((s) => s.result, 'result', '30')
              .having((s) => s.history.first.expression, 'expr', '10--20')
              .having((s) => s.history.first.result, 'result', '30'),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const CalculateResult('-2×-2'));
        calculatorBloc.add(const CalculateResult('5+-3'));
        calculatorBloc.add(const CalculateResult('10--20'));
      });

      test('calculates expressions with parenthesized negative operands correctly', () {
        final expectedStates = [
          // 1. (-5)×(-5) = 25
          isA<CalculatorState>()
              .having((s) => s.result, 'result', '25')
              .having((s) => s.history.first.expression, 'expr', '(-5)×(-5)')
              .having((s) => s.history.first.result, 'result', '25'),
          // 2. (-2)×(-2) = 4
          isA<CalculatorState>()
              .having((s) => s.result, 'result', '4')
              .having((s) => s.history.first.expression, 'expr', '(-2)×(-2)')
              .having((s) => s.history.first.result, 'result', '4'),
          // 3. 5+(-3) = 2
          isA<CalculatorState>()
              .having((s) => s.result, 'result', '2')
              .having((s) => s.history.first.expression, 'expr', '5+(-3)')
              .having((s) => s.history.first.result, 'result', '2'),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const CalculateResult('(-5)×(-5)'));
        calculatorBloc.add(const CalculateResult('(-2)×(-2)'));
        calculatorBloc.add(const CalculateResult('5+(-3)'));
      });
    });

    group('large and small results', () {
      const cases = {
        '999999999×999999999': '9.99999998×10¹⁷',
        '99999×999999': '99,998,900,001',
        '9.99999998×10¹⁷+1': '9.99999998×10¹⁷',
        '(-9.99999998×10¹⁷)÷2': '-4.99999999×10¹⁷',
        '1÷100000000': '1×10⁻⁸',
      };

      cases.forEach((expression, expected) {
        test('$expression = $expected', () async {
          final expectation = expectLater(
            calculatorBloc.stream,
            emits(
              isA<CalculatorState>()
                  .having((s) => s.result, 'result', expected)
                  .having(
                    (s) => s.history.first.result,
                    'history result',
                    expected,
                  ),
            ),
          );
          calculatorBloc.add(CalculateResult(expression));
          await expectation;
        });
      });
    });
  });
}
