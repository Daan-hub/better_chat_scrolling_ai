import 'dart:async';

import 'package:better_chat_scrolling_ai/better_chat_scrolling_ai.dart';
import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/fake_ai_service.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String title;
  final List<Message> initialMessages;

  const ChatScreen({
    super.key,
    required this.title,
    required this.initialMessages,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatScrollController _chatScrollController;
  late final TextEditingController _textController;
  late List<Message> _messages;
  StreamSubscription<String>? _aiStream;
  bool _isAIResponding = false;
  int _nextId = 100;

  @override
  void initState() {
    super.initState();
    _chatScrollController = ChatScrollController(
      scrollToExchangeDuration: const Duration(milliseconds: 500),
    )..init();
    _textController = TextEditingController();
    // Copy initial messages (newest first).
    _messages = List.of(widget.initialMessages);
  }

  @override
  void dispose() {
    _aiStream?.cancel();
    _chatScrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    // Insert user message at index 0 (newest).
    setState(() {
      _messages.insert(
        0,
        Message(
          id: '${_nextId++}',
          role: MessageRole.user,
          content: text,
        ),
      );
    });

    // Tell the controller about the new user message.
    _chatScrollController.onNewUserMessage();

    // Start AI response.
    _startAIResponse(text);
  }

  void _startAIResponse(String userMessage) {
    // Insert empty AI message at index 0.
    final aiMessage = Message(
      id: '${_nextId++}',
      role: MessageRole.assistant,
      content: '',
    );

    setState(() {
      _messages.insert(0, aiMessage);
      _isAIResponding = true;
    });

    _chatScrollController.onAIResponseStarted();

    _aiStream?.cancel();
    _aiStream = FakeAIService.streamResponse(userMessage).listen(
      (token) {
        setState(() {
          aiMessage.content += token;
        });
        _chatScrollController.onNewAIContent();
      },
      onDone: () {
        setState(() {
          _isAIResponding = false;
        });
        _chatScrollController.onAIResponseComplete();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                        ),
                      ],
                    ),
                  )
                : BetterChatScrollView<Message>(
                    messages: _messages,
                    controller: _chatScrollController,
                    hideScrollToBottomWhenKeyboardOpen: false,
                    scrollToBottomBottomOffset: 12,
                    scrollToBottomThreshold: 50,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    messageBuilder: (context, message, index) {
                      return MessageBubble(message: message);
                    },
                  ),
          ),
          ChatInputBar(
            controller: _textController,
            onSend: _handleSend,
            enabled: !_isAIResponding,
          ),
        ],
      ),
    );
  }
}
