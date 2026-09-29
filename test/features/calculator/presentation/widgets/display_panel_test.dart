import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_state.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/display_panel.dart';
import 'package:mechanix_calculator/l10n/app_localizations.dart';

void main() {
  group('DisplayPanel', () {
    testWidgets('shows 0 when history is empty and expression is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '',
              result: '0',
              errorMessage: '',
              history: [],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.byType(HistoryOverlay), findsNothing);
    });

    testWidgets('shows only 0 when cleared (AC) even if history is not empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '',
              result: '0',
              errorMessage: '',
              isCalculated: false,
              history: [HistoryItem(expression: '3+5', result: '8')],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('3+5'), findsNothing);
      expect(find.byType(HistoryOverlay), findsNothing);
    });

    testWidgets('shows only 0 when cleared (AC) even if history item result was 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '',
              result: '0',
              errorMessage: '',
              isCalculated: false,
              history: [HistoryItem(expression: '2-2', result: '0')],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('2-2'), findsNothing);
      expect(find.byType(HistoryOverlay), findsNothing);
    });

    testWidgets(
      'shows previous expression and result for completed calculation',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DisplayPanel(
                expression: '',
                result: '12,950',
                errorMessage: '',
                isCalculated: true,
                history: [
                  HistoryItem(expression: '12.95 × 10', result: '12,950'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('12.95 × 10'), findsOneWidget);
        expect(find.text('12,950'), findsOneWidget);
        expect(find.byType(HistoryOverlay), findsNothing);
      },
    );

    testWidgets(
      'shows previous expression and 0 result for completed calculation with result 0 (e.g. 2-2=0)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DisplayPanel(
                expression: '',
                result: '0',
                errorMessage: '',
                isCalculated: true,
                history: [
                  HistoryItem(expression: '2-2', result: '0'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('2-2'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.byType(HistoryOverlay), findsNothing);
      },
    );

    group('Error message presentation', () {
      testWidgets(
        'shows expression and exact error message when error is present',
        (tester) async {
          // 1. Division by zero / invalid mathematical operation
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: DisplayPanel(
                  expression: '5÷0',
                  result: '',
                  errorMessage: invalidOperationsErrorMessage,
                  history: [],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('5÷0'), findsOneWidget);
          expect(find.text(invalidOperationsErrorMessage), findsOneWidget);

          // 2. Malformed expressions
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: DisplayPanel(
                  expression: '5++',
                  result: '',
                  errorMessage: 'Malformed expressions',
                  history: [],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('5++'), findsOneWidget);
          expect(find.text('Malformed expressions'), findsOneWidget);
        },
      );

      testWidgets(
        'shows expression and distinct error messages when limits are hit',
        (tester) async {
          // 1. 15 Digits Limit
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: DisplayPanel(
                  expression: '111111111111111',
                  result: '',
                  errorMessage: maxDigitsErrorMessage,
                  history: [],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('111111111111111'), findsOneWidget);

          // 2. 100 Characters Limit
          final expr100 = '1' * 100;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: DisplayPanel(
                  expression: expr100,
                  result: '',
                  errorMessage: maxCharactersErrorMessage,
                  history: const [],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(expr100), findsOneWidget);
          expect(find.text(maxCharactersErrorMessage), findsOneWidget);

          // 3. 20 Operations Limit
          const expr40Ops =
              '1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1';
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: DisplayPanel(
                  expression: expr40Ops,
                  result: '',
                  errorMessage: maxOperationsErrorMessage,
                  history: [],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(expr40Ops), findsOneWidget);
          expect(find.text(maxOperationsErrorMessage), findsOneWidget);
        },
      );

      testWidgets(
        'shows error snackbar when widget updates with new error message',
        (tester) async {
          // Initial state without error
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: DisplayPanel(
                  expression: '123',
                  result: '0',
                  errorMessage: '',
                  history: [],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('123'), findsOneWidget);
          expect(find.text("Can't enter more than 15 digits"), findsNothing);

          // Update widget with limit error
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: DisplayPanel(
                  expression: '123',
                  result: '0',
                  errorMessage: "Can't enter more than 15 digits",
                  history: [],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('123'), findsOneWidget);
          expect(find.text("Can't enter more than 15 digits"), findsOneWidget);
        },
      );

      testWidgets(
        'resolves error message keys to localized strings with AppLocalizations',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: DisplayPanel(
                  expression: '5÷0',
                  result: '',
                  errorMessage: invalidOperationsErrorMessage,
                  history: [],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('5÷0'), findsOneWidget);
          expect(find.text('Error'), findsOneWidget);
        },
      );
    });

    testWidgets('shows active expression when typing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '12.95 × 10',
              result: '0',
              errorMessage: '',
              history: [],
            ),
          ),
        ),
      );

      expect(find.text('12.95 × 10'), findsOneWidget);
    });

    testWidgets(
      'renders HistoryOverlay when isHistoryOpen is true and handles tap',
      (tester) async {
        String? tappedExpr;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DisplayPanel(
                expression: '',
                result: '12,950',
                errorMessage: '',
                isHistoryOpen: true,
                history: const [
                  HistoryItem(expression: '11 × 21', result: '231'),
                  HistoryItem(expression: '12.95 × 10', result: '12,950'),
                ],
                onHistoryItemTap: (expr) {
                  tappedExpr = expr;
                },
              ),
            ),
          ),
        );

        expect(find.byType(HistoryOverlay), findsOneWidget);
        expect(find.text('11 × 21'), findsOneWidget);
        expect(find.text('231'), findsOneWidget);
        expect(find.text('12.95 × 10'), findsOneWidget);

        await tester.tap(find.text('11 × 21'));
        await tester.pumpAndSettle();

        expect(tappedExpr, '11 × 21');
      },
    );

    testWidgets(
      'renders vertical Scrollbar and SingleChildScrollView for long digits',
      (tester) async {
        final longDigits = '1234567890' * 20;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                width: 300,
                child: DisplayPanel(
                  expression: longDigits,
                  result: '0',
                  errorMessage: '',
                  history: const [],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(Scrollbar), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.text(longDigits), findsOneWidget);

        final scrollable = find.byType(SingleChildScrollView);
        final singleChild = tester.widget<SingleChildScrollView>(scrollable);
        expect(singleChild.scrollDirection, Axis.vertical);
        expect(singleChild.reverse, isTrue);
      },
    );
  });
}
