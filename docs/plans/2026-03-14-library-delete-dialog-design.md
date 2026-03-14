# Library Delete Dialog Design

**Goal:** Replace the system delete confirmation sheet on the Library screen with a custom overlay dialog that appears centered and slightly above center.

## Context

`LibraryView` currently uses `confirmationDialog` for delete confirmation. That API does not provide stable control over dialog placement, so it cannot satisfy the requirement to keep the confirmation centered and nudged upward.

## Chosen Approach

Use a lightweight in-view overlay:

- Keep `pendingDeletion` as the source of truth
- When `pendingDeletion` is non-nil, show a dimmed full-screen backdrop
- Render a compact confirmation card centered with a negative Y offset
- Dismiss on cancel or backdrop tap
- Confirm deletion by reusing the existing `viewModel.deleteWord(id:)` flow

## Supporting Structure

Add a small `LibraryDeletionPrompt` value type to hold the dialog title, message, and destructive button label. This keeps the view code simple and gives a pure surface for focused regression tests.

## Why This Approach

- Precise control over placement and motion
- Localized to `LibraryView`
- Keeps existing deletion behavior unchanged
- Enables a small test around prompt copy without requiring UI automation
