import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChatScrollController {
  /// Creates a chat scroll controller.
  ///
  /// [autoFollowOnScrollToBottom] controls whether pressing the scroll-to-bottom
  /// button during AI streaming activates auto-follow mode (viewport sticks to
  /// the bottom as new content arrives). Defaults to true.
  ///
  /// [scrollToBottomDuration] controls the animation duration when scrolling to
  /// the bottom. Defaults to 300ms.
  ///
  /// [scrollToBottomCurve] controls the animation curve when scrolling to the
  /// bottom. Defaults to [Curves.easeOut].
  ///
  /// [showButtonDebounce] controls how long the scroll-to-bottom button waits
  /// before appearing, to prevent brief flashes. Defaults to 150ms.
  ///
  /// [keyboardAdjustDuration] controls the animation duration when adjusting
  /// scroll position after the keyboard opens. Defaults to 150ms.
  ///
  /// [autoFollowDeltaThreshold] is the minimum pixel delta before auto-follow
  /// adjusts the scroll position. Defaults to 0.5.
  ChatScrollController({
    this.autoFollowOnScrollToBottom = true,
    this.scrollToBottomDuration = const Duration(milliseconds: 300),
    this.scrollToBottomCurve = Curves.easeOut,
    this.showButtonDebounce = const Duration(milliseconds: 150),
    this.keyboardAdjustDuration = const Duration(milliseconds: 150),
    this.autoFollowDeltaThreshold = 0.5,
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

  /// Animation duration for the scroll-to-bottom action.
  final Duration scrollToBottomDuration;

  /// Animation curve for the scroll-to-bottom action.
  final Curve scrollToBottomCurve;

  /// Debounce duration before the scroll-to-bottom button appears.
  final Duration showButtonDebounce;

  /// Animation duration when adjusting scroll after keyboard opens.
  final Duration keyboardAdjustDuration;

  /// Minimum pixel delta before auto-follow adjusts scroll position.
  final double autoFollowDeltaThreshold;

  bool _inExchange = false;
  int _pendingAICount = 0;
  int _totalItemCount = 0;
  bool _isProgrammaticScroll = false;
  bool _autoFollow = false;
  bool _isReanchoring = false;
  bool _anchoredToBottom = false;
  bool _pendingExchangeJump = false;

  double _viewportHeight = 0;
  double _bottomPadding = 0;
  double _scrollToBottomThreshold = 50.0;

  /// Debounce timer to prevent brief flashes of the scroll-to-bottom button.
  Timer? _showButtonDebounceTimer;

  void init() {
    itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
  }

  void updateViewportInfo(
    double viewportHeight,
    double bottomPadding,
    double scrollToBottomThreshold,
  ) {
    final previousHeight = _viewportHeight;
    _viewportHeight = viewportHeight;
    _bottomPadding = bottomPadding;
    _scrollToBottomThreshold = scrollToBottomThreshold;

    // When viewport shrinks (keyboard opened), adjust scroll position
    // to keep current content visible — but only if we were near the bottom
    // and not in an active exchange (which has its own scroll handling).
    if (previousHeight > 0 &&
        viewportHeight < previousHeight &&
        !_inExchange &&
        itemScrollController.isAttached) {
      final heightDelta = previousHeight - viewportHeight;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (itemScrollController.isAttached) {
          scrollOffsetController.animateScroll(
            offset: heightDelta,
            duration: keyboardAdjustDuration,
          );
        }
      });
    }
  }

  /// Debounced show: only shows button after 150ms of consistently needing
  /// to show. Hides are always instant. Prevents brief flashes on send.
  void _setShowButton(bool shouldShow) {
    if (shouldShow) {
      // Debounce: only show after 150ms
      _showButtonDebounceTimer ??= Timer(showButtonDebounce, () {
        _showButtonDebounceTimer = null;
        showScrollToBottom.value = true;
      });
    } else {
      _showButtonDebounceTimer?.cancel();
      _showButtonDebounceTimer = null;
      showScrollToBottom.value = false;
    }
  }

  void _onPositionsChanged() {
    if (_isProgrammaticScroll || _isReanchoring) return;
    if (_totalItemCount <= 1) return;
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final anchorIndex = _totalItemCount - 1;
    final thresholdFraction =
        _viewportHeight > 0 ? _scrollToBottomThreshold / _viewportHeight : 0.0;

    final anchorPositions = positions.where((p) => p.index == anchorIndex);
    bool anchorNearBottom;
    if (anchorPositions.isNotEmpty) {
      // Anchor visible — use leading edge fraction check.
      anchorNearBottom =
          anchorPositions.first.itemLeadingEdge < 1.0 + thresholdFraction;
    } else {
      // Anchor off-screen — check the item right before the anchor.
      // trailingEdge is in viewport fractions: 1.0 = viewport bottom,
      // 3.0 = 2 viewports below. We're "near the bottom" when the
      // pre-anchor item's trailing edge is close to 1.0 (within threshold).
      final preAnchor = positions.where((p) => p.index == anchorIndex - 1);
      if (preAnchor.isNotEmpty) {
        anchorNearBottom =
            preAnchor.first.itemTrailingEdge < 1.0 + thresholdFraction;
      } else {
        anchorNearBottom = false;
      }
    }

    final shouldShow = !anchorNearBottom;
    _setShowButton(shouldShow);

    if (shouldShow && _autoFollow) {
      _autoFollow = false;
    }
  }

  void onNewUserMessage() {
    _inExchange = true;
    _autoFollow = false;
    _anchoredToBottom = false;
    exchangeCountNotifier.value = 1 + _pendingAICount;
    _pendingAICount = 0;
    _isProgrammaticScroll = true;
    _setShowButton(false);

    _pendingExchangeJump = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_pendingExchangeJump ||
            !itemScrollController.isAttached ||
            _totalItemCount <= 1) {
          // If _pendingExchangeJump is false, updateItemCount already handled
          // the jump — skip to avoid double-jump. Otherwise, leave the flag
          // true so updateItemCount can retry when the item count catches up.
          _isProgrammaticScroll = _pendingExchangeJump;
          return;
        }
        _pendingExchangeJump = false;
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
  void onUserTouch() {
    _autoFollow = false;
    if (_anchoredToBottom) {
      _anchoredToBottom = false;
      _reanchorToVisibleItem();
    }
  }

  /// Called by the widget on user drag (onPointerMove).
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
    _pendingExchangeJump = false;
  }

  void updateItemCount(int count) {
    final prev = _totalItemCount;
    _totalItemCount = count;

    // Handle async state managers (e.g. Riverpod) where onNewUserMessage()
    // fires before the widget rebuilds with updated messages. The original
    // post-frame jump bails out when _totalItemCount <= 1, so we retry here
    // once the item count catches up.
    if (_pendingExchangeJump && prev <= 1 && count > 1) {
      _pendingExchangeJump = false;
      _isProgrammaticScroll = true;
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
    }
  }

  double get _bottomAlignment {
    if (_viewportHeight > 0 && _bottomPadding > 0) {
      return 1.0 - (_bottomPadding / _viewportHeight);
    }
    return 1.0;
  }

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
      itemScrollController.jumpTo(
        index: _totalItemCount - 1,
        alignment: _bottomAlignment,
      );
      return;
    }

    final targetEdge = _bottomAlignment;
    final currentEdge = anchorPos.itemLeadingEdge;
    final delta = (currentEdge - targetEdge) * _viewportHeight;

    if (delta.abs() < autoFollowDeltaThreshold) return;

    scrollOffsetController.animateScroll(
      offset: delta,
      duration: Duration.zero,
    );
    _setShowButton(false);
  }

  Future<void> scrollToBottom() async {
    if (!itemScrollController.isAttached || _totalItemCount <= 1) return;

    _isProgrammaticScroll = true;
    _anchoredToBottom = true;
    _setShowButton(false);

    if (_inExchange && autoFollowOnScrollToBottom) {
      _autoFollow = true;
    }

    await itemScrollController.scrollTo(
      index: _totalItemCount - 1,
      alignment: _bottomAlignment,
      duration: scrollToBottomDuration,
      curve: scrollToBottomCurve,
    );

    _isProgrammaticScroll = false;
    _onPositionsChanged();
  }

  void jumpToBottom() {
    if (!itemScrollController.isAttached || _totalItemCount <= 1) return;
    _anchoredToBottom = true;
    itemScrollController.jumpTo(
      index: _totalItemCount - 1,
      alignment: _bottomAlignment,
    );
    _setShowButton(false);
  }

  void dispose() {
    _showButtonDebounceTimer?.cancel();
    itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    showScrollToBottom.dispose();
    exchangeCountNotifier.dispose();
  }
}
