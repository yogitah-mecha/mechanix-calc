import 'package:math_expressions/math_expressions.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/calc_serializer.dart';

/// Resolves the leading `%` in an operand chain using [base].
/// Traverses `×`, `÷`, and unary minus, but not powers.
class PercentResolver {
  const PercentResolver();

  Expression resolve(Expression node) => switch (node) {
    Plus(:final first, :final second) => _additive(first, second, Plus.new),
    Minus(:final first, :final second) => _additive(first, second, Minus.new),
    Times(:final first, :final second) => Times(
      resolve(first),
      resolve(second),
    ),
    Divide(:final first, :final second) => Divide(
      resolve(first),
      resolve(second),
    ),
    Power(:final first, :final second) => Power(
      resolve(first),
      resolve(second),
    ),
    UnaryMinus(:final exp) => UnaryMinus(resolve(exp)),
    _ when _isPercent(node) => _percentOf(node),
    _ => node,
  };

  Expression _additive(
    Expression left,
    Expression right,
    Expression Function(Expression, Expression) build,
  ) {
    final base = resolve(left);
    return build(base, _resolveWithBase(right, base));
  }

  /// Resolves [node], applying [base] to the `%` at the start of its
  /// leftmost operand chain (through `×`, `÷` and unary minus only; a `%`
  /// raised to a power, `10%^2`, is a plain percent).
  Expression _resolveWithBase(Expression node, Expression base) =>
      switch (node) {
        Times(:final first, :final second) => Times(
          _resolveWithBase(first, base),
          resolve(second),
        ),
        Divide(:final first, :final second) => Divide(
          _resolveWithBase(first, base),
          resolve(second),
        ),
        UnaryMinus(:final exp) => UnaryMinus(_resolveWithBase(exp, base)),
        _ when _isPercent(node) => Times(base, _percentOf(node)),
        _ => resolve(node),
      };

  /// `pct(x)` -> `x / 100`.
  Expression _percentOf(Expression node) =>
      Divide(resolve(_percentArgument(node)), Number(100));

  static bool _isPercent(Expression node) =>
      node is MathFunction && node.name == percentFunctionName;

  /// The parser wraps function arguments in a [BoundVariable].
  static Expression _percentArgument(Expression node) {
    final argument = (node as MathFunction).args.single;
    return argument is BoundVariable ? argument.value : argument;
  }
}
