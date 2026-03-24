import 'package:flutter/material.dart';

import '../models/message.dart';
import 'chat_screen.dart';

class _ChatPreview {
  final String title;
  final String subtitle;
  final List<Message> messages;

  _ChatPreview({
    required this.title,
    required this.subtitle,
    required this.messages,
  });
}

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  final List<_ChatPreview> _chats = [
    _ChatPreview(
      title: 'Flutter Basics',
      subtitle: 'What is the Widget tree?',
      messages: [
        Message(
            id: '11',
            role: MessageRole.assistant,
            content: 'Hello! I\'d be happy to help you learn Flutter. What would you like to know?'),
        Message(id: '10', role: MessageRole.user, content: 'What is the Widget tree?'),
        Message(
          id: '9',
          role: MessageRole.user,
          content: 'What is the Widget tree?',
        ),
        Message(
          id: '8',
          role: MessageRole.assistant,
          content: 'Sure! You can hot reload by pressing "r" in your terminal when running with "flutter run".',
        ),
        Message(
          id: '7',
          role: MessageRole.user,
          content: 'How can I refresh my app quickly during development?',
        ),
        Message(
          id: '6',
          role: MessageRole.assistant,
          content: 'The Widget tree in Flutter is a hierarchical structure where each widget '
              'describes part of the user interface. Widgets are immutable blueprints — '
              'when state changes, Flutter rebuilds the affected widgets and efficiently '
              'updates only what changed on screen.',
        ),
        Message(id: '5', role: MessageRole.user, content: 'What is the Widget tree?'),
        Message(
          id: '4',
          role: MessageRole.assistant,
          content: 'StatelessWidget is for static content that never changes. StatefulWidget '
              'is for dynamic content that can change over time via setState().',
        ),
        Message(
          id: '3',
          role: MessageRole.user,
          content: 'What\'s the difference between Stateless and Stateful?',
        ),
        Message(
          id: '2',
          role: MessageRole.assistant,
          content: 'Hello! I\'d be happy to help you learn Flutter. What would you like to know?',
        ),
        Message(id: '1', role: MessageRole.user, content: 'Hi! I want to learn Flutter.'),
      ],
    ),
    _ChatPreview(
      title: 'Performance Tips',
      subtitle: 'How do I optimize my app?',
      messages: [
        Message(
          id: '6',
          role: MessageRole.assistant,
          content: 'Using the Flutter inspector can help you analyze rendering performance issues visually.',
        ),
        Message(
          id: '5',
          role: MessageRole.user,
          content: 'Any tools for debugging performance issues?',
        ),
        Message(
          id: '4',
          role: MessageRole.assistant,
          content: 'Here are key optimization tips:\n\n'
              '1. Use const constructors\n'
              '2. Use ListView.builder for long lists\n'
              '3. Minimize setState scope\n'
              '4. Use RepaintBoundary\n'
              '5. Profile with DevTools',
        ),
        Message(id: '3', role: MessageRole.user, content: 'How do I optimize my Flutter app?'),
        Message(
          id: '2',
          role: MessageRole.assistant,
          content: 'Of course! Performance is an important topic. Ask away!',
        ),
        Message(id: '1', role: MessageRole.user, content: 'Can you help with performance?'),
      ],
    ),
    _ChatPreview(
      title: 'State Management',
      subtitle: 'Tell me about Riverpod',
      messages: [
        Message(
          id: '4',
          role: MessageRole.assistant,
          content: 'You can also try Bloc or Provider for other state management approaches in Flutter.',
        ),
        Message(
          id: '3',
          role: MessageRole.user,
          content: 'Are there other state management solutions?',
        ),
        Message(
          id: '2',
          role: MessageRole.assistant,
          content: 'Riverpod is a reactive state management solution. It improves on Provider with '
              'compile-time safety, no widget tree dependency, and better async support.',
        ),
        Message(id: '1', role: MessageRole.user, content: 'Tell me about Riverpod'),
      ],
    ),
    _ChatPreview(
      title: 'Short Chat',
      subtitle: 'Hi!',
      messages: [
        Message(
          id: '3',
          role: MessageRole.assistant,
          content: 'Nice to meet you! 😊',
        ),
        Message(
          id: '2',
          role: MessageRole.assistant,
          content: 'Hello! How can I help you today?',
        ),
        Message(id: '1', role: MessageRole.user, content: 'Hi!'),
      ],
    ),
    _ChatPreview(
      title: 'Empty Chat',
      subtitle: 'Start a fresh conversation',
      messages: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: _chats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                chat.messages.isEmpty ? Icons.add : Icons.message,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(chat.title),
            subtitle: Text(
              chat.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    title: chat.title,
                    initialMessages: chat.messages
                        .map((m) => Message(
                              id: m.id,
                              role: m.role,
                              content: m.content,
                              timestamp: m.timestamp,
                            ))
                        .toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
