# Spec: Clear Submenu with Confirmation Alerts

## Problem Statement

The only bulk-delete in the app is "Clear Completed". Deleting a section does not delete its notes — it moves them to the unsectioned zone — so the unsectioned pile can only ever grow, and there is no way to delete it in bulk. There is also no way to wipe all notes, or reset the app to empty, without deleting notes one by one.

## Solution

The ellipsis menu's "Clear Completed" item becomes a "Clear" submenu with four scoped bulk-delete actions: Clear Completed (unchanged behavior), Clear Unsectioned Notes, Clear All Notes (sections survive), and Clear Everything (notes and sections). The three new actions are irreversible, so each shows a native confirmation alert stating exactly how many notes (and sections) will be deleted, with a destructive Clear button and Cancel as the default. Items whose target count is zero are disabled.

## User Stories

1. As a user, I want a Clear submenu in the ellipsis menu, so that all bulk-delete actions are grouped in one place without crowding the top-level menu.
2. As a user, I want to clear all unsectioned notes at once, so that the pile that accumulates from deleted sections and quick captures does not require one-by-one deletion.
3. As a user, I want to clear all notes while keeping my sections, so that I can reuse my organizational structure with fresh content.
4. As a user, I want to clear everything — notes and sections — so that I can reset the app to an empty state.
5. As a user, I want Clear Completed to keep working exactly as before, so that my existing habit of clearing done notes is undisturbed.
6. As a user, I want a native confirmation alert before any irreversible clear, so that a mis-click cannot destroy my notes.
7. As a user, I want the alert to state how many notes (and sections) will be deleted, so that the destructiveness is concrete before I commit.
8. As a user, I want the alert for Clear All Notes to say sections will be kept, so that I understand the difference from Clear Everything.
9. As a user, I want the confirm button to render as destructive (red) and Cancel to be the default, so that pressing Return cancels and clearing requires a deliberate click.
10. As a user, I want no confirmation on Clear Completed, so that the low-risk action I already use stays one click.
11. As a user, I want menu items disabled when there is nothing for them to clear, so that I never see an alert offering to delete zero notes.
12. As a user, I want ellipsis suffixes on the items that confirm, so that I know before clicking that a dialog follows.
13. As a user, I want cancelling the alert to change nothing, so that I can safely inspect the counts and back out.
14. As a user, I want a confirmed clear persisted like any other edit, so that the result survives app restart.

## Implementation Decisions

- The core notes store gains three operations alongside the existing clear-completed: clear unsectioned notes, clear all notes (sections kept), and clear everything (notes and sections).
- The app model gains a confirm-clear flow parameterized by clear kind. It computes the affected counts, presents an NSAlert (warning style, following the existing new-section prompt precedent), and applies the mutation through the standard mutate path (revision bump + scheduled save) only on confirmation.
- Alert copy per kind, with live counts:
  - Clear Unsectioned Notes? — "This will delete N unsectioned notes. This cannot be undone."
  - Clear All Notes? — "This will delete N notes. Sections will be kept."
  - Clear Everything? — "This will delete N notes and M sections. This cannot be undone."
- Confirm button titled "Clear" with destructive styling; Cancel is the default button.
- Menu layout: Clear Completed, divider, then the three confirming items in order of increasing scope, each with a trailing ellipsis.
- Each item is disabled when its target count is zero; Clear Completed is retrofitted with the same disabled treatment for consistency.
- No undo mechanism exists in the app; the confirmation alert is the sole safeguard. Building undo is explicitly not part of this feature.

## Testing Decisions

- Tests target external behavior of the core store only: after each new clear operation, exactly the expected notes/sections remain — never internal ordering or storage details.
- The three new store operations are covered in the existing core store test suite, following the style of the current clear-completed and delete-section tests (construct store, mutate, assert remaining contents).
- The app model layer has no test target; per repo convention the menu and alert flow are verified manually: each item disabled/enabled at the right counts, alert copy shows correct counts, Cancel is a no-op, confirm clears the right scope and persists across restart.

## Out of Scope

- Undo/redo for clears (no undo infrastructure exists).
- Per-section clear actions (e.g. "Delete Section and Notes" in the section context menu) — the submenu leaves room for these later.
- Changing what "Delete Section" does to its notes.
- Confirmation for Clear Completed.

## Further Notes

- Seam count: one existing seam — the core store's public API, already exercised by the core test suite. No new seams; the alert flow rides the established NSAlert-from-app-model precedent.
- No issue tracker configured for this repo; spec lives in `docs/specs/` per convention.
