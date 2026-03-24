import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChatScrollController {
  ChatScrollController();

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ValueNotifier<bool> showScrollToBottom = ValueNotifier(false);

  int _exchangeCount = 0;
  int get exchangeCount => _exchangeCount;

  /// Total item count in the list (including trailing anchor).
  int _totalItemCount = 0;

  void init() {
    itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
  }

  void _onPositionsChanged() {
    if (_totalItemCount <= 1) return;
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Trailing anchor is the last item.
    // If its leading edge is within the viewport, we're at the bottom.
    final anchorIndex = _totalItemCount - 1;
    final anchorVisible = positions.any(
      (p) => p.index == anchorIndex && p.itemLeadingEdge <= 1.0,
    );
    showScrollToBottom.value = !anchorVisible;
  }

  void onNewUserMessage() {
    _exchangeCount = 1;
    showScrollToBottom.value = false;

    // Schedule jump after 2 frames (layout needs to settle with new exchange).
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!itemScrollController.isAttached || _totalItemCount <= 1) return;
        // The exchange group is the second-to-last item (before the anchor).
        final exchangeIndex = _totalItemCount - 2;
        if (exchangeIndex >= 0) {
          itemScrollController.jumpTo(index: exchangeIndex, alignment: 0.0);
        }
      });
    });
  }

  void onAIResponseStarted() {
    _exchangeCount += 1;
  }

  void onNewAIContent() {
    // Nothing needed — non-reversed list doesn't auto-follow.
  }

  void onAIResponseComplete() {
    _exchangeCount = 0;
  }

  /// Called by [BetterChatScrollView] on each build to keep item count in sync.
  void updateItemCount(int count) {
    _totalItemCount = count;
  }

  void scrollToBottom() {
    if (!itemScrollController.isAttached || _totalItemCount <= 1) return;
    // Scroll to trailing anchor at alignment 1.0:
    // anchor's top at viewport bottom → all content fills above.
    itemScrollController.scrollTo(
      index: _totalItemCount - 1,
      alignment: 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    showScrollToBottom.value = false;
  }

  void jumpToBottom() {
    if (!itemScrollController.isAttached || _totalItemCount <= 1) return;
    itemScrollController.jumpTo(
      index: _totalItemCount - 1,
      alignment: 1.0,
    );
  }

  void dispose() {
    itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    showScrollToBottom.dispose();
  }
}
