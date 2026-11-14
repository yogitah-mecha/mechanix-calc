import 'package:equatable/equatable.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/result_formatter.dart';

class ExpressionResult extends Equatable {
  final String expression;
  final String errorMessage;

  const ExpressionResult({required this.expression, this.errorMessage = ''});

  @override
  List<Object?> get props => [expression, errorMessage];
}

class ExpressionBuilder {
  static const Set<String> _operators = {'+', '-', '×', '÷', '%', '*', '/'};
  static final _operatorSplitPattern = RegExp(r'[+\-×÷%()]');

  /// A scientific number at the end, e.g. "9.99999998×10¹⁷".
  static final _trailingScientificPattern = RegExp(
    '([0-9.]+×10[${ResultFormatter.superscriptChars}]+)\$',
  );

  /// A negated scientific number at the end, e.g. "(-9.99999998×10¹⁷)".
  static final _trailingNegScientificPattern = RegExp(
    '\\(-([0-9.]+×10[${ResultFormatter.superscriptChars}]+)\\)\$',
  );

  static bool _endsWithExponent(String expression) =>
      expression.isNotEmpty &&
      ResultFormatter.superscriptChars.contains(
        expression[expression.length - 1],
      );

  static int countOperations(String expression) {
    if (expression.isEmpty) return 0;

    int count = 0;

    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];

      if (!_operators.contains(char)) continue;

      if (char == '-' &&
          (i == 0 ||
              _operators.contains(expression[i - 1]) ||
              expression[i - 1] == '(')) {
        continue;
      }

