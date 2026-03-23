import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

  void onNewUserMessage() {
    _exchangeCount = 1;
    _isUserScrolledUp = false;
    showScrollToBottom.value = false;
    _needsScrollToBottom = true;
    // Schedule jump after the next 2 frames (layout needs to settle with new exchange).
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(0);
        }
      });
    });
  }

  void onAIResponseStarted() {
    _exchangeCount += 1;
    _needsScrollToBottom = !_isUserScrolledUp;
  }

  void onNewAIContent() {}

  void onAIResponseComplete() {}

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

  void jumpToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(0);
  }

  bool consumeScrollToBottom() {
    if (_needsScrollToBottom) {
      _needsScrollToBottom = false;
      return true;
    }
    return false;
  }

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
