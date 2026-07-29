# Spec: Drag and Drop (v0.2)

## Problem Statement

Reordering notes in Bronze currently requires keyboard commands (⌥j/⌥k) or the right-click "Move to" menu. Moving a note several positions, or into another section, takes many repeated actions. There is no way to pull text into Bronze by dragging, or to drag a note's text out into another app.

## Solution

Direct-manipulation drag and drop. Grab a card (or the current multi-selection) and drop it anywhere in the list: between cards, into another section, or onto a section header. Drag text in from any app to create a note at the drop position. Drag a card out to any app to paste its text. A thin accent insertion line shows exactly where the drop will land.

## User Stories

1. As a user, I want to drag a note card and drop it between two other cards, so that I can reorder notes directly.
2. As a user, I want to drag a card that is part of my current selection and have the whole selection move, so that I can reorder several notes in one gesture.
3. As a user, I want to drag a card that is not in my selection and have only that card move, so that stale selections do not cause surprise moves.
4. As a user, I want to drop notes between cards of a different section and have them adopt that section, so that repositioning and re-sectioning is one gesture.
5. As a user, I want to drop notes onto a section header and have them land at the top of that section, so that I can file notes without aiming between cards.
6. As a user, I want to drop notes into the unsectioned area the same way, so that I can un-file notes by dragging.
7. As a user, I want to drop notes below the last card to send them to the end of the list, so that the trailing area is not dead space.
8. As a user, I want a thin insertion line at the exact drop position while hovering, so that I know where notes will land before releasing.
9. As a user, I want a section header to highlight when targeted, so that header drops are distinguishable from between-card drops.
10. As a user, I want moved notes to remain selected after the drop, so that I can immediately act on them again.
11. As a user, I want dropping a selection onto its own position to change nothing, so that accidental micro-drags are harmless.
12. As a user, I want a multi-note drag to preserve on-screen order, so that the block reads the same after the move.
13. As a user, I want drag disabled while a search filter is active, so that I cannot reorder against invisible neighbors.
14. As a user, I want to drag text from another app into the list and get a new note at the drop position, so that capture works by dragging too.
15. As a user, I want text dropped onto a section header to become a note at the top of that section, so that external capture can be filed directly.
16. As a user, I want dropped text trimmed and empty drops ignored, so that whitespace junk never becomes a note.
17. As a user, I want to drag a card into another app and have its text arrive as plain text, so that notes flow out as easily as they flow in.
18. As a user, I want a multi-note drag-out to paste all texts joined by blank lines, so that drag-out matches the Copy command's format.

## Implementation Decisions

- **Selection-aware drag**: if the dragged card's id is in the current selection, the payload carries the whole selection in display order; otherwise only the dragged card. Finder behavior.
- **New core reorder API** on the notes store, covered by tests:
  - move notes before/after an anchor note: the moved block (display order preserved) is removed and reinserted adjacent to the anchor, adopting the anchor's sectionId. No-op when the anchor is inside the moved set.
  - move notes to the start of a section (or of the unsectioned group for nil).
  - insert externally dropped text before/after an anchor (existing insert API adopts anchor's section) and at the start of a section.
- **Single payload type** for all four flows: a Codable Transferable carrying note ids plus their joined plain text. Custom UTType (`tech.teensy.bronze.notes`, exported in the app's Info.plist) via CodableRepresentation, plus a ProxyRepresentation exporting the text (drag-out) and importing String (external text drops arrive as a payload with empty ids).
- **Drop resolution in the view layer**: each card hosts top/bottom half drop zones deciding before/after; section headers are whole-target zones; one trailing zone after the last group maps to end-of-list. Internal payloads call the reorder API; empty-id payloads create notes at the same resolved position.
- **Drag sources and drop zones disabled** whenever the search query is non-empty.
- **Visuals via design tokens**: accent-colored insertion line at the active edge, header highlight when targeted. No live-shuffle preview.
- After an internal drop, the model's selection is set to the moved ids.
- Drag-out text format identical to the existing Copy command (texts joined by blank lines).

## Testing Decisions

- Core store methods get exhaustive unit tests in the existing Core test suite (`swift test`), same seam as all current store tests: construct store, call method, assert on displayOrder/sections. Behavior only — no internal array-layout assertions beyond what displayOrder exposes.
- Cases: reorder within section, cross-section before/after adopts section, header drop to start, multi-id block order preservation, anchor-inside-selection no-op, unknown-anchor no-op, external insert at position and section start.
- Payload Transferable and view drop zones are not unit tested (matches existing convention: view layer verified manually). Manual pass: internal reorder, cross-section, header drop, drag-out to TextEdit, drag-in from browser, search-active drag disabled.

## Out of Scope

- Live-shuffle preview while hovering (insertion line only).
- Dragging section headers to reorder sections.
- Dropping files, images, or URLs (plain text only).
- Drag while a search filter is active.
- Undo (roadmap item, unchanged).

## Further Notes

- Seam unchanged and single: the notes store's public API remains the only tested seam; the view layer stays a thin adapter.
- No issue tracker configured for this repo; spec lives in `docs/specs/` alongside existing `docs/spec.md` convention.
