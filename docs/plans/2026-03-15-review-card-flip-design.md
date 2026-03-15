# Review Card Flip Design

**Goal:** Turn the Review screen word area into a card-style interaction and add a flip transition when moving from the current word to the next word.

## Context

`ReviewView` currently shows one translucent panel for the current word and advances immediately after the user taps the card. That meets the basic review flow, but it does not visually communicate that the user has entered the next word.

## Chosen Interaction

Use a single review card with two explicit behaviors:

- Tapping the Chinese card area, excluding the `英文翻译` button, means the user knows the word
- Tapping `英文翻译` reveals the English text
- Tapping the card after English is revealed means the user does not know the word
- After either result is submitted, the card performs a short 3D flip before showing the next word

## Review Semantics

- `会` path: submit `.known`, keep the scheduler-driven next stage progression, then flip into the next word
- `不会` path: require the English reveal first, submit `.unknown`, reset the word to stage 1 for future review, then flip into the next word
- Both paths reset the next card to the hidden-English state

## UI Direction

Keep the existing page structure, but strengthen the review panel into a clearer card:

- Larger rounded card shape
- Stronger shadow and border treatment
- Compact stage badge at the top
- Chinese meaning centered as the primary focus
- English translation revealed inline in the lower portion when requested
- A short non-blocking transition hint that the next word has loaded, expressed by the flip itself rather than extra modal UI

## Why This Approach

- Preserves the current mental model and button flow
- Keeps the behavior localized to the review feature
- Avoids introducing a second card or a more fragile stacked animation system
- Allows view-model testing to focus on review-state correctness while the view owns the transition effect
