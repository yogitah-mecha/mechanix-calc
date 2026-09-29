import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_bloc.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_event.dart';
import 'package:mechanix_calculator/features/calculator/presentation/screens/calculator_screen.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/button_grid.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/display_panel.dart';
import 'package:widgets/widgets.dart';

void main() {
  group('CalculatorScreen', () {
    late CalculatorBloc bloc;

    setUp(() {
      bloc = CalculatorBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    Widget createScreen() {
      return MaterialApp(
        home: BlocProvider<CalculatorBloc>.value(
          value: bloc,
          child: const CalculatorScreen(),
        ),
      );
    }

    Future<void> performCalculation(
      WidgetTester tester, {
      required String firstNumber,
      required String operator,
      required String secondNumber,
    }) async {
      bloc.add(CalculateResult('$firstNumber$operator$secondNumber'));
      await tester.pumpAndSettle();
    }

    Finder getHistoryButton() {
      return find.byKey(const Key('history_button'));
    }

    testWidgets('renders all initial UI components properly', (tester) async {
      await tester.pumpWidget(createScreen());

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(MechanixAppBar), findsOneWidget);
      expect(find.byType(DisplayPanel), findsOneWidget);
      expect(find.byType(ButtonGrid), findsOneWidget);
      expect(find.byType(KeyboardListener), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('History button is disabled when history is empty', (
      tester,
    ) async {
      await tester.pumpWidget(createScreen());

      expect(bloc.state.history, isEmpty);

      final historyButton = getHistoryButton();
      expect(historyButton, findsOneWidget);

      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byType(HistoryOverlay), findsNothing);
    });

    testWidgets('History button open history', (tester) async {
      await tester.pumpWidget(createScreen());

      await performCalculation(
        tester,
        firstNumber: '5',
        operator: '+',
        secondNumber: '3',
      );

      expect(bloc.state.history, isNotEmpty);

      // Open history.
      await tester.tap(getHistoryButton());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('Tapping on DisplayPanel dismisses history when open', (
      tester,
    ) async {
      await tester.pumpWidget(createScreen());

      await performCalculation(
        tester,
        firstNumber: '10',
        operator: '×',
        secondNumber: '2',
      );

      // Open history
      await tester.tap(getHistoryButton());
      await tester.pumpAndSettle();

      // Tap on the DisplayPanel area
      final displayPanel = find.byType(DisplayPanel);
      await tester.tap(displayPanel);
      await tester.pumpAndSettle();

      // History should be dismissed
      expect(find.byType(HistoryOverlay), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('PointerDown on ButtonGrid closes open history', (
      tester,
    ) async {
      await tester.pumpWidget(createScreen());

      await performCalculation(
        tester,
        firstNumber: '4',
        operator: '+',
        secondNumber: '6',
      );

      // Open history
      await tester.tap(getHistoryButton());
      await tester.pumpAndSettle();

      // Pointer down on ButtonGrid
      final buttonGrid = find.byType(ButtonGrid);
      await tester.tapAt(tester.getCenter(buttonGrid));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryOverlay), findsNothing);
    });

    testWidgets(
      'ButtonGrid PointerDown when history is closed does not error',
      (tester) async {
        await tester.pumpWidget(createScreen());

        final buttonGrid = find.byType(ButtonGrid);
        await tester.tapAt(tester.getCenter(buttonGrid));
        await tester.pumpAndSettle();

        expect(find.byType(HistoryOverlay), findsNothing);
      },
    );

    group('Keyboard shortcuts and events', () {
      testWidgets('handles KeyDown for digits and operators', (tester) async {
        await tester.pumpWidget(createScreen());

        // Press '5'
        await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
        await tester.pumpAndSettle();
        expect(find.text('5').first, findsOneWidget);

        // Press '+'
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.equal);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(find.text('5+').first, findsOneWidget);

        // Press '3'
        await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
        await tester.pumpAndSettle();
        expect(find.text('5+3').first, findsOneWidget);

        // Press Enter
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(bloc.state.result, '8');
      });

      testWidgets('handles backspace key', (tester) async {
        await tester.pumpWidget(createScreen());

        await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
        await tester.pumpAndSettle();
        expect(find.text('98').first, findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pumpAndSettle();
        expect(find.text('9').first, findsOneWidget);
      });

      testWidgets('Escape key closes history when open', (tester) async {
        await tester.pumpWidget(createScreen());

        await performCalculation(
          tester,
          firstNumber: '2',
          operator: '+',
          secondNumber: '2',
        );

        // Open history
        await tester.tap(getHistoryButton());
        await tester.pumpAndSettle();

        // Send Escape key
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(HistoryOverlay), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
      });

      testWidgets('Escape key clears calculation when history is closed', (
        tester,
      ) async {
        await tester.pumpWidget(createScreen());

        await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
        await tester.pumpAndSettle();
        expect(find.text('7').first, findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('0').first, findsOneWidget);
      });

      testWidgets('Shift + Equal sends OperatorPressed(+)', (tester) async {
        await tester.pumpWidget(createScreen());

        await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
        await tester.pumpAndSettle();
        expect(find.text('4').first, findsOneWidget);

        // Simulate Shift key down, Equal key down, then release
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.equal);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();

        expect(find.text('4+').first, findsOneWidget);
      });

      testWidgets('unmapped keys and non-KeyDown events are ignored safely', (
        tester,
      ) async {
        await tester.pumpWidget(createScreen());

        // Send KeyUpEvent directly
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
        await tester.pumpAndSettle();
        expect(find.text('0').first, findsOneWidget);

        // Send unmapped KeyDownEvent (e.g. keyZ)
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.pumpAndSettle();
        expect(find.text('0').first, findsOneWidget);
      });

      testWidgets(
        'tapping on-screen buttons updates UI and calculates result',
        (tester) async {
          await tester.pumpWidget(createScreen());

          // Tap '7'
          await tester.tap(find.widgetWithText(MechanixButton, '7'));
          await tester.pumpAndSettle();
          expect(find.text('7').first, findsOneWidget);

          // Tap '+'
          await tester.tap(find.widgetWithText(MechanixButton, '+'));
          await tester.pumpAndSettle();
          expect(find.text('7+').first, findsOneWidget);

          // Tap '8'
          await tester.tap(find.widgetWithText(MechanixButton, '8'));
          await tester.pumpAndSettle();
          expect(find.text('7+8').first, findsOneWidget);

          // Tap '='
          await tester.tap(find.widgetWithText(MechanixButton, '='));
          await tester.pumpAndSettle();

          expect(bloc.state.result, '15');
        },
      );

      testWidgets(
        'typing after error clears error message and starts a fresh expression',
        (tester) async {
          await tester.pumpWidget(createScreen());

          // Perform division by zero: 5 ÷ 0 =
          await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
          await tester.sendKeyEvent(LogicalKeyboardKey.slash);
          await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();

          expect(bloc.state.errorMessage, invalidOperationsErrorMessage);

          // Type '9' after the error.
          await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
          await tester.pumpAndSettle();

          expect(find.text(invalidOperationsErrorMessage), findsNothing);
          // Verify DisplayPanel shows '9' and not '0'
          expect(
            find.descendant(
              of: find.byType(DisplayPanel),
              matching: find.text('9'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(DisplayPanel),
              matching: find.text('0'),
            ),
            findsNothing,
          );

          // Type '8' to continue building the expression '98'
          await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: find.byType(DisplayPanel),
              matching: find.text('98'),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'AC button clears 2-2=0 calculation and removes top expression from display',
        (tester) async {
          await tester.pumpWidget(createScreen());

          // 2 - 2 = 0
          await tester.tap(find.widgetWithText(MechanixButton, '2'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(MechanixButton, '-'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(MechanixButton, '2'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(MechanixButton, '='));
          await tester.pumpAndSettle();

          expect(bloc.state.result, '0');

          // Tap AC
          await tester.tap(find.widgetWithText(MechanixButton, 'AC'));
          await tester.pumpAndSettle();

          expect(find.text('2-2'), findsNothing);
          expect(
            find.descendant(
              of: find.byType(DisplayPanel),
              matching: find.text('0'),
            ),
            findsOneWidget,
          );
        },
      );
    });
  });
}
