/// The binary operators: the symbols accepted from the display and
/// keyboard, and the symbol `math_expressions` expects.
enum CalcOperator {
  add(symbols: {'+'}, parserSymbol: '+'),
  subtract(symbols: {'-'}, parserSymbol: '-'),
  multiply(symbols: {'×', '*'}, parserSymbol: '*'),
  divide(symbols: {'÷', '/'}, parserSymbol: '/'),

  /// Typed as `^`; a superscript power (`5²`) is serialized to it as well.
  power(symbols: {'^'}, parserSymbol: '^');

  const CalcOperator({required this.symbols, required this.parserSymbol});

  /// Accepted symbols; the first one is the one shown on the display.
  final Set<String> symbols;
  final String parserSymbol;

  String get displaySymbol => symbols.first;

  static CalcOperator? fromSymbol(String symbol) {
    for (final operator in values) {
      if (operator.symbols.contains(symbol)) return operator;
    }
    return null;
  }
}
