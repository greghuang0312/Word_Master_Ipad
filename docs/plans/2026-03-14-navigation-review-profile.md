# Navigation Review Profile Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver a stable bottom app navigation, review sync-on-entry with a syncing popup, and the simplified API key flow on the profile screen.

**Architecture:** Introduce a lightweight `MainTab` enum for the custom shell and keep one `NavigationStack` per tab inside a bottom-aligned container. Add focused pure models for API key helper text and review syncing presentation where useful, while preserving existing repository and Keychain integrations.

**Tech Stack:** SwiftUI, XCTest, Foundation

---

### Task 1: Add Pure Models For Navigation And API Key Guidance

**Files:**
- Create: `WordMaster/App/MainTab.swift`
- Create: `WordMaster/Features/Profile/ProfileApiKeyGuidance.swift`
- Test: `WordMasterTests/MainTabTests.swift`
- Test: `WordMasterTests/ProfileApiKeyGuidanceTests.swift`

**Step 1: Write the failing tests**

Assert:
- all five tabs exist with the expected titles and SF Symbols
- the API key guidance text mentions using the full key, keeping `sk-`, and not entering `Bearer`

**Step 2: Run test to verify it fails**

Run the targeted XCTest command if an Apple toolchain is available.

**Step 3: Write minimal implementation**

Add pure value types/constants only.

**Step 4: Run test to verify it passes**

Run the same targeted test command if toolchain support exists.

### Task 2: Replace The Main Tab Shell

**Files:**
- Modify: `WordMaster/App/MainTabView.swift`

**Step 1: Remove `TabView`**

Use a custom bottom-aligned shell with explicit tab buttons.

**Step 2: Keep navigation stacks per tab**

Render one `NavigationStack` per tab and toggle visibility by selection so switching tabs does not relocate the main navigation.

**Step 3: Pass activity state**

Send an `isActive` flag into `ReviewView` so it can sync every time the tab becomes active.

### Task 3: Rework Review Sync Behavior

**Files:**
- Modify: `WordMaster/Features/Review/ReviewView.swift`
- Modify: `WordMaster/Features/Review/ReviewViewModel.swift`

**Step 1: Remove redundant refresh UI**

Delete the top toolbar refresh button and the in-flow queue refresh button.

**Step 2: Sync on re-entry**

Trigger `loadQueue()` every time the review tab becomes active.

**Step 3: Add syncing popup**

Show a centered overlay with `正在同步数据` while the queue is loading, then dismiss it automatically when loading ends.

### Task 4: Simplify Profile API Key Flow

**Files:**
- Modify: `WordMaster/Features/Profile/ProfileView.swift`
- Modify: `WordMaster/Features/Profile/ProfileViewModel.swift`

**Step 1: Use a visible text field**

Do not preload the stored key into the visible field.

**Step 2: Keep only two actions**

Remove separate save/test buttons and keep:
- `测试并保存`
- `清除`

**Step 3: Clear the visible field after success**

Persist the tested key, keep it in Keychain, and clear the field contents in the UI so the saved key is no longer visible.

**Step 4: Add help text**

Explain that the user should enter the full DeepSeek key, including `sk-` if present, and should not enter `Bearer`.

### Task 5: Verify

**Files:**
- Inspect: `git diff`

**Step 1: Run targeted tests**

Run the new XCTest targets if an Apple toolchain is available.

**Step 2: Check for toolchain absence**

If `swift`, `swiftc`, or `xcodebuild` is unavailable, record that limitation explicitly.
