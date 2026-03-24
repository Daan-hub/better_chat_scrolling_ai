import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../controllers/chat_scroll_controller.dart';
import 'scroll_to_bottom_button.dart';

class BetterChatScrollView<T> extends StatefulWidget {
  final List<T> messages;
  final Widget Function(BuildContext context, T message, int index) messageBuilder;
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
  State<BetterChatScrollView<T>> createState() => _BetterChatScrollViewState<T>();
}

class _BetterChatScrollViewState<T> extends State<BetterChatScrollView<T>> {
  double _viewportHeight = 0;
  bool _initialLayoutDone = false;

  ChatScrollController get _ctrl => widget.controller;

  @override
  void didUpdateWidget(BetterChatScrollView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.length != oldWidget.messages.length) {
      // Defer check to after the current build cycle — onNewUserMessage()
      // hasn't been called yet when didUpdateWidget fires.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_ctrl.consumeScrollToBottom()) {
          _ctrl.jumpToBottom();
        }
      });
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
    final exchangeCount = _ctrl.exchangeCount;
    final regularCount = widget.messages.length - exchangeCount;
    final itemCount = (exchangeCount > 0 ? 1 : 0) + regularCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;
        if (!_initialLayoutDone) {
          _initialLayoutDone = true;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _ctrl.jumpToBottom();
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
                        physics: const ClampingScrollPhysics(),
                        padding: widget.padding,
                        itemCount: itemCount,
                        itemBuilder: _buildItem,
                        separatorBuilder: (context, index) {
                          return widget.separatorBuilder!(context, index);
                        },
                      )
                    : ListView.builder(
                        reverse: true,
                        controller: _ctrl.scrollController,
                        physics: const ClampingScrollPhysics(),
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
    final exchangeCount = _ctrl.exchangeCount;
    if (index == 0 && exchangeCount > 0) {
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
            for (int i = exchangeCount - 1; i >= 0; i--) ...[
              if (i < exchangeCount - 1 && widget.separatorBuilder != null) widget.separatorBuilder!(context, 0),
              widget.messageBuilder(context, widget.messages[i], i),
            ],
          ],
        ),
      );
    }

    // Regular messages (offset by exchange group)
    final msgIndex = exchangeCount > 0 ? index - 1 + exchangeCount : index;
    if (msgIndex >= widget.messages.length) return const SizedBox.shrink();
    return widget.messageBuilder(context, widget.messages[msgIndex], msgIndex);
  }
}
