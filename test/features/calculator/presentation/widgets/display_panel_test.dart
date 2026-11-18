import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_state.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/superscript.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/display_panel.dart';
import 'package:mechanix_calculator/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

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
              history: [HistoryItem(expression: '3+5', result: '8')],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('3+5'), findsNothing);
      expect(find.byType(HistoryOverlay), findsNothing);
    });

    testWidgets(
      'shows only 0 when cleared (AC) even if history item result was 0',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DisplayPanel(
                expression: '',
                result: '0',
                errorMessage: '',
                history: [HistoryItem(expression: '2-2', result: '0')],
              ),
            ),
          ),
        );

        expect(find.text('0'), findsOneWidget);
        expect(find.text('2-2'), findsNothing);
        expect(find.byType(HistoryOverlay), findsNothing);
      },
    );

    testWidgets(
      'shows calculated expression on top and result on bottom for completed calculation',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DisplayPanel(
                calculatedExpression: '12.95 × 10',
                result: '12,950',
                errorMessage: '',
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
      'shows calculated expression and 0 result for completed calculation with result 0 (e.g. 2-2=0)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DisplayPanel(
                calculatedExpression: '2-2',
                result: '0',
                errorMessage: '',
                history: [HistoryItem(expression: '2-2', result: '0')],
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
      'uses displayMedium style for normal short expression and headlineMedium style for long multiline expression',
      (tester) async {
        const shortText = '12,950';
        final longText = '12,9500000000000000000000000000000000000000';

        // 1. Short text uses displayMedium
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 540,
                child: DisplayPanel(
                  expression: shortText,
                  result: '0',
                  errorMessage: '',
                  history: [],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final shortTextFinder = find.text(shortText);
        expect(shortTextFinder, findsOneWidget);
        final shortWidget = tester.widget<Text>(shortTextFinder);
        final defaultDisplayMedium = ThemeData.light().textTheme.displayMedium!
            .copyWith(
              fontFamily: MechanixFontFamily.geistMono,
              fontSize: 52,
              fontWeight: FontWeight.w400,
            );

        expect(
          shortWidget.style?.fontSize,
          equals(defaultDisplayMedium.fontSize),
        );

        // 2. Long text uses headlineMedium
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 350,
                child: DisplayPanel(
                  expression: longText,
                  result: '0',
                  errorMessage: '',
                  history: const [],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final longTextFinder = find.text(longText);
        expect(longTextFinder, findsOneWidget);
        final longWidget = tester.widget<Text>(longTextFinder);
        final defaultHeadlineMedium = ThemeData.light()
            .textTheme
            .headlineMedium!
            .copyWith(
              fontFamily: MechanixFontFamily.geistMono,
              fontSize: 32,
              fontWeight: FontWeight.w400,
            );
        expect(
          longWidget.style?.fontSize,
          equals(defaultHeadlineMedium.fontSize),
        );
      },
    );

    testWidgets('scientific result draws exponent as raised plain digits', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              calculatedExpression: '999999999×999999999',
              result: '9.99999998×10¹⁷',
              errorMessage: '',
            ),
          ),
        ),
      );

      final exponent = tester.widget<Text>(
        find.byKey(const ValueKey('exponent_0')),
      );
      expect(exponent.data, '17');
      expect(find.textContaining('9.99999998×10', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('¹⁷', findRichText: true), findsNothing);
    });

    testWidgets('expression being typed draws exponent as raised digits', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '(-8.879999982×10²⁰)×9',
              result: '0',
              errorMessage: '',
            ),
          ),
        ),
      );

      final exponent = tester.widget<Text>(
        find.byKey(const ValueKey('exponent_0')),
      );
      expect(exponent.data, '20');
      expect(find.textContaining('²⁰', findRichText: true), findsNothing);
      expect(
        find.textContaining('(-8.879999982×10', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('text with two exponents renders without key conflicts', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '9.9×10¹⁷+1.2×10³',
              result: '0',
              errorMessage: '',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('exponent_0'))).data,
        '17',
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('exponent_1'))).data,
        '3',
      );
    });

    group('superscript powers are drawn as raised plain digits', () {
      Future<void> pumpExpression(WidgetTester tester, String text) =>
          tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: DisplayPanel(
                  expression: text,
                  result: '0',
                  errorMessage: '',
                ),
              ),
            ),
          );

      String exponent(WidgetTester tester, int index) => tester
          .widget<Text>(find.byKey(ValueKey('exponent_$index')))
          .data!;

      final cases = {
        // typed text -> (text before the power, raised digits)
        '5²': ('5', '2'),
        '2¹⁰': ('2', '10'),
        '5⁰⁴⁵': ('5', '045'),
        '5⁻²': ('5', '-2'),
        '(2+3)²': ('(2+3)', '2'),
        '(-5²)': ('(-5', '2'),
        '2×10³': ('2×10', '3'),
      };

      cases.forEach((text, expected) {
        final (base, digits) = expected;
        testWidgets('"$text" shows "$base" with raised "$digits"', (
          tester,
        ) async {
          await pumpExpression(tester, text);

          expect(exponent(tester, 0), digits);
          expect(
            find.textContaining(base, findRichText: true),
            findsWidgets,
          );
          // The superscript characters themselves are not drawn.
          for (final char in Superscript.chars.split('')) {
            expect(
              find.textContaining(char, findRichText: true),
              findsNothing,
              reason: char,
            );
          }
        });
      });

      testWidgets('a negative power still being typed shows a raised "-"', (
        tester,
      ) async {
        await pumpExpression(tester, '5⁻');

        expect(exponent(tester, 0), '-');
      });

      testWidgets('each power in an expression is raised separately', (
        tester,
      ) async {
        await pumpExpression(tester, '3²+4²-(2+3)⁻¹');

        expect(tester.takeException(), isNull);
        expect(exponent(tester, 0), '2');
        expect(exponent(tester, 1), '2');
        expect(exponent(tester, 2), '-1');
        expect(find.byKey(const ValueKey('exponent_3')), findsNothing);
      });

      testWidgets('^ is shown as typed, not raised', (tester) async {
        await pumpExpression(tester, '2^10');

        expect(find.text('2^10'), findsOneWidget);
        expect(find.byKey(const ValueKey('exponent_0')), findsNothing);
      });

      testWidgets('a power on a result line is raised too', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DisplayPanel(
                calculatedExpression: '5⁰⁴⁵',
                result: '2.842170943×10³¹',
                errorMessage: '',
              ),
            ),
          ),
        );

        // One power on the expression line, one on the result line.
        final raised = find.byKey(const ValueKey('exponent_0'));
        expect(raised, findsNWidgets(2));
        expect(
          tester.widgetList<Text>(raised).map((t) => t.data).toSet(),
          {'045', '31'},
        );
        expect(
          find.textContaining('2.842170943×10', findRichText: true),
          findsOneWidget,
        );
      });

      testWidgets('history entries raise their powers', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HistoryOverlay(
                history: [HistoryItem(expression: '5²', result: '25')],
              ),
            ),
          ),
        );

        expect(exponent(tester, 0), '2');
        expect(find.textContaining('²', findRichText: true), findsNothing);
      });
    });

    group('ExponentText', () {
      testWidgets('draws the power at half the font size, top-aligned', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ExponentText('5²', style: TextStyle(fontSize: 40)),
            ),
          ),
        );

        final raised = tester.widget<Text>(
          find.byKey(const ValueKey('exponent_0')),
        );
        expect(raised.data, '2');
        expect(raised.style?.fontSize, 20);

        final richText = tester.widget<RichText>(
          find
              .ancestor(
                of: find.byKey(const ValueKey('exponent_0')),
                matching: find.byType(RichText),
              )
              .last,
        );
        final placeholders = <WidgetSpan>[];
        richText.text.visitChildren((span) {
          if (span is WidgetSpan) placeholders.add(span);
          return true;
        });
        expect(placeholders.single.alignment, PlaceholderAlignment.top);
      });

      testWidgets('text without superscripts is a plain Text', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ExponentText('12+3', style: TextStyle(fontSize: 40)),
            ),
          ),
        );

        expect(find.text('12+3'), findsOneWidget);
        expect(find.byKey(const ValueKey('exponent_0')), findsNothing);
      });

      testWidgets('screen readers get the full text', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ExponentText('5⁻²', style: TextStyle(fontSize: 40)),
            ),
          ),
        );

        expect(find.bySemanticsLabel('5⁻²'), findsOneWidget);
        handle.dispose();
      });
    });
  });
}
