## 0.1.3

- Fix race condition when `onAIResponseStarted()` fires before `onNewUserMessage()` — order-independent buffering
- Make `exchangeCount` reactive via `exchangeCountNotifier` (ValueNotifier) — works with Riverpod, Bloc, etc.
- Fix layout jump when AI response completes or follow-up content loads
- Fix scroll-to-bottom not reaching true bottom — accounts for list bottom padding
- Fix `scrollToBottomThreshold` not being used — button now respects threshold before appearing
- Fix scroll-to-bottom button briefly flashing when sending a message
- Fix chat not starting at true bottom when opened
- Add auto-follow mode: pressing scroll-to-bottom during streaming keeps viewport at bottom; touch/drag cancels immediately
- Add `autoFollowOnScrollToBottom` parameter on `ChatScrollController` (default: true)
- Add `scrollToBottomBuilder` — custom button builder that receives the `onPressed` callback
- Add `scrollToBottomAlignment` — position button left, center (default), or right
- Add `scrollToBottomBottomOffset` — control distance from bottom edge (default: 8)
- `scrollToBottom()` is now async (returns `Future<void>`)

## 0.1.2

- Fix race condition when `onAIResponseStarted()` fires before `onNewUserMessage()`
- Make `exchangeCount` reactive via `exchangeCountNotifier` (ValueNotifier)

## 0.1.1

- Fix layout jump when AI response completes or follow-up content loads

## 0.1.0

- Initial release
- `BetterChatScrollView` widget with generic message type support
- `ChatScrollController` for managing scroll state during AI streaming
- Exchange grouping: user message pins to top, AI response grows downward
- Automatic scroll-to-bottom button with customizable widget
- Stable viewport when user is scrolled up during streaming
- Keyboard-aware layout handling
- Separator builder support
