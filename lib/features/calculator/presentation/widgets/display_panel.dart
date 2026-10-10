import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

import '../../bloc/calculator_state.dart';

class DisplayPanel extends StatefulWidget {
  final String expression;
  final String calculatedExpression;
  final String result;
  final String errorMessage;
  final List<HistoryItem> history;
  final bool isHistoryOpen;
  final ValueChanged<String>? onHistoryItemTap;
  final VoidCallback? onDismissHistory;

  const DisplayPanel({
    super.key,
    this.expression = '',
    this.calculatedExpression = '',
    required this.result,
    required this.errorMessage,
    this.history = const [],
    this.isHistoryOpen = false,
    this.onHistoryItemTap,
    this.onDismissHistory,
  });

  @override
  State<DisplayPanel> createState() => _DisplayPanelState();
}

class _DisplayPanelState extends State<DisplayPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DisplayPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.errorMessage.isNotEmpty &&
        widget.errorMessage != oldWidget.errorMessage &&
        widget.errorMessage != invalidOperationsErrorMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final l10n = AppLocalizations.of(context);

        MechanixSnackbar.text(
          text: _getErrorMessage(l10n, widget.errorMessage),
          position: MechanixSnackbarPosition.top,
        ).show(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isHistoryOpen) {
      return HistoryOverlay(
        history: widget.history,
        onHistoryItemTap: widget.onHistoryItemTap,
      );
    }

    final l10n = AppLocalizations.of(context);
    final String topExpression;
    final String bottomText;

    if (widget.errorMessage.isNotEmpty &&
        widget.errorMessage == invalidOperationsErrorMessage) {
      topExpression = widget.expression.isNotEmpty
          ? widget.expression
          : widget.calculatedExpression;
      bottomText = _getErrorMessage(l10n, widget.errorMessage);
    } else if (widget.expression.isNotEmpty) {
      topExpression = '';
      bottomText = widget.expression;
    } else if (widget.calculatedExpression.isNotEmpty) {
      topExpression = widget.calculatedExpression;
      bottomText = widget.result.isNotEmpty ? widget.result : '0';
    } else {
      topExpression = '';
      bottomText = widget.result.isNotEmpty ? widget.result : '0';
    }

    final displayMediumStyle = Theme.of(context).textTheme.displayMedium!
        .copyWith(
          fontFamily: MechanixFontFamily.geistMono,
          fontSize: 52,
          fontWeight: FontWeight.w400,
        );

    final displayContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (topExpression.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                topExpression,
                textAlign: TextAlign.end,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          SizedBox(
            height: 100,
            width: 540,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: SizedBox(
                width: 540,
                child: Text(
                  bottomText,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: displayMediumStyle,
                ),
              ),
            ),
          ),

          /// Use a small set of font sizes based on expression length
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: Text(
          //     bottomText,
          //     style: displayMediumStyle.copyWith(
          //       fontSize: getDisplayFontSize(bottomText),
          //     ),
          //   ),
          // ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onDismissHistory,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: false,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            reverse: true,
            child: displayContent,
          ),
        ),
      ),
    );
  }
}

class HistoryOverlay extends StatefulWidget {
  final List<HistoryItem> history;
  final ValueChanged<String>? onHistoryItemTap;

  const HistoryOverlay({
    super.key,
    required this.history,
    this.onHistoryItemTap,
  });

  @override
  State<HistoryOverlay> createState() => _HistoryOverlayState();
}

class _HistoryOverlayState extends State<HistoryOverlay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant HistoryOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.history != oldWidget.history) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;

    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.history.reversed.toList();

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return _HistoryTile(item: item, onTap: widget.onHistoryItemTap);
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  final ValueChanged<String>? onTap;

  const _HistoryTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleSmall!.copyWith(
      fontFamily: MechanixFontFamily.geistMono,
      fontSize: 18,
      color: Theme.of(context).colorScheme.onSecondaryContainer,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap?.call(item.expression),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  item.expression,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('=', style: textStyle.copyWith(fontSize: 24)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.result,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: textStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _getErrorMessage(AppLocalizations? l10n, String key) {
  if (l10n == null) return key;

  switch (key) {
    case maxDigitsErrorMessage:
      return l10n.maxDigitsErrorMessage;
    case maxCharactersErrorMessage:
      return l10n.maxCharactersErrorMessage;
    case maxOperationsErrorMessage:
      return l10n.maxOperationsErrorMessage;
    case invalidOperationsErrorMessage:
      return l10n.invalidOperationsErrorMessage;
    default:
      return l10n.invalidOperationsErrorMessage;
  }
}

double getDisplayFontSize(String text) {
  if (text.length > 60) return 24;
  if (text.length > 40) return 32;
  if (text.length > 16) return 40;
  return 52;
}
