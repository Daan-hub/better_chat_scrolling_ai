import 'dart:math';

class FakeAIService {
  static final _random = Random();

  static final _responses = [
    // Shorter response as before
    'Flutter is an open-source UI software development toolkit created by Google. '
        'It is used to develop cross-platform applications for Android, iOS, Linux, '
        'macOS, Windows, and the web from a single codebase. Flutter uses Dart as '
        'its programming language and provides a rich set of pre-designed widgets '
        'that follow Material Design and Cupertino guidelines.',
    // 5x longer response
    'That\'s a great question! The key difference lies in how state is managed. '
        'StatelessWidget is immutable — once built, it cannot change. StatefulWidget, '
        'on the other hand, maintains a State object that can change over time and '
        'trigger rebuilds. Use StatelessWidget for static content and StatefulWidget '
        'when you need to track changes. '
        'To elaborate further, StatelessWidgets are best suited for static UIs that don\'t depend on any user interaction or input—'
        'they are built once and never updated unless their parent is rebuilt. When choosing between widgets, it\'s important to '
        'consider how often your UI actually needs to update: overusing StatefulWidgets can negatively impact performance. '
        'On the other hand, StatefulWidgets come in handy when you need to update your UI based on things like user input, timers, '
        'animations, or data fetched from a network request. Importantly, the State object lives for the lifetime of the widget and '
        'is only disposed when the widget is removed from the tree. This means you can preserve variables, listeners, and controllers '
        'across rebuilds. In larger apps, understanding when to use each widget type helps maintain clean, efficient, and maintainable code. '
        'Experienced Flutter developers often favor StatelessWidgets where possible and only use StatefulWidgets for the minimal part of the UI '
        'that actually needs to update. And remember: using keys appropriately is also important when dealing with widget trees that can change structure '
        'to avoid subtle bugs and ensure state is maintained as intended. If you have any more specific questions about widget lifecycle, don\'t hesitate to ask!',
    // 5x longer response
    'Here are some tips for optimizing Flutter performance:\n\n'
        '1. Use const constructors wherever possible to avoid unnecessary rebuilds.\n'
        '2. Prefer ListView.builder over ListView for long lists — it lazily builds items.\n'
        '3. Avoid calling setState on large widget trees. Instead, isolate state to smaller widgets.\n'
        '4. Use RepaintBoundary to limit repaint areas.\n'
        '5. Profile with DevTools to identify bottlenecks.\n\n'
        'These practices will help keep your app running at 60fps even with complex UIs. '
        'Let\'s dive deeper: const constructors tell Flutter that a widget and its children will never change, '
        'allowing Flutter to reuse the same instance and skip unnecessary rebuilds — this is especially beneficial for '
        'larger or deeply nested widget trees. When dealing with scrollable lists, ListView.builder not only improves memory usage '
        'but also performance, since widgets are only built as they are scrolled into view. Calling setState on the whole page or on large '
        'containers is inefficient; break down your widgets into smaller ones where state is only updated where absolutely necessary. '
        'RepaintBoundary widgets function as a performance optimization, preventing non-changing areas of your widget tree from repainting every frame. '
        'Finally, Flutter DevTools provides profiling capabilities, helping you spot dropped frames, excessive rebuilds, and heavy painting operations. '
        'Bonus advanced tips: consider using the flutter_profile build type when testing release performance. Watch out for excessive use of Opacity widgets, '
        'and prefer using ClipRect or other widgets for shapes/clipping — Opacity can be expensive, especially for animations. '
        'Cache images or icons when possible, and limit layout complexity by avoiding deep nesting. '
        'Keep your widget trees shallow and leverage const (or const factories) on as many widgets as possible. '
        'Periodically perform tree shaking to ensure you\'re only shipping code and dependencies you need.',
    // Shorter response as before
    'Sure! I\'d be happy to help you with that. Let me walk you through the process step by step.',
    // 5x longer response
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
        'across rebuilds), and why you should keep your build methods lean. '
        'For a deeper look: the Widget tree provides the configuration, describing what the UI should look like. '
        'Elements persist between widget builds and can retain state, allowing widgets to update efficiently. '
        'RenderObjects do the heavy lifting for painting and layout. Efficient UI updates are made possible because '
        'the framework only updates those render objects whose configuration has changed. When you use keys, such as ValueKey, '
        'ObjectKey, or GlobalKey, you provide hints to Flutter on how to efficiently match and preserve state between widget rebuilds, '
        'especially when working with lists or changing hierarchy. '
        'Building lean and focused build methods leads to faster rebuilds and better modularity. As your app grows, separating logic into smaller widgets and using '
        'InheritedWidgets, Providers, or Riverpod can further improve structure and performance.\n\n'
        'As you become more familiar with how widgets and elements work together, you\'ll be able to diagnose layout or state issues more efficiently and avoid performance pitfalls.',
    // 5x longer response
    'Absolutely! Riverpod is a reactive state management solution for Flutter. '
        'It builds on the concepts of Provider but with significant improvements:\n\n'
        '- Compile-time safety: no more ProviderNotFoundException at runtime\n'
        '- No dependency on the widget tree: providers can be accessed anywhere\n'
        '- Support for multiple providers of the same type\n'
        '- Built-in support for async operations\n'
        '- Easy testing and overriding\n\n'
        'The core concept is simple: you declare providers that hold state, and widgets '
        'watch those providers to automatically rebuild when the state changes. '
        'Diving much deeper: Riverpod\'s architecture fully decouples the state management layer from the widget tree, '
        'which allows you to read or manipulate providers from business logic, services, or even background tasks — something other solutions struggle with. '
        'Riverpod offers enhanced safety through compile-time checks, dramatically improving error diagnosis and maintenance in larger projects. '
        'Its support for family and autoDispose modifiers gives you fine control over provider scope, caching, and automatic cleanup, which is especially useful for '
        'resource management in advanced apps. With robust FutureProvider and StreamProvider types, you can seamlessly work with asynchronous data, reducing boilerplate and complexity. '
        'Riverpod also excels at testability: you can override providers for precise, isolated unit testing, and even dynamically modify provider behavior in production to support advanced features like feature toggles. '
        'Whether you\'re building a simple todo app or a complex enterprise-grade solution, Riverpod offers a scalable and ergonomic approach to managing state, dependencies, and business logic. '
        'For even better DX, check out Riverpod Generator for code generation, hooks for more concise UI, and the latest AsyncNotifier for even more powerful async flows. '
        'The Riverpod ecosystem keeps growing, and it\'s fast becoming a best practice for state management in large Flutter codebases.',
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
