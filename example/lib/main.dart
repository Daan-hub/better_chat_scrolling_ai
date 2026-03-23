import 'package:flutter/material.dart';

import 'screens/chat_list_screen.dart';

void main() {
  runApp(const BetterChatScrollingExampleApp());
}

class BetterChatScrollingExampleApp extends StatelessWidget {
  const BetterChatScrollingExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better Chat Scrolling',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: ChatListScreen(),
    );
  }
}
