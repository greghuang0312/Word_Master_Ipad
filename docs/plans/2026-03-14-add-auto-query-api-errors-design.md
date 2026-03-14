# Add Auto Query And API Error Messaging Design

## Context

- `ProfileViewModel` already surfaces `error.localizedDescription`, but `DeepSeekClientError` still returns generic or raw English text for common API failures.
- `AddWordView` currently triggers candidate lookup from the view layer with `.onChange`, which makes the auto-query behavior depend on one specific view binding path.

## Decision

1. Centralize DeepSeek-facing error messages in `DeepSeekClientError`.
2. Move Chinese-input auto-query orchestration into `AddWordViewModel`.

## API Error Messaging

- Keep `ProfileViewModel` simple: it should continue displaying `error.localizedDescription`.
- Teach `DeepSeekClientError.requestFailed` to map common status codes to user-facing Chinese text:
  - `401`: API Key 无效或已失效
  - `402`: DeepSeek 账户余额不足
  - `429`: 请求过于频繁，请稍后再试
- Preserve server-provided message text as a fallback for other status codes.

## Add Screen Auto Query

- Replace the view-layer `.onChange` trigger with a debounced `Combine` pipeline inside `AddWordViewModel`.
- The view model listens to `zhText`, trims it, removes duplicates, debounces input, and triggers candidate lookup automatically.
- Clearing the Chinese text should immediately clear candidate state and cancel pending lookups.
- The manual “重新查询” button remains available and continues to call the same query method directly.

## Testing

- Add pure tests for `DeepSeekClientError.errorDescription`.
- Add `AddWordViewModel` tests covering:
  - debounced auto-query on Chinese input
  - clearing text cancels/clears candidate state
