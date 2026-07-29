# Spec: Scroll to Newly Added Note

## Problem Statement

Adding a note through the composer gives no visual confirmation of where it landed. New notes go to the end of the unsectioned zone, which sits above any sections — so with sections below, the new note can be entirely off-screen. The user types, presses return, and sees nothing change.

## Solution

After submitting a note from the composer, the list scrolls so the new note is visible at the bottom edge of the scroll area, right above the composer. The scroll targets the note itself — not the end of the list — so sections below the unsectioned zone do not pull the viewport past it. Capture and paste flows that create unsectioned notes scroll the same way.

## User Stories

1. As a user, I want the list to scroll to my newly added note after composer submit, so that I get visual confirmation the note was created.
2. As a user, I want the scroll to target the new note rather than the list end, so that sections below the unsectioned zone do not scroll my note out of view.
3. As a user, I want the new note aligned to the bottom of the scroll area, so that it sits visually adjacent to the composer I just typed in.
4. As a user, I want the scroll animated briefly, so that I can follow where the viewport moved.
5. As a user, I want notes captured from other apps to scroll into view the same way, so that opening the panel shows what just landed.
6. As a user, I want pasting into an empty selection to scroll to the pasted note, so that all unsectioned-add paths behave consistently.
7. As a user, I want composer focus and my selection left untouched by the scroll, so that rapid consecutive entry is uninterrupted.
8. As a user, I want an active search filter left intact when I add a non-matching note, so that adding never destroys my query state.

## Implementation Decisions

- Reuse the existing scroll-target mechanism the panel already consumes; no view-layer changes.
- The app model's add-note path captures the note returned by the store and sets the scroll target to that note's id with a bottom anchor, after the mutation.
- Applies to every caller of the add-note path: composer submit, global capture, and paste-as-note with no selection. Anchored inserts (open-below, paste after selection) are unchanged.
- No selection change on add — scroll only.
- When a search filter hides the new note, the scroll request is a silent no-op (target id absent from the rendered list); the query is never cleared.
- Existing scroll animation (0.15s ease-out) reused as-is.
- Timing follows the established reorder precedent: scroll target set in the same run loop as the mutation's revision bump; the scroll-target change handler runs after the body re-evaluates, so the new row's id is resolvable.

## Testing Decisions

- No Core changes; the notes store already returns the created note and is covered by existing tests.
- The app model layer has no test target; per repo convention (see drag-and-drop spec) it is verified manually.
- Manual pass: with sections below the unsectioned zone, add a note via composer and confirm the viewport lands the note just above the composer; add while a search filter hides the note and confirm nothing jumps and the query survives; capture from another app and confirm the panel shows the note.

## Out of Scope

- Selecting or focusing the new note.
- Clearing the search filter on add.
- Scrolling for anchored inserts (open-below/above, paste after selection) — they already land adjacent to the visible anchor.
- Scroll behavior for section creation.

## Further Notes

- Seam count: zero new seams. The change rides the existing scroll-target published property already consumed by the panel view.
- No issue tracker configured for this repo; spec lives in `docs/specs/` per convention.
