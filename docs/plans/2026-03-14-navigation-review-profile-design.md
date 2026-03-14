# Navigation Review Profile Design

**Goal:** Move the main app navigation to a stable bottom bar, make the Review screen re-sync whenever it is re-entered, and simplify the Profile API key interaction to a single test-and-save flow.

## Context

The current app shell relies on `TabView`, which can place the main navigation at the top on iPad/Playgrounds. The Review screen also mixes pull-to-refresh, toolbar refresh, and initial loading without a dedicated sync overlay. The Profile screen still exposes separate save and test actions and preloads any stored API key into a masked field.

## Chosen Approach

- Replace `TabView` with a custom bottom navigation shell
- Pass an `isActive` flag into tab roots so the Review screen can sync each time it becomes active
- Show a centered sync overlay while review data is loading
- Reduce the Profile API key flow to a visible text field plus `测试并保存` and `清除`
- Clear the visible field after a successful save while keeping the saved key in Keychain

## Why This Approach

- Stable bottom placement across iPad and Playgrounds
- Explicit review screen lifecycle instead of relying on incidental `task` behavior
- Profile API key behavior matches the approved privacy and replacement flow
- Existing repository and Keychain integrations remain intact

## API Key Input Rule

The input should contain the full API key exactly as issued by DeepSeek. If the key starts with `sk-`, the user should include that prefix. The app should not ask users to type `Bearer ` because the client already adds that prefix in the `Authorization` header.
