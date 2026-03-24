# better_chat_scrolling_ai

A drop-in Flutter widget that handles chat scrolling the way AI chat apps should — user messages pin to the top, AI responses stream downward, and the viewport stays rock-solid when users scroll up.

Built for AI chat interfaces where responses stream in token-by-token.

## The Problem

Building a chat UI that streams AI responses is deceptively hard:

- The user's message should jump to the **top** of the screen after sending
- The AI response should grow **downward** beneath it
- The viewport must **not jump** when the user is scrolled up reading history
- A "scroll to bottom" button should appear/disappear at the right times
- The keyboard opening shouldn't break everything

Most chat packages use `reverse: true` ListView hacks that fall apart during streaming. This package solves all of it.

## How It Works

```
After user sends "What is Flutter?":

┌──────────────────┐        ┌──────────────────┐
│      AppBar      │        │      AppBar      │
├──────────────────┤        ├──────────────────┤
│ [User] What is ──┤        │ [User] What is ──┤  ← pinned at top
│       Flutter?   │        │       Flutter?   │
│                  │        │                  │
│                  │        │ [AI] Flutter is  │  ← streams downward
│  (empty space)   │        │  an open-source  │
│                  │        │  UI toolkit...   │
│                  │        │                  │
├──────────────────┤        ├──────────────────┤
│ [Type a msg..] ➤ │        │ [Type a msg..] ➤ │
└──────────────────┘        └──────────────────┘
   Just sent                   AI streaming in
```

The widget uses a `ConstrainedBox` exchange group that ensures the current user message + AI response always fill at least the full viewport height, keeping the user message anchored at the top while the AI response grows below it.

## Installation

```yaml
dependencies:
  better_chat_scrolling_ai: ^0.1.0
```

```dart
import 'package:better_chat_scrolling_ai/better_chat_scrolling_ai.dart';
```

## Quick Start

```dart
class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatScrollController _scrollController;
  final List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ChatScrollController()..init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BetterChatScrollView<Message>(
            messages: _messages,
            controller: _scrollController,
            messageBuilder: (context, message, index) {
              return MessageBubble(message: message);
            },
          ),
        ),
        ChatInputBar(onSend: _handleSend),
      ],
    );
  }
}
```

## Hooking Up the Controller

The controller needs to know about message lifecycle events. Call these methods at the right time:

```dart
// 1. User sends a message
void _handleSend(String text) {
  setState(() {
    _messages.insert(0, Message(role: 'user', content: text));
  });
  _scrollController.onNewUserMessage(); // pins user msg to top

  _startAIResponse(text);
}

// 2. AI response starts streaming
void _startAIResponse(String prompt) {
  final aiMessage = Message(role: 'assistant', content: '');
  setState(() {
    _messages.insert(0, aiMessage);
  });
  _scrollController.onAIResponseStarted(); // adds AI msg to exchange group

  aiService.stream(prompt).listen(
    (token) {
      setState(() {
        aiMessage.content += token;
      });
      _scrollController.onNewAIContent(); // notifies of new content
    },
    onDone: () {
      _scrollController.onAIResponseComplete(); // ends the exchange
    },
  );
}
```

### Controller Methods

| Method | When to call |
|---|---|
| `init()` | After creating the controller (usually in `initState`) |
| `onNewUserMessage()` | After inserting the user's message into the list |
| `onAIResponseStarted()` | After inserting the empty AI message into the list |
| `onNewAIContent()` | After each streamed token updates the AI message |
| `onAIResponseComplete()` | When the AI response finishes streaming |
| `scrollToBottom()` | Programmatically scroll to bottom (animated) |
| `jumpToBottom()` | Programmatically jump to bottom (instant) |
| `dispose()` | In your widget's `dispose()` method |

## Widget Properties

```dart
BetterChatScrollView<T>(
  // Required
  messages: List<T>,               // newest message at index 0
  messageBuilder: (ctx, msg, i) => Widget,
  controller: ChatScrollController,

  // Optional
  padding: EdgeInsets?,             // list padding
  separatorBuilder: (ctx, i) => Widget, // space between messages
  scrollToBottomBuilder: (onPressed) => Widget, // custom button (receives callback)
  scrollToBottomAlignment: Alignment, // button position (default: center)
  scrollToBottomBottomOffset: double, // distance from bottom edge (default: 8)
  scrollToBottomThreshold: double,  // offset before button shows (default: 50)
)
```

## Message Order

Messages must be ordered **newest first** (index 0 = most recent). This matches how most chat backends return messages and how the internal exchange grouping works.

```dart
// Correct: newest at index 0
_messages.insert(0, newMessage);

// Wrong: oldest at index 0
_messages.add(newMessage);
```

## Scroll-to-Bottom Button

A default circular button with a down arrow appears when the user scrolls up more than 50px. You can customize it:

```dart
BetterChatScrollView<Message>(
  // Custom button design (onPressed is provided by the package)
  scrollToBottomBuilder: (onPressed) => FloatingActionButton.small(
    onPressed: onPressed,
    child: Icon(Icons.arrow_downward),
  ),
  // Position: bottomLeft, center (default), or bottomRight
  scrollToBottomAlignment: Alignment.centerRight,
  // Distance from bottom edge
  scrollToBottomBottomOffset: 12,
  // Show after 100px of scrolling (default: 50)
  scrollToBottomThreshold: 100,
  // ...
)
```

## Key Behaviors

**User sends a message:**
- All old messages push off-screen above
- User message pins to the top of the viewport
- Empty space fills below until AI responds

**AI streams a response:**
- Text appears below the user message, growing downward
- User message stays pinned at the top
- Empty space shrinks as the response grows
- When the response exceeds the viewport, latest text stays visible at the bottom

**User scrolled up during streaming:**
- Viewport stays completely stable — nothing moves
- Scroll-to-bottom button visible
- User can tap the button or scroll back manually

**Keyboard opens:**
- Chat area shrinks, messages stay visible
- No jumping or layout glitches

## Requirements

- Flutter >= 3.10.0
- Dart >= 3.0.0

## License

MIT

## Detailed Flow Documentation

For a comprehensive breakdown of every scroll scenario (13 flows with diagrams), see [FLOWS.md](FLOWS.md).
