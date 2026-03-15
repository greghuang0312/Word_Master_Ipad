# Review Card Flip Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add card-style review presentation and a flip animation that plays when advancing to the next word on the Review screen.

**Architecture:** Keep review result semantics inside `ReviewViewModel`, but add a small transition surface the view can observe so the card can animate before showing the next word. `ReviewView` remains the owner of presentation details such as card styling, disabled state during animation, and the 3D flip effect.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add Review Queue Transition Tests

**Files:**
- Create: `WordMasterTests/ReviewViewModelTests.swift`
- Modify: `WordMaster/Features/Review/ReviewViewModel.swift`

**Step 1: Write the failing test**

Add tests covering:
- tapping the card while English is hidden advances to the next queued word and resets `showEnglish` to `false`
- revealing English and then tapping the card submits the unknown path and still advances to the next queued word
- finishing the final card clears the queue and sets the completion notice

**Step 2: Run test to verify it fails**

Run a targeted XCTest command for `ReviewViewModelTests` if the local Apple toolchain is available.

**Step 3: Write minimal implementation**

Expose only the state needed to support the existing review flow plus next-card transition coordination.

**Step 4: Run test to verify it passes**

Run the same targeted XCTest command and confirm the new tests pass.

### Task 2: Add Flip Transition Coordination

**Files:**
- Modify: `WordMaster/Features/Review/ReviewViewModel.swift`

**Step 1: Add transition state**

Track whether a next-card transition is in progress so the view can temporarily ignore repeated taps.

**Step 2: Separate submit from advance**

Let the view model persist the review result first, then expose a controlled way to finish the transition and move to the next card after the animation delay.

**Step 3: Verify**

Re-run the targeted tests and confirm the transition state does not break existing queue behavior.

### Task 3: Restyle the Review Card and Add Flip Animation

**Files:**
- Modify: `WordMaster/Features/Review/ReviewView.swift`

**Step 1: Upgrade the card presentation**

Convert the current panel into a clearer card surface with stronger shadow, border, spacing, and a more intentional hierarchy.

**Step 2: Add the flip animation**

Animate a horizontal 3D rotation when the user submits either review path, switch to the next word around the midpoint, and return the card to its resting position.

**Step 3: Protect interactions**

Disable card taps and the reveal button while loading or while the flip transition is running.

**Step 4: Verify**

Inspect the Review screen diff and run available tests or build commands.
