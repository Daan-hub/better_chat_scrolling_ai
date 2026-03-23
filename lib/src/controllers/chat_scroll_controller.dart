import 'package:flutter/material.dart';

class ChatScrollController {
  ChatScrollController({
    double scrollToBottomThreshold = 50.0,
  }) : _scrollToBottomThreshold = scrollToBottomThreshold;

  final double _scrollToBottomThreshold;
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<bool> showScrollToBottom = ValueNotifier(false);

  bool _isUserScrolledUp = false;
  bool get isUserScrolledUp => _isUserScrolledUp;

  int _exchangeCount = 0;
  int get exchangeCount => _exchangeCount;

  bool _needsScrollToBottom = false;

  /// Call after inserting a user message at messages[0].
  /// Always starts a fresh exchange (resets count to 1).
  void onNewUserMessage() {
    // Start a fresh exchange with just this user message.
    _exchangeCount = 1;
    _isUserScrolledUp = false;
    showScrollToBottom.value = false;
    _needsScrollToBottom = true;
  }

  /// Call after inserting an empty AI response message at messages[0].
  void onAIResponseStarted() {
    _exchangeCount += 1;
    _needsScrollToBottom = !_isUserScrolledUp;
  }

  /// Call after each streaming token update to messages[0].
  void onNewAIContent() {
    // Nothing needed — padding recalc + offset 0 handles it.
  }

  /// Call when AI response is complete.
  void onAIResponseComplete() {
    // Don't reset exchange count — layout should persist.
  }

  /// Smooth scroll to bottom (for the button).
  void scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _isUserScrolledUp = false;
    showScrollToBottom.value = false;
  }

  /// Jump to bottom instantly (for after sending).
  void jumpToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(0);
  }

  /// Returns true if a scroll-to-bottom is pending.
  bool consumeScrollToBottom() {
    if (_needsScrollToBottom) {
      _needsScrollToBottom = false;
      return true;
    }
    return false;
  }

  /// Handle user scroll notifications from NotificationListener.
  void handleUserScroll(UserScrollNotification notification) {
    if (!scrollController.hasClients) return;
    final offset = scrollController.offset;
    if (offset > _scrollToBottomThreshold) {
      if (!_isUserScrolledUp) {
        _isUserScrolledUp = true;
        showScrollToBottom.value = true;
      }
    } else {
      if (_isUserScrolledUp) {
        _isUserScrolledUp = false;
        showScrollToBottom.value = false;
      }
    }
  }

  /// Handle general scroll notifications (for fling-to-bottom detection).
  void handleScrollEnd() {
    if (!scrollController.hasClients) return;
    final offset = scrollController.offset;
    if (offset <= _scrollToBottomThreshold && _isUserScrolledUp) {
      _isUserScrolledUp = false;
      showScrollToBottom.value = false;
    }
  }

  void dispose() {
    scrollController.dispose();
    showScrollToBottom.dispose();
  }
}
