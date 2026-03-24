## 0.1.2

- Fix race condition when `onAIResponseStarted()` fires before `onNewUserMessage()`
- Make `exchangeCount` reactive via `exchangeCountNotifier` (ValueNotifier) — widget now rebuilds automatically when exchange state changes
- Add order-independent buffering: controller correctly handles any call order between user message and AI response events
- Clamp exchange count to message list length for safety
- Works correctly with provider-based state management (Riverpod, Bloc, etc.) — no longer requires `setState` to drive rebuilds

## 0.1.1

- Fix layout jump when AI response completes or follow-up content loads
- `onAIResponseComplete()` no longer resets exchange group — it persists until the next `onNewUserMessage()` call

## 0.1.0

- Initial release
- `BetterChatScrollView` widget with generic message type support
- `ChatScrollController` for managing scroll state during AI streaming
- Exchange grouping: user message pins to top, AI response grows downward
- Automatic scroll-to-bottom button with customizable widget
- Stable viewport when user is scrolled up during streaming
- Keyboard-aware layout handling
- Separator builder support
