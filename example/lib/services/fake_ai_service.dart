import 'dart:math';

class FakeAIService {
  static final _random = Random();

  static final _responses = [
    'Flutter is an open-source UI software development toolkit created by Google. '
        'It is used to develop cross-platform applications for Android, iOS, Linux, '
        'macOS, Windows, and the web from a single codebase. Flutter uses Dart as '
        'its programming language and provides a rich set of pre-designed widgets '
        'that follow Material Design and Cupertino guidelines.',
    'That\'s a great question! The key difference lies in how state is managed. '
        'StatelessWidget is immutable — once built, it cannot change. StatefulWidget, '
        'on the other hand, maintains a State object that can change over time and '
        'trigger rebuilds. Use StatelessWidget for static content and StatefulWidget '
        'when you need to track changes.',
    'Here are some tips for optimizing Flutter performance:\n\n'
        '1. Use const constructors wherever possible to avoid unnecessary rebuilds.\n'
        '2. Prefer ListView.builder over ListView for long lists — it lazily builds items.\n'
        '3. Avoid calling setState on large widget trees. Instead, isolate state to smaller widgets.\n'
        '4. Use RepaintBoundary to limit repaint areas.\n'
        '5. Profile with DevTools to identify bottlenecks.\n\n'
        'These practices will help keep your app running at 60fps even with complex UIs.',
    'Sure! I\'d be happy to help you with that. Let me walk you through the process step by step.',
    'The Widget tree in Flutter is a hierarchical structure where each widget describes '
        'part of the user interface. When you call setState(), Flutter compares the new '
        'widget tree with the old one (a process called reconciliation), and only updates '
        'the parts of the actual render tree that changed. This is what makes Flutter fast — '
        'it minimizes the work needed to update the screen.\n\n'
        'The Element tree acts as a bridge between the Widget tree (which is immutable and '
        'rebuilt frequently) and the RenderObject tree (which handles the actual layout and '
        'painting). Elements are long-lived and manage the lifecycle of their corresponding '
        'widgets and render objects.\n\n'
        'Understanding this three-tree architecture is crucial for building performant '
        'Flutter applications. It explains why const widgets help performance (they can '
        'be reused without rebuilding), why keys matter (they help Flutter match elements '
        'across rebuilds), and why you should keep your build methods lean.',
    'Absolutely! Riverpod is a reactive state management solution for Flutter. '
        'It builds on the concepts of Provider but with significant improvements:\n\n'
        '- Compile-time safety: no more ProviderNotFoundException at runtime\n'
        '- No dependency on the widget tree: providers can be accessed anywhere\n'
        '- Support for multiple providers of the same type\n'
        '- Built-in support for async operations\n'
        '- Easy testing and overriding\n\n'
        'The core concept is simple: you declare providers that hold state, and widgets '
        'watch those providers to automatically rebuild when the state changes.',
  ];

  /// Streams a response word by word, simulating AI token generation.
  static Stream<String> streamResponse(String userMessage) async* {
    final response = _responses[_random.nextInt(_responses.length)];
    final words = response.split(' ');
    for (int i = 0; i < words.length; i++) {
      await Future.delayed(
        Duration(milliseconds: 20 + _random.nextInt(60)),
      );
      yield i == 0 ? words[i] : ' ${words[i]}';
    }
  }
}
