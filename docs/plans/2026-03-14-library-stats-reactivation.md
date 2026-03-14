# Library Stats Reactivation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reload the Library and Stats screens every time those tabs become active, with the same syncing popup behavior as Review.

**Architecture:** Encode activation-reload policy in `MainTab`, then route `isActive` into each affected screen from the custom bottom navigation shell. Each screen keeps its existing load method but triggers it from an activation-aware task and renders a centered sync overlay while loading.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add Pure Reload Policy Test

**Files:**
- Modify: `WordMaster/App/MainTab.swift`
- Modify: `WordMasterTests/MainTabTests.swift`

**Step 1: Write the failing test**

Assert:
- `review`, `library`, and `stats` return `true`
- `add` and `profile` return `false`

**Step 2: Run test to verify it fails**

Run the targeted XCTest command if an Apple toolchain is available.

**Step 3: Write minimal implementation**

Add a computed property on `MainTab`.

### Task 2: Wire Activation Into Library And Stats

**Files:**
- Modify: `WordMaster/App/MainTabView.swift`
- Modify: `WordMaster/Features/Library/LibraryView.swift`
- Modify: `WordMaster/Features/Stats/StatsView.swift`

**Step 1: Pass `isActive`**

Use the selected tab state to pass activation booleans into both screens.

**Step 2: Reload on activation**

Replace one-time `.task` with `.task(id: isActive)` and guard inactive runs.

**Step 3: Add syncing popup**

Render the same centered `正在同步数据` overlay while loading.

### Task 3: Verify

Inspect the diff and run available Apple toolchain commands if present.
