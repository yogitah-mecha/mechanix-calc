import 'package:flutter/material.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/calculator_button.dart';

enum CalculatorActionType {
  number,

  /// A superscript digit or `-` added to the last power (keyboard: Ctrl+digit,
  /// Ctrl+-).
  superscript,
  operator,
  openBracket,
  closeBracket,
  clear,
  delete,
  toggleSign,
  percentage,
  calculate,
}

class CalculatorButtonData {
  final String? text;
  final IconData? icon;
  final CalculatorButtonType type;
  final CalculatorActionType action;
  final String? value;

  const CalculatorButtonData({
    this.text,
    this.icon,
    this.type = CalculatorButtonType.standard,
    required this.action,
    this.value,
  });
}

const List<CalculatorButtonData> calculatorButtons = [
  // Row 1
  CalculatorButtonData(
    text: 'AC',
    type: CalculatorButtonType.action,
    action: CalculatorActionType.clear,
  ),
  CalculatorButtonData(
    text: '+/-',
    type: CalculatorButtonType.action,
    action: CalculatorActionType.toggleSign,
  ),
  CalculatorButtonData(
    icon: Icons.percent,
    type: CalculatorButtonType.action,
    action: CalculatorActionType.percentage,
  ),
  CalculatorButtonData(
    text: '÷',
    type: CalculatorButtonType.action,
    action: CalculatorActionType.operator,
    value: '÷',
  ),

  // Row 2
  CalculatorButtonData(
    text: '7',
    action: CalculatorActionType.number,
    value: '7',
  ),
  CalculatorButtonData(
    text: '8',
    action: CalculatorActionType.number,
    value: '8',
  ),
  CalculatorButtonData(
    text: '9',
    action: CalculatorActionType.number,
    value: '9',
  ),
  CalculatorButtonData(
    text: '×',
    type: CalculatorButtonType.action,
    action: CalculatorActionType.operator,
    value: '×',
  ),

  // Row 3
  CalculatorButtonData(
    text: '4',
    action: CalculatorActionType.number,
    value: '4',
  ),
  CalculatorButtonData(
    text: '5',
    action: CalculatorActionType.number,
    value: '5',
  ),
  CalculatorButtonData(
    text: '6',
    action: CalculatorActionType.number,
    value: '6',
  ),
  CalculatorButtonData(
    text: '-',
    type: CalculatorButtonType.action,
    action: CalculatorActionType.operator,
    value: '-',
  ),

  // Row 4
  CalculatorButtonData(
    text: '1',
    action: CalculatorActionType.number,
    value: '1',
  ),
  CalculatorButtonData(
    text: '2',
    action: CalculatorActionType.number,
    value: '2',
  ),
  CalculatorButtonData(
    text: '3',
    action: CalculatorActionType.number,
    value: '3',
  ),
  CalculatorButtonData(
    text: '+',
    type: CalculatorButtonType.action,
    action: CalculatorActionType.operator,
    value: '+',
  ),

  // Row 5
  CalculatorButtonData(
    icon: Icons.backspace_outlined,
    type: CalculatorButtonType.action,
    action: CalculatorActionType.delete,
  ),
  CalculatorButtonData(
    text: '0',
    action: CalculatorActionType.number,
    value: '0',
  ),
  CalculatorButtonData(
    text: '.',
    type: CalculatorButtonType.action,
    action: CalculatorActionType.number,
    value: '.',
  ),
  CalculatorButtonData(
    text: '=',
    type: CalculatorButtonType.primary,
    action: CalculatorActionType.calculate,
  ),
];

class ButtonGrid extends StatelessWidget {
  final ValueChanged<CalculatorButtonData>? onButtonPressed;

  const ButtonGrid({super.key, this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double crossSpacing = 8.0;
          const double mainSpacing = 8.0;
          final double itemWidth =
              (constraints.maxWidth - (crossSpacing * 3)) / 4;
          final double itemHeight =
              (constraints.maxHeight - (mainSpacing * 4)) / 5;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calculatorButtons.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: mainSpacing,
              crossAxisSpacing: crossSpacing,
              childAspectRatio: itemWidth / itemHeight,
            ),
            itemBuilder: (context, index) {
              final btn = calculatorButtons[index];
              return CalculatorButton(
                text: btn.text,
                icon: btn.icon,
                type: btn.type,
                onTap: () => onButtonPressed?.call(btn),
              );
            },
          );
        },
      ),
    );
  }
}