      count++;
    }

    return count;
  }

  static bool hasNumberExceedingMaxDigits(String expression) {
    final segments = expression.split(_operatorSplitPattern);
    for (final segment in segments) {
      final digits = segment.replaceAll(RegExp(r'\D'), '');
      if (digits.length > maxDigits) {
        return true;
      }
    }
    return false;
  }

  static String? validateExpressionLimits(String expression) {
    if (expression.length > maxCharacters) {
      return maxCharactersErrorMessage;
    }
    if (countOperations(expression) > maxOperations) {
      return maxOperationsErrorMessage;
    }
    if (hasNumberExceedingMaxDigits(expression)) {
      return maxDigitsErrorMessage;
    }
    return null;
  }

  static ExpressionResult handleNumber(
    String currentExpression,
    String number,
  ) {
    if (_endsWithExponent(currentExpression)) {
      return ExpressionResult(expression: currentExpression);
    }

    String resultingExpression;

    if (number == '.') {
      final segments = currentExpression.split(_operatorSplitPattern);
      if (segments.isNotEmpty && segments.last.contains('.')) {
        return ExpressionResult(expression: currentExpression);
      }
      if (currentExpression.isEmpty || currentExpression == '0') {
        resultingExpression = '0.';
      } else if (currentExpression.endsWith('(-')) {
        resultingExpression = '${currentExpression}0.';
      } else if (currentExpression.endsWith(')')) {
        final match = RegExp(r'\(-([0-9.]+)\)$').firstMatch(currentExpression);
        if (match != null) {
          final inner = match.group(1)!;
          if (!inner.contains('.')) {
            resultingExpression =
                '${currentExpression.substring(0, match.start)}(-$inner.)';
          } else {
            return ExpressionResult(expression: currentExpression);
          }
        } else {
          resultingExpression = '$currentExpression.';
        }
      } else if (currentExpression.isNotEmpty &&
          _operators.contains(
            currentExpression[currentExpression.length - 1],
          )) {
        resultingExpression = '${currentExpression}0.';
      } else {
        resultingExpression = '$currentExpression.';
      }
    } else {
      if (currentExpression == '0') {
        resultingExpression = number;
      } else if (currentExpression.endsWith('(-')) {
        resultingExpression = '$currentExpression$number)';
      } else if (currentExpression.endsWith(')')) {
        final match = RegExp(r'\(-([0-9.]+)\)$').firstMatch(currentExpression);
        if (match != null) {
          final inner = match.group(1)!;
          final updatedInner = inner == '0' ? number : '$inner$number';
          resultingExpression =
              '${currentExpression.substring(0, match.start)}(-$updatedInner)';
        } else {
          resultingExpression = currentExpression + number;
        }
      } else {
        resultingExpression = currentExpression + number;
      }
    }

    final error = validateExpressionLimits(resultingExpression);
    if (error != null) {
      return ExpressionResult(
        expression: currentExpression,
        errorMessage: error,
      );
    }

    return ExpressionResult(expression: resultingExpression);
  }

  static ExpressionResult handleOperator(
    String currentExpression,
    String operator, {
    String? previousResult,
  }) {
    if (currentExpression.isEmpty && operator == '-') {
      return const ExpressionResult(expression: '(-');
    }

    String resultingExpression;
    if (currentExpression.isEmpty) {
      if (previousResult != null && previousResult.isNotEmpty) {
        final sanitized = previousResult.replaceAll(',', '');
        resultingExpression = sanitized.startsWith('-')
            ? '($sanitized)$operator'
            : '$sanitized$operator';
      } else {
        return ExpressionResult(expression: currentExpression);
      }
    } else if (currentExpression == '(-' || currentExpression == '-') {
      return const ExpressionResult(expression: '');
    } else if (currentExpression.endsWith('(-')) {
      resultingExpression = currentExpression.substring(
        0,
        currentExpression.length - 2,
      );
      if (resultingExpression.isNotEmpty &&
          _operators.contains(
            resultingExpression[resultingExpression.length - 1],
          )) {
        resultingExpression =
            resultingExpression.substring(0, resultingExpression.length - 1) +
            operator;
      } else {
        resultingExpression += operator;
      }
    } else {
      final lastChar = currentExpression[currentExpression.length - 1];
      // '%' ends an operand (e.g. "10%"), so keep it and append the operator.
      if (_operators.contains(lastChar) && lastChar != '%') {
        resultingExpression =
            currentExpression.substring(0, currentExpression.length - 1) +
            operator;
      } else {
        resultingExpression = currentExpression + operator;
      }
    }

    final error = validateExpressionLimits(resultingExpression);
    if (error != null) {
      return ExpressionResult(
        expression: currentExpression,
        errorMessage: error,
      );
    }

    return ExpressionResult(expression: resultingExpression);
  }

  static ExpressionResult handleDelete(String currentExpression) {
    if (currentExpression.isEmpty) {
      return const ExpressionResult(expression: '');
    }

    if (currentExpression.endsWith(')')) {
      final match = RegExp(r'\(-([0-9.]+)\)$').firstMatch(currentExpression);
      if (match != null) {
        final inner = match.group(1)!;
        if (inner.length > 1) {
          return ExpressionResult(
            expression:
                '${currentExpression.substring(0, match.start)}(-${inner.substring(0, inner.length - 1)})',
          );
        } else {
          return ExpressionResult(
            expression: currentExpression.substring(0, match.start),
          );
        }
      }
    }

    if (currentExpression.endsWith('(-')) {
      return ExpressionResult(
        expression: currentExpression.substring(
          0,
          currentExpression.length - 2,
        ),
      );
    }

    return ExpressionResult(
      expression: currentExpression.substring(0, currentExpression.length - 1),
    );
  }

  static ExpressionResult handleClear() {
    return const ExpressionResult(expression: '');
  }

  static ExpressionResult handleToggleSign(String currentExpression) {
    if (currentExpression.isEmpty) {
      return const ExpressionResult(expression: '(-');
    }
    if (currentExpression == '(-' || currentExpression == '-') {
      return const ExpressionResult(expression: '');
    }

    // 1. If expression ends with an operator followed by '(-', e.g. "5×(-", remove '(-' -> "5×"
    if (currentExpression.endsWith('(-')) {
      return ExpressionResult(
        expression: currentExpression.substring(
          0,
          currentExpression.length - 2,
        ),
      );
    }

    // 2. If expression ends with a trailing operator, e.g. "5×", "5+", "5÷", toggle adds '(-' -> "5×(-"
    final lastChar = currentExpression[currentExpression.length - 1];
    if (_operators.contains(lastChar)) {
      final resultingExpression = '$currentExpression(-';
      final error = validateExpressionLimits(resultingExpression);
      if (error != null) {
        return ExpressionResult(
          expression: currentExpression,
          errorMessage: error,
        );
      }
      return ExpressionResult(expression: resultingExpression);
    }

    // Scientific numbers: "(-9.9×10¹⁷)" -> "9.9×10¹⁷", "9.9×10¹⁷" -> "(-9.9×10¹⁷)"
    final negSci = _trailingNegScientificPattern.firstMatch(currentExpression);
    if (negSci != null) {
      return ExpressionResult(
        expression:
            '${currentExpression.substring(0, negSci.start)}${negSci.group(1)}',
      );
    }
    final sci = _trailingScientificPattern.firstMatch(currentExpression);
    if (sci != null && sci.start == 1 && currentExpression.startsWith('-')) {
      // A negative scientific result reused as-is, e.g. "-9.9×10¹⁷".
      return ExpressionResult(expression: currentExpression.substring(1));
    }
    if (sci != null) {
      final resultingExpression =
          '${currentExpression.substring(0, sci.start)}(-${sci.group(1)})';
      final error = validateExpressionLimits(resultingExpression);
      if (error != null) {
        return ExpressionResult(
          expression: currentExpression,
          errorMessage: error,
        );
      }
      return ExpressionResult(expression: resultingExpression);
    }

    // 3. If expression ends with a parenthesized negative number "(-<digits>)"
    // e.g. "(-5)" -> "5", "2×(-5)" -> "2×5", "(-5)×(-5)" -> "(-5)×5"
    final parenNegMatch = RegExp(
      r'\(-([0-9.]+)\)$',
    ).firstMatch(currentExpression);
    if (parenNegMatch != null) {
      final innerNumber = parenNegMatch.group(1)!;
      final prefix = currentExpression.substring(0, parenNegMatch.start);
      final resultingExpression = '$prefix$innerNumber';
      return ExpressionResult(expression: resultingExpression);
    }

    // 4. If expression ends with unparenthesized negative number at start, e.g. "-5" -> "5"
    if (currentExpression.startsWith('-') &&
        RegExp(r'^-[0-9.]+$').hasMatch(currentExpression)) {
      return ExpressionResult(expression: currentExpression.substring(1));
    }

    // 5. The expression ends with a positive number segment "<digits>"
    // Find the start of the current (last) number segment.
    int numStartIndex = currentExpression.length - 1;
    while (numStartIndex >= 0 &&
        (currentExpression[numStartIndex] == '.' ||
            (currentExpression.codeUnitAt(numStartIndex) >= 48 &&
                currentExpression.codeUnitAt(numStartIndex) <= 57))) {
      numStartIndex--;
    }

    final numberPart = currentExpression.substring(numStartIndex + 1);
    final prefix = currentExpression.substring(0, numStartIndex + 1);
    final resultingExpression = '$prefix(-$numberPart)';

    final error = validateExpressionLimits(resultingExpression);
    if (error != null) {
      return ExpressionResult(
        expression: currentExpression,
        errorMessage: error,
      );
    }

    return ExpressionResult(expression: resultingExpression);
  }

  static ExpressionResult handlePercentage(String currentExpression) {
    if (currentExpression.isEmpty) {
      return const ExpressionResult(expression: '');
    }

    final resultingExpression = '$currentExpression%';
    final error = validateExpressionLimits(resultingExpression);
    if (error != null) {
      return ExpressionResult(
        expression: currentExpression,
        errorMessage: error,
      );
    }

    return ExpressionResult(expression: resultingExpression);
  }
}
