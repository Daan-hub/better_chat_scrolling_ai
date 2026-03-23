# better_chat_scrolling_ai — Complete Flow Documentation

Every flow below describes what the user sees on screen and what happens technically.

---

## How the Architecture Works

We use `ListView.builder(reverse: true)`. In a reversed list:
- **Index 0 = visual bottom** (newest message)
- **Offset 0 = scrolled to bottom**
- **`jumpTo(0)` = go to latest content**

The trick: we add a **bottom padding item at index 0** that pushes the latest exchange (user message + AI response) to the **top** of the viewport.

```
Reversed ListView layout (bottom to top):

  Index 0:   BOTTOM PADDING (empty SizedBox)    ← visual bottom
  Index 1:   messages[0] (AI response)           ← newest message
  Index 2:   messages[1] (user's sent message)   ← second newest
  ...
  Index N:   messages[N-1] (oldest)              ← visual top
```

**Padding formula:** `bottomPadding = max(0, viewportHeight - exchangeHeight)`

Where `exchangeHeight` = total height of messages in the current exchange (user msg + AI response).

**The math proof that user message stays at the top:**
- User msg sits at offset `[bottomPadding + aiHeight, bottomPadding + aiHeight + userMsgHeight]`
- Since `bottomPadding = viewportHeight - aiHeight - userMsgHeight`:
  - User msg bottom = `(vp - A - U) + A = vp - U`
  - User msg top = `vp - U + U = vp`
- So user msg is ALWAYS at `[vp - U, vp]` = the **very top of the viewport** ✓
- This holds true regardless of AI response height (as long as exchange fits in viewport)

---

## Flow 1: Opening an Existing Chat

### What the user sees:
- Messages appear at the **bottom** of the screen, above the input bar
- Newest message at the very bottom, oldest above
- If few messages → they cluster at the bottom, space above is NOT scrollable
- If many messages → scroll up to see older ones

```
FEW MESSAGES:                     MANY MESSAGES:
┌──────────────────┐              ┌──────────────────┐
│      AppBar      │              │      AppBar      │
├──────────────────┤              ├──────────────────┤
│                  │              │  [User] Msg #3   │
│                  │              │                  │
│   (empty, not    │              │  [AI] Response 3 │
│    scrollable)   │              │                  │
│                  │              │  [User] Msg #4   │
│  [AI] Hello!     │              │                  │
│                  │              │  [AI] Response 4 │
│  [User] Hi!      │              │                  │
│                  │              │  [User] Msg #5   │
│  [AI] How can I  │              │                  │
│       help?      │              │  [AI] Latest msg │
├──────────────────┤              ├──────────────────┤
│ [Type a msg..]  ➤│              │ [Type a msg..]  ➤│
└──────────────────┘              └──────────────────┘
```

### Technical:
- No active exchange → bottom padding = 0
- `reverse: true` with content < viewport → messages sit at bottom naturally
- `maxScrollExtent = 0` → can't scroll into empty space above

---

## Flow 2: User Sends a Message

### What the user sees:
1. User types "What is Flutter?" and taps send
2. **All old messages get pushed UP and off screen**
3. User's message appears at the **TOP RIGHT**
4. Below it: empty space all the way to the input bar
5. **The user message stays at the top permanently** (until response is long enough to push it off)

```
BEFORE:                            AFTER SEND:
┌──────────────────┐               ┌──────────────────┐
│      AppBar      │               │      AppBar      │
├──────────────────┤               ├──────────────────┤
│                  │               │                  │
│  [AI] Hello!     │               │  [User] What is ─┤ ← TOP RIGHT
│                  │               │        Flutter?  │
│  [User] Hi!      │               │                  │
│                  │               │                  │
│  [AI] How can I  │               │   (empty space — │
│       help?      │               │    bottom padding│
│                  │               │    fills this)   │
│  [User] What is  │               │                  │
│        Flutter?  │               │                  │
├──────────────────┤               ├──────────────────┤
│ [Type a msg..]  ➤│               │ [Type a msg..]  ➤│
└──────────────────┘               └──────────────────┘
```

### Technical:
1. New message inserted at `messages[0]`
2. `controller.onNewUserMessage()` → sets `exchangeCount = 1`
3. MeasureSize widget reports user message height (e.g. 80px)
4. Bottom padding = `max(0, 600 - 80) = 520px`
5. `jumpTo(0)` → viewport shows: [520px padding | 80px user msg at top]
6. Old messages are at higher offsets → off screen above

---

## Flow 3: AI Response Streams In (user at bottom)

### What the user sees:
1. After sending, user's message is at the top-right
2. AI bubble appears just BELOW the user message
3. Text streams in word by word — bubble grows DOWNWARD
4. **User message does NOT move** — stays at the top
5. Empty space below AI bubble shrinks as text grows

