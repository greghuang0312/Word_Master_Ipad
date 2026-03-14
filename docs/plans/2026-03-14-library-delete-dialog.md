# Library Delete Dialog Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Show a custom centered delete confirmation overlay on the Library screen instead of the system confirmation sheet.

**Architecture:** Extract a tiny `LibraryDeletionPrompt` model from `WordItem` and let `LibraryView` build its overlay from that value. The view continues to use `pendingDeletion` as state and calls the existing delete action when the destructive button is pressed.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add Deletion Prompt Model

**Files:**
- Create: `WordMaster/Features/Library/LibraryDeletionPrompt.swift`
- Test: `WordMasterTests/LibraryDeletionPromptTests.swift`

**Step 1: Write the failing test**

Add a test that creates a prompt from a `WordItem` and asserts:
- title is `删除词条`
- destructive button title contains the English word
- message contains both Chinese and English text

**Step 2: Run test to verify it fails**

Run the targeted XCTest command if a local Apple toolchain is available.

**Step 3: Write minimal implementation**

Create a tiny equatable value type with `title`, `message`, and `confirmTitle`.

**Step 4: Run test to verify it passes**

Run the same targeted XCTest command if toolchain support exists.

### Task 2: Replace System Confirmation Dialog

**Files:**
- Modify: `WordMaster/Features/Library/LibraryView.swift`

**Step 1: Remove `confirmationDialog`**

Delete the system modifier and keep `pendingDeletion` as the state trigger.

**Step 2: Add custom overlay**

Render:
- dimmed backdrop
- confirmation card centered and shifted upward
- cancel and destructive buttons

**Step 3: Reuse existing delete flow**

On confirm, clear `pendingDeletion` and call `viewModel.deleteWord(id:)`.

**Step 4: Verify**

Inspect the diff and run any available build or test command.
