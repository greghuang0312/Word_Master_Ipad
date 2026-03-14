# Add Auto Query And API Error Messaging Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make API key test failures display clear Chinese reasons and ensure entering Chinese meaning in Add automatically fetches English candidates.

**Architecture:** Localize common DeepSeek HTTP failures inside `DeepSeekClientError`, then keep `ProfileViewModel` and `AddWordViewModel` consuming `error.localizedDescription`. Move Add auto-query triggering from `AddWordView` into a debounced `Combine` pipeline owned by `AddWordViewModel`.

**Tech Stack:** SwiftUI, Combine, XCTest

---

### Task 1: Cover Error Messaging

**Files:**
- Create: `WordMasterTests/DeepSeekClientErrorTests.swift`
- Modify: `WordMaster/Data/LLM/DeepSeekClient.swift`

**Step 1: Write the failing test**

Assert localized descriptions for `401`, `402`, and `429`.

**Step 2: Run test to verify it fails**

Run the targeted XCTest command if an Apple toolchain is available.

**Step 3: Write minimal implementation**

Map the common status codes to Chinese messages while keeping a fallback.

### Task 2: Cover Add Auto Query

**Files:**
- Create: `WordMasterTests/AddWordViewModelTests.swift`
- Modify: `WordMaster/Features/Add/AddWordViewModel.swift`
- Modify: `WordMaster/Features/Add/AddWordView.swift`

**Step 1: Write the failing test**

Assert that updating `zhText` automatically triggers candidate lookup after debounce.

**Step 2: Run test to verify it fails**

Run the targeted XCTest command if an Apple toolchain is available.

**Step 3: Write minimal implementation**

Move auto-query triggering into the view model and remove the view-layer `.onChange`.

### Task 3: Verify

Inspect the diff and run available Apple toolchain commands if present.
