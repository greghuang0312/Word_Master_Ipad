# Profile Banner Status Design

**Goal:** Make the "My" screen result banner show semantic success and error states instead of always using the success presentation.

## Context

`ProfileView` currently renders a single success-style banner for every result message. `ProfileViewModel` only publishes plain text, so the view cannot distinguish successful actions from failures such as connectivity test errors.

## Chosen Approach

Introduce a small banner state model with:

- `message`
- `tone` (`success` or `error`)

`ProfileViewModel` will publish this state instead of plain banner text. `ProfileView` will render the icon and tint from the semantic tone.

## Why This Approach

- Keeps presentation state explicit instead of inferring from Chinese strings
- Scales to future profile actions without adding more string matching
- Limits changes to the profile feature only

## Scope

- Add a profile banner state type
- Update profile view model result publishing to include tone
- Update profile banner UI to render green checkmarks for success and red x-marks for errors
- Add a focused unit test for the new banner tone mapping
