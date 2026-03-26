## 0.2.1

- Animate scroll to exchange on new user message — replaces instant `jumpTo` with smooth `scrollTo`
- Add configurable `scrollToExchangeDuration` and `scrollToExchangeCurve` on `ChatScrollController`

## 0.2.0

- Fix `scrollToBottomThreshold` not working for large values — button now correctly respects threshold when anchor item is off-screen
- Fix keyboard viewport adjustment using near-instant 16ms animation — now uses configurable smooth 150ms transition
- Document auto-follow 16ms as intentional — minimum valid duration for frame-synced tracking (`animateScroll` requires `> Duration.zero`)
- Add `showScrollToBottomButton` toggle on `BetterChatScrollView` (default: true)
- Add configurable `scrollToBottomDuration`, `scrollToBottomCurve`, `showButtonDebounce`, `keyboardAdjustDuration`, and `autoFollowDeltaThreshold` on `ChatScrollController`
- Add configurable `scrollToBottomFadeDuration` and `physics` on `BetterChatScrollView`
- Fix separator logic duplication in `_buildItem`
- Remove unused `MeasureSize` widget

## 0.1.8

- Fix keyboard not pushing content up when viewing long messages in existing chats

## 0.1.7

- Fix double-jump when `onNewUserMessage()` is called on initial mount (e.g. `initState` + `postFrameCallback`)

## 0.1.6

- Fix first message not scrolling to top in empty chats when using async state managers (Riverpod, Bloc, etc.)
- Add empty chat example with placeholder UI

## 0.1.5

- Add Android platform support to example app

## 0.1.4

- Fix scroll-to-bottom threshold not working — anchor now 1px tall so `ItemPositionsListener` always reports it
- Fix scroll-to-bottom button briefly flashing on send — debounce show by 150ms
- Replace `scrollToBottomWidget` with `scrollToBottomBuilder` — builder receives the `onPressed` callback

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
