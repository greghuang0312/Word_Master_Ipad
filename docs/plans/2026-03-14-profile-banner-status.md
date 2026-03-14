# Profile Banner Status Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Render semantic success and error banners on the profile screen so failure messages use a red x-mark instead of a green checkmark.

**Architecture:** Extract a tiny banner state model for the profile feature and have `ProfileViewModel` publish that model. `ProfileView` reads the semantic tone from the model and maps it to the correct icon and tint.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add Banner State Model

**Files:**
- Create: `WordMaster/Features/Profile/ProfileResultBanner.swift`
- Test: `WordMasterTests/ProfileResultBannerTests.swift`

**Step 1: Write the failing test**

Create tests that assert:
- success tone uses `checkmark.circle.fill`
- error tone uses `xmark.circle.fill`

**Step 2: Run test to verify it fails**

Run the profile-related test target if a local Apple toolchain is available.

**Step 3: Write minimal implementation**

Add a small equatable model with `message` and `tone`, plus tone-to-icon mapping.

**Step 4: Run test to verify it passes**

Run the same targeted test command if toolchain support exists.

### Task 2: Wire Banner State Through Profile Feature

**Files:**
- Modify: `WordMaster/Features/Profile/ProfileViewModel.swift`
- Modify: `WordMaster/Features/Profile/ProfileView.swift`

**Step 1: Replace plain banner text state**

Change the view model to publish `ProfileResultBanner?` instead of `String?`.

**Step 2: Preserve semantic state at source**

Send `.success` for save/clear/test success cases and `.error` for validation, persistence, or connectivity failures.

**Step 3: Update the view**

Render the banner from `ProfileResultBanner` and map:
- success -> green `checkmark.circle.fill`
- error -> red `xmark.circle.fill`

**Step 4: Verify**

Inspect the diff and run any available targeted verification command.
