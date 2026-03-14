# Add Save Feedback Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Add save feedback immediate and stateful, remove redundant manual re-query UI, and send unauthenticated save attempts back to login.

**Architecture:** Introduce a small Add-specific banner model consumed by both the view model and view. The view model owns save progress/error/success transitions and escalates authentication loss through `AppContext.signOut()`, while the view renders the banner and removes the manual re-query button.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Cover Save Feedback State

**Files:**
- Create: `WordMaster/Features/Add/AddWordResultBanner.swift`
- Modify: `WordMaster/Features/Add/AddWordViewModel.swift`
- Modify: `WordMasterTests/AddWordViewModelTests.swift`

**Step 1: Write the failing test**

Assert progress appears immediately, success replaces it after the repository completes, and failures produce an error-tone banner.

**Step 2: Run test to verify it fails**

Run the targeted XCTest command if an Apple toolchain is available.

**Step 3: Write minimal implementation**

Add a stateful banner model and wire save transitions through it.

### Task 2: Remove Redundant Re-query And Handle Auth Loss

**Files:**
- Modify: `WordMaster/Features/Add/AddWordView.swift`
- Modify: `WordMaster/Features/Add/AddWordViewModel.swift`
- Modify: `WordMasterTests/AddWordViewModelTests.swift`

**Step 1: Write the failing test**

Assert unauthenticated save triggers sign-out.

**Step 2: Run test to verify it fails**

Run the targeted XCTest command if an Apple toolchain is available.

**Step 3: Write minimal implementation**

Remove the manual re-query button and sign out when save detects missing authentication.

### Task 3: Verify

Inspect the diff and run available Apple toolchain commands if present.
