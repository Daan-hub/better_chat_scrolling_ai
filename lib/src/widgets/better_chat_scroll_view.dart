import 'package:flutter/material.dart';

import '../controllers/chat_scroll_controller.dart';
import 'measure_size.dart';
import 'scroll_to_bottom_button.dart';

class BetterChatScrollView<T> extends StatefulWidget {
  /// Messages list ordered **newest first**.
  final List<T> messages;

  /// Builder for each message widget. Receives context, message, and index.
  final Widget Function(BuildContext context, T message, int index)
      messageBuilder;

  /// Controller managing scroll state and exchange tracking.
  final ChatScrollController controller;

  /// Optional custom scroll-to-bottom button widget.
  /// If null, a default circular arrow-down button is used.
  final Widget? scrollToBottomWidget;

  /// Padding around messages inside the list.
  final EdgeInsets? padding;

  /// How far from the bottom (in pixels) before showing the scroll-to-bottom button.
  final double scrollToBottomThreshold;

  /// Optional separator between messages.
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
  final Map<int, double> _messageHeights = {};
  double _bottomPadding = 0;
  double _viewportHeight = 0;
  bool _initialLayoutDone = false;
  int _prevMessageCount = 0;
  final _separatorHeights = <int, double>{};

  ChatScrollController get _ctrl => widget.controller;

  @override
  void didUpdateWidget(BetterChatScrollView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When new messages are inserted, the index-based height map is stale.
    // Clear it so MeasureSize re-reports correct heights for new indices.
    if (widget.messages.length != oldWidget.messages.length) {
      _messageHeights.clear();
      _separatorHeights.clear();
    }
    _scheduleRecalc();
  }

  void _scheduleRecalc() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recalcBottomPadding();

      if (_ctrl.consumeScrollToBottom()) {
        // Double post-frame: first let layout settle, then jump.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _ctrl.jumpToBottom();
        });
      }
    });
  }

  void _onMessageSizeChanged(int index, Size size) {
    final oldHeight = _messageHeights[index];
    if (oldHeight == size.height) return;
    _messageHeights[index] = size.height;
    _recalcBottomPadding();

    if (!_ctrl.isUserScrolledUp && _ctrl.scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_ctrl.scrollController.hasClients &&
            _ctrl.scrollController.offset > 0.5 &&
            !_ctrl.isUserScrolledUp) {
          _ctrl.jumpToBottom();
        }
      });
    }
  }

  void _onSeparatorSizeChanged(int index, Size size) {
    final oldHeight = _separatorHeights[index];
    if (oldHeight == size.height) return;
    _separatorHeights[index] = size.height;
    _recalcBottomPadding();
  }

  void _recalcBottomPadding() {
    if (_viewportHeight <= 0) return;

    final exchangeCount = _ctrl.exchangeCount;
    if (exchangeCount == 0) {
      if (_bottomPadding != 0) {
        setState(() => _bottomPadding = 0);
      }
      return;
    }

    // Sum heights of messages in the current exchange.
    double exchangeHeight = 0;
    for (int i = 0; i < exchangeCount; i++) {
      exchangeHeight += _messageHeights[i] ?? 0;
    }

    // Add separator heights between exchange messages.
    // In the list, separators between exchange messages are at indices 1..exchangeCount-1
    // (index 0 separator is between padding and first msg = hidden).
    for (int i = 0; i < exchangeCount - 1; i++) {
      exchangeHeight += _separatorHeights[i] ?? 12; // default estimate 12px
    }

    // Subtract list padding top/bottom from viewport (they eat into available space).
    double availableHeight = _viewportHeight;
    if (widget.padding != null) {
      availableHeight -= widget.padding!.vertical;
    }

    final newPadding = (availableHeight - exchangeHeight).clamp(0.0, availableHeight);

    if ((newPadding - _bottomPadding).abs() > 0.5) {
      setState(() => _bottomPadding = newPadding);
    }
  }

  bool _handleUserScroll(UserScrollNotification notification) {
    _ctrl.handleUserScroll(notification);
    return false;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      _ctrl.handleScrollEnd();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.messages.length + 1;

    // Detect if messages were added (for initial large padding on new exchange).
    if (widget.messages.length != _prevMessageCount) {
      final added = widget.messages.length > _prevMessageCount;
      _prevMessageCount = widget.messages.length;
      if (added && _ctrl.exchangeCount > 0 && _viewportHeight > 0) {
        // If exchange just started and we haven't measured yet, use max padding
        // to avoid flicker (messages appear at top from the start).
        final exchangeCount = _ctrl.exchangeCount;
        double measuredHeight = 0;
        bool allMeasured = true;
        for (int i = 0; i < exchangeCount; i++) {
          final h = _messageHeights[i];
          if (h == null) {
            allMeasured = false;
          } else {
            measuredHeight += h;
          }
        }
        if (!allMeasured) {
          double availableHeight = _viewportHeight;
          if (widget.padding != null) {
            availableHeight -= widget.padding!.vertical;
          }
          _bottomPadding =
              (availableHeight - measuredHeight).clamp(0.0, availableHeight);
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final newViewportHeight = constraints.maxHeight;
        if (newViewportHeight != _viewportHeight) {
          _viewportHeight = newViewportHeight;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _recalcBottomPadding();
            if (!_initialLayoutDone) {
              _initialLayoutDone = true;
              _ctrl.jumpToBottom();
            }
          });
        }

        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: NotificationListener<UserScrollNotification>(
                onNotification: _handleUserScroll,
                child: widget.separatorBuilder != null
                    ? ListView.separated(
                        reverse: true,
                        controller: _ctrl.scrollController,
                        padding: widget.padding,
                        itemCount: itemCount,
                        itemBuilder: _buildItem,
                        separatorBuilder: (context, index) {
                          if (index == 0) {
                            return const SizedBox.shrink();
                          }
                          final sepIndex = index - 1;
                          final separator =
                              widget.separatorBuilder!(context, sepIndex);
                          // Measure separator heights for exchange padding calc.
                          if (sepIndex < (_ctrl.exchangeCount)) {
                            return MeasureSize(
                              onChange: (size) =>
                                  _onSeparatorSizeChanged(sepIndex, size),
                              child: separator,
                            );
                          }
                          return separator;
                        },
                      )
                    : ListView.builder(
                        reverse: true,
                        controller: _ctrl.scrollController,
                        padding: widget.padding,
                        itemCount: itemCount,
                        itemBuilder: _buildItem,
                      ),
              ),
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

  Widget _buildItem(BuildContext context, int index) {
    if (index == 0) {
      return SizedBox(height: _bottomPadding);
    }

    final messageIndex = index - 1;
    final message = widget.messages[messageIndex];

    return MeasureSize(
      onChange: (size) => _onMessageSizeChanged(messageIndex, size),
      child: widget.messageBuilder(context, message, messageIndex),
    );
  }
}
