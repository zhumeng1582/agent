# Project Context

## Current State
- Flutter iOS/Android/macOS multi-modal chat app
- Active development - see recent commits for latest changes

## UI Style
- **Doubao-inspired design**: soft violet primary color (#6C63FF), gradient avatars, rounded corners (16-18px), card-based layouts
- Dark mode with surface color #252542
- Light mode background #F8F9FE

## Key Patterns

### Message Streaming (Typewriter Effect)
- `Message.isStreaming` (bool?) field marks messages being typed
- `TextMessage` uses `animated_text_kit` with cursor '|'
- Animation duration: content.length * 30ms + 500ms buffer
- Chat auto-scrolls to bottom during streaming unless user scrolled up

### Message Bubble Layout
- `MessageBubble` uses `width: double.infinity` with 16px horizontal padding
- `_buildBubble` uses `maxWidth: MediaQuery.of(context).size.width` (100%)
- Alignment controlled via `Column.crossAxisAlignment`

### State Management
- Riverpod with `ConsumerWidget` / `ConsumerStatefulWidget`
- `loadingChatIdsProvider` tracks which chats have AI "thinking" state
- Per-chat loading via `Set<String>` not single ID

## Important Notes
- AI responses are一次性返回 (complete in one go), not streaming
- Typewriter effect is simulated for better UX
- Don't use `StatefulWidget` for simple text messages - stick with `ConsumerWidget`

## Recent Fixes (avoid regressing)
- Fix: `isStreaming` must be `bool?` not `bool` (null from old messages)
- Fix: Timer disposal in `TextMessage` must check `mounted`
- Fix: Message bubble width uses 100% maxWidth with 16px container padding
