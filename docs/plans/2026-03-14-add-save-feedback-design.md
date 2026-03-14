# Add Save Feedback Design

## Context

- The Add screen still shows a redundant manual re-query button even though candidate lookup is already automatic.
- Save success feedback appears only after the repository round-trip completes, so the UI feels unresponsive.
- Save failure feedback currently reuses the same green checkmark banner as success.
- When a save is attempted without a valid authenticated session, the screen only shows an inline notice instead of returning to login.

## Decision

1. Remove the manual re-query button from the Add screen.
2. Replace the Add save popup with a typed banner state:
   - `progress`: "正在保存"
   - `success`: "已经添加完成"
   - `error`: "保存失败：..."
3. Drive banner icon and color from the banner tone:
   - `progress`: `ProgressView`
   - `success`: green `checkmark.circle.fill`
   - `error`: red `xmark.circle.fill`
4. Treat missing authentication as a global auth failure:
   - if `currentUserId` is missing before save, sign out the app context immediately
   - if the repository returns `WordRepositoryError.missingSession`, sign out the app context immediately

## Testing

- Add view model tests for:
  - immediate progress banner before save completes
  - error banner tone/message on save failure
  - sign-out trigger when save happens without a valid session
