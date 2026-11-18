import 'package:math_expressions/math_expressions.dart';
import 'package:mechanix_calculator/features/calculator/domain/engine/calc_evaluator.dart';
import 'package:mechanix_calculator/features/calculator/domain/engine/percent_resolver.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/calc_serializer.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';

/// Evaluates the calculator's input tokens:
/// Parsing, the AST and evaluation come from `math_expressions`; t
class CalcEngine {
  CalcEngine({
    CalcSerializer serializer = const CalcSerializer(),
    PercentResolver percentResolver = const PercentResolver(),
  }) : _serializer = serializer,
       _percentResolver = percentResolver,
       _parser = GrammarParser()
         ..addFunction(percentFunctionName, (args) => args.single / 100);

  final CalcSerializer _serializer;
  final PercentResolver _percentResolver;
  final GrammarParser _parser;

  /// Parses [tokens] into a percent-resolved AST.
  ({Expression ast, ContextModel context}) parse(List<InputToken> tokens) {
    final serialized = _serializer.serialize(tokens);
    final ast = _percentResolver.resolve(_parser.parse(serialized.source));

    final context = ContextModel();
    serialized.variables.forEach(
      (name, value) => context.bindVariableName(name, Number(value)),
    );
    return (ast: ast, context: context);
  }

  /// Evaluates [tokens].
  double evaluate(List<InputToken> tokens) {
    final (:ast, :context) = parse(tokens);
    return CalcEvaluator(context).evaluate(ast).toDouble();
  }
}
