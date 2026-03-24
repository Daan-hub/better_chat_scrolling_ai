import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../controllers/chat_scroll_controller.dart';
import 'scroll_to_bottom_button.dart';

class BetterChatScrollView<T> extends StatefulWidget {
  final List<T> messages;
  final Widget Function(BuildContext context, T message, int index)
      messageBuilder;
  final ChatScrollController controller;
  final Widget? scrollToBottomWidget;
  final EdgeInsets? padding;
  final double scrollToBottomThreshold;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  const BetterChatScrollView({
    super.key,
    required this.messages,
    required this.messageBuilder,
    required this.controller,
    this.scrollToBottomWidget,
    this.padding,
    this.scrollToBottomThreshold = 50.0,
    this.separatorBuilder,
  });

  @override
  State<BetterChatScrollView<T>> createState() =>
      _BetterChatScrollViewState<T>();
}

class _BetterChatScrollViewState<T> extends State<BetterChatScrollView<T>> {
  double _viewportHeight = 0;

  ChatScrollController get _ctrl => widget.controller;

  @override
  Widget build(BuildContext context) {
    final exchangeCount = _ctrl.exchangeCount;
    final messageCount = widget.messages.length;
    final regularCount = messageCount - exchangeCount;

    // Items: regular messages + (exchange group if active) + trailing anchor.
    final itemCount =
        regularCount + (exchangeCount > 0 ? 1 : 0) + 1; // +1 for anchor
    _ctrl.updateItemCount(itemCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;

        return Stack(
          children: [
            ScrollablePositionedList.builder(
              itemCount: itemCount,
              itemScrollController: _ctrl.itemScrollController,
              itemPositionsListener: _ctrl.itemPositionsListener,
              // Start at trailing anchor with top at viewport bottom
              // → all real messages fill above = chat starts at bottom.
              initialScrollIndex: itemCount > 1 ? itemCount - 1 : 0,
              initialAlignment: itemCount > 1 ? 1.0 : 0.0,
              padding: widget.padding,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemBuilder: (context, index) =>
                  _buildItem(context, index, regularCount, exchangeCount, itemCount),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _ctrl.showScrollToBottom,
                  builder: (context, show, child) {
                    return AnimatedOpacity(
                      opacity: show ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !show,
                        child: widget.scrollToBottomWidget ??
                            ScrollToBottomButton(
                              onPressed: _ctrl.scrollToBottom,
                            ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    int regularCount,
    int exchangeCount,
    int itemCount,
  ) {
    // Trailing anchor (always the last item).
    if (index == itemCount - 1) {
      return const SizedBox.shrink();
    }

    // Exchange group (second-to-last real item, when exchange is active).
    if (exchangeCount > 0 && index == regularCount) {
      double minHeight = _viewportHeight;
      if (widget.padding != null) {
        minHeight -= widget.padding!.vertical;
      }

      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Exchange messages: user msg first (top), AI response below.
            // messages[exchangeCount-1] = user msg, messages[0] = AI response (newest-first array).
            for (int i = exchangeCount - 1; i >= 0; i--) ...[
              if (i < exchangeCount - 1 &&
                  widget.separatorBuilder != null)
                widget.separatorBuilder!(context, 0),
              widget.messageBuilder(
                  context, widget.messages[i], i),
            ],
          ],
        ),
      );
    }

    // Regular messages in chronological order (oldest first).
    // List index 0 = oldest = messages[messages.length - 1]
    final msgIndex = widget.messages.length - 1 - index;
    if (msgIndex < 0 || msgIndex >= widget.messages.length) {
      return const SizedBox.shrink();
    }

    final messageWidget = widget.messageBuilder(
      context,
      widget.messages[msgIndex],
      msgIndex,
    );

    // Separator after each regular message (not the last one before exchange/anchor).
    final isLastRegular = (exchangeCount > 0)
        ? index == regularCount - 1
        : index == regularCount - 1; // last regular before anchor
    if (widget.separatorBuilder != null && !isLastRegular) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          messageWidget,
          widget.separatorBuilder!(context, index),
        ],
      );
    }

    // Separator between last regular message and exchange group.
    if (widget.separatorBuilder != null &&
        isLastRegular &&
        exchangeCount > 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          messageWidget,
          widget.separatorBuilder!(context, index),
        ],
      );
    }

    return messageWidget;
  }
}