```
TIME 0 (sent):             TIME 1 (streaming):         TIME 2 (more text):
┌─────────────────┐        ┌─────────────────┐         ┌─────────────────┐
│     AppBar      │        │     AppBar      │         │     AppBar      │
├─────────────────┤        ├─────────────────┤         ├─────────────────┤
│ [User] What is ─┤        │ [User] What is ─┤         │ [User] What is ─┤
│       Flutter?  │        │       Flutter?  │         │       Flutter?  │
│                 │        │                 │         │                 │
│                 │        │ [AI] Flutter is │         │ [AI] Flutter is │
│  (empty space)  │        │      an open... │         │  an open-source │
│                 │        │                 │         │  UI toolkit by  │
│                 │        │  (empty space,  │         │  Google for     │
│                 │        │   shrinking)    │         │  building apps  │
│                 │        │                 │         │  across mobile  │
├─────────────────┤        ├─────────────────┤         ├─────────────────┤
│[Type a msg..] ➤ │        │[Type a msg..] ➤ │         │[Type a msg..] ➤ │
└─────────────────┘        └─────────────────┘         └─────────────────┘
```

### Technical:
1. AI message inserted at `messages[0]` (empty content)
2. `controller.onAIResponseStarted()` → `exchangeCount = 2`
3. Each token: `messages[0].content += token` → `setState()` → bubble grows
4. MeasureSize reports new AI height → padding recalculates:
   - `exchangeHeight = aiHeight + userMsgHeight`
   - `bottomPadding = max(0, viewportHeight - exchangeHeight)`
5. At offset 0: [padding | AI response | user msg at top]
6. User msg stays at `[vp - U, vp]` — mathematically fixed at the top ✓

---

## Flow 4: AI Response Finishes (fits in viewport)

### What the user sees:
1. AI is done streaming
2. User message **STILL** at top-right
3. AI response sits below it
4. Empty space below (padding still there)
5. **Layout persists indefinitely** — nothing changes when streaming stops

```
┌─────────────────┐
│     AppBar      │
├─────────────────┤
│ [User] What is ─┤  ← still at top, permanently
│       Flutter?  │
│                 │
│ [AI] Flutter is │  ← complete response
│  an open-source │
│  UI toolkit by  │
│  Google.        │
│                 │
│  (empty space)  │  ← padding stays
│                 │
├─────────────────┤
│[Type a msg..] ➤ │
└─────────────────┘
```

### Technical:
- Streaming stops. No more setState calls.
- Padding is based on geometry (viewport vs content), NOT streaming state.
- Layout stays exactly the same whether streaming or finished.

---

## Flow 5: AI Response Exceeds Viewport

### What the user sees:
1. AI response grows very long (3+ screens of text)
2. Empty space is now completely gone
3. User message has scrolled off the top
4. Latest AI text appears at the bottom of the screen
5. New words keep appearing at the bottom
6. User can scroll up to see their question + beginning of response

```
FITS:                              EXCEEDS:
┌─────────────────┐                ┌─────────────────┐
│ [User] What is ─┤                │  ...toolkit by  │
│       Flutter?  │                │  Google for     │
│                 │                │  building apps  │
│ [AI] Flutter is │                │  across mobile, │
│  an open-source │                │  web, desktop   │
│  UI toolkit...  │                │  from a single  │
│                 │                │  codebase. It   │
│  (empty space)  │                │  uses Dart and  │
│                 │                │  provides hot   │
├─────────────────┤                │  reload for     │
│[Type a msg..] ➤ │                │  fast dev...    │
└─────────────────┘                ├─────────────────┤
                                   │[Type a msg..] ➤ │
                                   └─────────────────┘
```

### Technical:
- `exchangeHeight > viewportHeight` → `bottomPadding = 0`
- At offset 0: we see the bottom of the AI response (latest text)
- In reversed list, item bottom is anchored at offset 0 → latest tokens always visible
- No auto-scroll needed — staying at offset 0 IS seeing the latest text
- The AI text widget's latest word is at its bottom = closest to offset 0

---

## Flow 6: User Sends While Scrolled Up

### What the user sees:
1. Was scrolled up reading old messages
2. "↓" button visible above input bar
3. Types and sends
4. **Screen jumps** — user's new message at TOP RIGHT
5. Old messages gone (above viewport)
6. "↓" button disappears

```
BEFORE (scrolled up):           AFTER SEND:
┌──────────────────┐            ┌──────────────────┐
│      AppBar      │            │      AppBar      │
├──────────────────┤            ├──────────────────┤
│  [AI] Earlier msg│            │                  │
│                  │            │  [User] New ─────┤
│  [User] Old msg  │            │        question  │
│                  │            │                  │
│  [AI] Another    │            │                  │
│       old msg    │            │   (empty space)  │
├──────────────────┤            │                  │
│       [ ↓ ]      │            │                  │
│ [New question] ➤ │            ├──────────────────┤
└──────────────────┘            │ [Type a msg..]  ➤│
                                └──────────────────┘
```

