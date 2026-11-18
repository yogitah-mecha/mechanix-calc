import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';

/// Turns input tokens into display text. The editor needs it to apply the
/// character limit; the implementation lives in presentation
/// (`ExpressionRenderer`), so the domain does not depend on it.
abstract interface class InputRenderer {
  String render(List<InputToken> tokens);
}
