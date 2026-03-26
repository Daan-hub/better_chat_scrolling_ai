import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../controllers/chat_scroll_controller.dart';
import 'scroll_to_bottom_button.dart';

class BetterChatScrollView<T> extends StatefulWidget {
  final List<T> messages;
  final Widget Function(BuildContext context, T message, int index)
      messageBuilder;
  final ChatScrollController controller;

  /// Custom scroll-to-bottom button builder. Receives the `onPressed` callback.
  /// If null, the default [ScrollToBottomButton] is used.
  final Widget Function(VoidCallback onPressed)? scrollToBottomBuilder;

  /// Horizontal alignment of the scroll-to-bottom button.
  ///
  /// Use [Alignment.centerLeft], [Alignment.center], or [Alignment.centerRight]
  /// to position the button. Defaults to [Alignment.center].
  final Alignment scrollToBottomAlignment;

  /// Padding between the scroll-to-bottom button and the bottom edge of the
  /// chat view. Defaults to 8.0.
  final double scrollToBottomBottomOffset;

  final EdgeInsets? padding;
  final double scrollToBottomThreshold;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Whether to show the scroll-to-bottom button. Defaults to true.
  /// When false, the button is never rendered (the controller still tracks
  /// state internally via [ChatScrollController.showScrollToBottom]).
  final bool showScrollToBottomButton;

  /// Duration of the scroll-to-bottom button fade animation. Defaults to 200ms.
  final Duration scrollToBottomFadeDuration;

  /// Custom scroll physics for the list. Defaults to
  /// `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())`.
  final ScrollPhysics? physics;

  const BetterChatScrollView({
    super.key,
    required this.messages,
    required this.messageBuilder,
    required this.controller,
    this.scrollToBottomBuilder,
    this.scrollToBottomAlignment = Alignment.center,
    this.scrollToBottomBottomOffset = 8.0,
    this.padding,
    this.scrollToBottomThreshold = 50.0,
    this.separatorBuilder,
    this.showScrollToBottomButton = true,
    this.scrollToBottomFadeDuration = const Duration(milliseconds: 200),
    this.physics,
  });

  @override
  State<BetterChatScrollView<T>> createState() =>
      _BetterChatScrollViewState<T>();
}

class _BetterChatScrollViewState<T> extends State<BetterChatScrollView<T>> {
  double _viewportHeight = 0;

  ChatScrollController get _ctrl => widget.controller;

  /// Compute the initial alignment that accounts for bottom padding,
  /// so the list starts at the true bottom (matching scrollToBottom behavior).
  double _initialAlignment(double viewportHeight) {
    final bottomPadding = widget.padding?.bottom ?? 0;
    if (viewportHeight > 0 && bottomPadding > 0) {
      return 1.0 - (bottomPadding / viewportHeight);
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;
        _ctrl.updateViewportInfo(
          _viewportHeight,
          widget.padding?.bottom ?? 0,
          widget.scrollToBottomThreshold,
        );

        return ValueListenableBuilder<int>(
          valueListenable: _ctrl.exchangeCountNotifier,
          builder: (context, rawExchangeCount, _) {
            final messageCount = widget.messages.length;
            // Clamp to prevent negative regularCount if exchangeCount
            // updates before the messages list does.
            final exchangeCount = rawExchangeCount.clamp(0, messageCount);
            final regularCount = messageCount - exchangeCount;

            // Items: regular messages + (exchange group if active) + trailing anchor.
            final itemCount =
                regularCount + (exchangeCount > 0 ? 1 : 0) + 1;
            _ctrl.updateItemCount(itemCount);

            final initAlign = _initialAlignment(_viewportHeight);

            return Stack(
              children: [
                // Detect user touch/drag to disable auto-follow immediately.
                // onPointerDown: cancel on first touch (before any movement)
                // onPointerMove: safety net in case down was missed
                // This prevents the flicker when the user scrolls up while
                // auto-follow is active (jumpToBottom and user drag fighting).
                Listener(
                  onPointerDown: (_) => _ctrl.onUserTouch(),
                  onPointerMove: (_) => _ctrl.cancelAutoFollow(),
                  child: ScrollablePositionedList.builder(
                    itemCount: itemCount,
                    itemScrollController: _ctrl.itemScrollController,
                    itemPositionsListener: _ctrl.itemPositionsListener,
                    scrollOffsetController: _ctrl.scrollOffsetController,
                    initialScrollIndex: itemCount > 1 ? itemCount - 1 : 0,
                    initialAlignment: itemCount > 1 ? initAlign : 0.0,
                    padding: widget.padding,
                    physics: widget.physics ??
                        const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                    itemBuilder: (context, index) => _buildItem(
                        context, index, regularCount, exchangeCount, itemCount),
                  ),
                ),
                if (widget.showScrollToBottomButton)
                  Positioned(
                    bottom: widget.scrollToBottomBottomOffset,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: widget.scrollToBottomAlignment,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _ctrl.showScrollToBottom,
                          builder: (context, show, child) {
                            return AnimatedOpacity(
                              opacity: show ? 1.0 : 0.0,
                              duration: widget.scrollToBottomFadeDuration,
                              child: IgnorePointer(
                                ignoring: !show,
                                child: widget.scrollToBottomBuilder
                                        ?.call(_ctrl.scrollToBottom) ??
                                    ScrollToBottomButton(
                                      onPressed: _ctrl.scrollToBottom,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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
    // Uses 1px height so ItemPositionsListener always reports it,
    // even when slightly off-screen. A 0-height item gets dropped
    // from position reports, breaking the threshold check.
    if (index == itemCount - 1) {
      return const SizedBox(height: 1);
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

    // Show separator after each regular message, except the very last one
    // when there's no exchange group (since only the anchor follows it).
    final isLastRegular = index == regularCount - 1;
    if (widget.separatorBuilder != null &&
        (!isLastRegular || exchangeCount > 0)) {
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
