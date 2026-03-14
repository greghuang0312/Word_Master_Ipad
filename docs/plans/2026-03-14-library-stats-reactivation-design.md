# Library Stats Reactivation Design

**Goal:** Make the Library and Stats screens reload whenever the user re-enters those tabs, matching the Review screen's activation-driven sync behavior.

## Context

The app now uses a custom bottom navigation shell. `ReviewView` already reloads via an `isActive` flag passed from `MainTabView`, but `LibraryView` and `StatsView` still rely on one-time `.task` loading and do not resync on tab re-entry.

## Chosen Approach

- Extend `MainTab` with a small `reloadsOnActivate` property
- Pass `isActive` into `LibraryView` and `StatsView` from `MainTabView`
- Replace one-time `.task` loading in those screens with `.task(id: isActive)`
- Show the same centered syncing overlay while each screen is loading

## Why This Approach

- Reuses the review tab pattern instead of inventing another lifecycle path
- Keeps the behavior explicit at the app shell level
- Adds a small pure regression surface via `MainTab`
