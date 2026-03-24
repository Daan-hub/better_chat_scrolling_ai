import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChatScrollController {
  /// Creates a chat scroll controller.
  ///
  /// [autoFollowOnScrollToBottom] controls whether pressing the scroll-to-bottom
  /// button during AI streaming activates auto-follow mode (viewport sticks to
  /// the bottom as new content arrives). Defaults to true.
  ChatScrollController({
    this.autoFollowOnScrollToBottom = true,
  });

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final ScrollOffsetController scrollOffsetController = ScrollOffsetController();
  final ValueNotifier<bool> showScrollToBottom = ValueNotifier(false);

  /// Notifier for the number of messages in the current exchange group.
  final ValueNotifier<int> exchangeCountNotifier = ValueNotifier(0);

  int get exchangeCount => exchangeCountNotifier.value;

  /// Whether pressing scroll-to-bottom during streaming activates auto-follow.
  final bool autoFollowOnScrollToBottom;

  bool _inExchange = false;
  int _pendingAICount = 0;
  int _totalItemCount = 0;
  bool _isProgrammaticScroll = false;
  bool _autoFollow = false;
  bool _isReanchoring = false;

  /// True after scrollToBottom/jumpToBottom targeted the anchor.
  /// When the user next touches the screen, we re-anchor to a visible
  /// content item to prevent jitter from ScrollablePositionedList
  /// maintaining the anchor's position as content grows.
  bool _anchoredToBottom = false;

  double _viewportHeight = 0;
  double _bottomPadding = 0;
  double _scrollToBottomThreshold = 50.0;

  void init() {
    itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
  }

  void updateViewportInfo(
    double viewportHeight,
    double bottomPadding,
    double scrollToBottomThreshold,
  ) {
    _viewportHeight = viewportHeight;
    _bottomPadding = bottomPadding;
    _scrollToBottomThreshold = scrollToBottomThreshold;
  }

  void _onPositionsChanged() {
    if (_isProgrammaticScroll || _isReanchoring) return;
    if (_totalItemCount <= 1) return;
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final anchorIndex = _totalItemCount - 1;
    final thresholdFraction =
        _viewportHeight > 0 ? _scrollToBottomThreshold / _viewportHeight : 0.0;

    final anchorNearBottom = positions.any(
      (p) => p.index == anchorIndex && p.itemLeadingEdge < 1.0 + thresholdFraction,
    );

    final shouldShow = !anchorNearBottom;
    showScrollToBottom.value = shouldShow;

    if (shouldShow && _autoFollow) {
      _autoFollow = false;
      // _anchoredToBottom stays true — resolved on next user touch
    }
  }

  void onNewUserMessage() {
    _inExchange = true;
    _autoFollow = false;
    _anchoredToBottom = false;
    exchangeCountNotifier.value = 1 + _pendingAICount;
    _pendingAICount = 0;
    _isProgrammaticScroll = true;
    showScrollToBottom.value = false;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!itemScrollController.isAttached || _totalItemCount <= 1) {
          _isProgrammaticScroll = false;
          return;
        }
        final exchangeIndex = _totalItemCount - 2;
        if (exchangeIndex >= 0) {
          itemScrollController.jumpTo(index: exchangeIndex, alignment: 0.0);
        }
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _isProgrammaticScroll = false;
          _onPositionsChanged();
        });
      });
    });
  }

  void onAIResponseStarted() {
    if (_inExchange) {
      exchangeCountNotifier.value = exchangeCountNotifier.value + 1;
    } else {
      _pendingAICount += 1;
    }
  }

  /// Called by the widget on user touch (onPointerDown).
  /// Cancels auto-follow AND re-anchors if the positioned item is the anchor.
  void onUserTouch() {
    _autoFollow = false;
    if (_anchoredToBottom) {
      _anchoredToBottom = false;
      _reanchorToVisibleItem();
    }
  }

  /// Called by the widget on user drag (onPointerMove).
  /// Safety net to cancel auto-follow if onPointerDown was missed.
  void cancelAutoFollow() {
    _autoFollow = false;
  }

  void onNewAIContent() {
    if (_autoFollow) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_autoFollow) {
          _adjustScrollToBottom();
        }
      });
    }
  }

  void onAIResponseComplete() {
    _inExchange = false;
    _pendingAICount = 0;
    _autoFollow = false;
  }

  void updateItemCount(int count) {
    _totalItemCount = count;
  }

  double get _bottomAlignment {
    if (_viewportHeight > 0 && _bottomPadding > 0) {
      return 1.0 - (_bottomPadding / _viewportHeight);
    }
    return 1.0;
  }

  /// Re-anchor the scroll position to the item closest to the viewport top.
  /// Visually a no-op, but changes ScrollablePositionedList's internal
  /// positioned item from the anchor to a content item.
  void _reanchorToVisibleItem() {
    if (!itemScrollController.isAttached) return;

    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final anchorIndex = _totalItemCount - 1;

    ItemPosition? best;
    double bestDist = double.infinity;

    for (final p in positions) {
      if (p.index == anchorIndex) continue;
      final dist = p.itemLeadingEdge.abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = p;
      }
    }

    if (best != null) {
      _isReanchoring = true;
      itemScrollController.jumpTo(
        index: best.index,
        alignment: best.itemLeadingEdge,
      );
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _isReanchoring = false;
      });
    }
  }

  /// Small pixel-level adjustment to keep anchor at viewport bottom.
  void _adjustScrollToBottom() {
    if (_viewportHeight <= 0) return;

    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final anchorIndex = _totalItemCount - 1;

    ItemPosition? anchorPos;
    for (final p in positions) {
      if (p.index == anchorIndex) {
        anchorPos = p;
        break;
      }
    }

    if (anchorPos == null) {
      // Anchor not visible. Jump to bottom.
      itemScrollController.jumpTo(
        index: _totalItemCount - 1,
        alignment: _bottomAlignment,
      );
      return;
    }

    final targetEdge = _bottomAlignment;
    final currentEdge = anchorPos.itemLeadingEdge;
    final delta = (currentEdge - targetEdge) * _viewportHeight;

    if (delta.abs() < 0.5) return;

    scrollOffsetController.animateScroll(
      offset: delta,
      duration: const Duration(milliseconds: 16),
    );
    showScrollToBottom.value = false;
  }

  /// Smoothly scrolls to the bottom of the chat (300ms animation).
  Future<void> scrollToBottom() async {
    if (!itemScrollController.isAttached || _totalItemCount <= 1) return;

    _isProgrammaticScroll = true;
    _anchoredToBottom = true;
    showScrollToBottom.value = false;

    if (_inExchange && autoFollowOnScrollToBottom) {
      _autoFollow = true;
    }

    await itemScrollController.scrollTo(
      index: _totalItemCount - 1,
      alignment: _bottomAlignment,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    _isProgrammaticScroll = false;
    _onPositionsChanged();
  }

  /// Instantly jumps to the bottom of the chat.
  void jumpToBottom() {
    if (!itemScrollController.isAttached || _totalItemCount <= 1) return;
    _anchoredToBottom = true;
    itemScrollController.jumpTo(
      index: _totalItemCount - 1,
      alignment: _bottomAlignment,
    );
    showScrollToBottom.value = false;
  }

  void dispose() {
    itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    showScrollToBottom.dispose();
    exchangeCountNotifier.dispose();
  }
}