### Technical:
- `onNewUserMessage()` forces `isUserScrolledUp = false` and `jumpTo(0)`
- Same behavior as Flow 2 from here

---

## Flow 7: AI Streams While User is Scrolled Up

### What the user sees:
1. Scrolled up reading old messages
2. "↓" button visible
3. AI streaming at the bottom (invisible to user)
4. **NOTHING MOVES** — screen stays perfectly stable
5. User can tap "↓" whenever they want to see the response

```
USER'S VIEW (completely stable):
┌──────────────────┐
│      AppBar      │
├──────────────────┤
│  [AI] Message #5 │
│                  │
│  [User] Msg #6   │  ← reading these, undisturbed
│                  │
│  [AI] Message #7 │  ← NOTHING MOVES
│                  │
│  [User] Msg #8   │
├──────────────────┤
│       [ ↓ ]      │
│ [Type a msg..]  ➤│
└──────────────────┘
```

### Technical:
- `isUserScrolledUp == true`
- `onNewAIContent()` checks → true → does nothing
- AI item grows at index 1 (visual bottom area), user is at high offset → unaffected
- Padding recalculates silently

---

## Flow 8: User Scrolls Up

### What the user sees:
1. At bottom, swipes down (scrolling up through history)
2. Older messages appear from the top
3. After ~50px of scrolling, "↓" button fades in above input bar
4. Button stays visible while scrolled up

### Technical:
- `UserScrollNotification` fires → `handleUserScroll()`
- When `offset > 50px`: `isUserScrolledUp = true`, `showScrollToBottom = true`
- Button uses `AnimatedOpacity(duration: 200ms)` to fade in

---

## Flow 9: User Taps "Scroll to Bottom" Button

### What the user sees:
1. Taps "↓" button
2. Screen **smoothly animates** to bottom (300ms)
3. Button fades out

### Technical:
- `scrollToBottom()` → `animateTo(0, duration: 300ms, curve: easeOut)`
- `isUserScrolledUp = false`, `showScrollToBottom = false`

---

## Flow 10: User Scrolls Back Down Manually

### What the user sees:
1. Scrolled up, button visible
2. Manually scrolls back down
3. When reaching bottom, button fades out

### Technical:
- `offset` decreases toward 0
- When `offset <= 50px`: `isUserScrolledUp = false`, button hides
- Also caught by `ScrollEndNotification` for fling animations

---

## Flow 11: Keyboard Opens

### What the user sees:
1. Taps input field
2. Keyboard slides up, input bar moves up with it
3. Chat area shrinks but messages stay visible
4. No jumping or glitching

```
BEFORE:                         AFTER KEYBOARD:
┌──────────────────┐           ┌──────────────────┐
│      AppBar      │           │      AppBar      │
├──────────────────┤           ├──────────────────┤
│  [AI] Hello!     │           │  [User] Thanks!  │
│  [User] Hi!      │           │                  │
│  [AI] Sure!      │           │  [AI] Response   │
│  [User] Thanks!  │           ├──────────────────┤
├──────────────────┤           │ [Type a msg..]  ➤│
│ [Type a msg..]  ➤│           ├──────────────────┤
└──────────────────┘           │    KEYBOARD      │
                               └──────────────────┘
```

### Technical:
- `Scaffold(resizeToAvoidBottomInset: true)` handles it
- `Expanded(BetterChatScrollView)` shrinks → LayoutBuilder fires
- Padding recalculates for smaller viewport
- Offset 0 stays anchored at bottom → seamless

---

## Flow 12: Empty New Chat

### What the user sees:
- Empty screen with input bar at bottom
- Nothing else

### Technical:
- `messages` is empty, `itemCount = 1` (just padding at index 0)
- Padding = 0 (no exchange) → nothing rendered

---

## Flow 13: Multiple Rapid Messages

### What the user sees:
1. Sends "Hi" → at top
2. Sends "One more thing" → appears below "Hi"
3. Sends "Help with X?" → appears below that
4. All 3 messages in the exchange area, empty space shrinking
5. AI eventually responds below the last one

### Technical:
- Each `onNewUserMessage()` increments `exchangeCount`
- Exchange height = sum of all user message heights
- Padding = `max(0, vp - exchangeHeight)`
- All exchange messages stay visible at top

---

## Scroll-to-Bottom Button

- **Size:** 36x36 circular with shadow
- **Position:** Centered, 8px above input bar
- **Show when:** `offset > 50px` from user scroll
- **Hide when:** `offset <= 50px`, or user sends, or button tapped
- **Animation:** Fade in/out 200ms
- **Customizable:** Pass `scrollToBottomWidget` to override
