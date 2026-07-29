# Bronze — MVP Spec

Open-source (MIT), Copper-inspired scratchpad for AI-assisted work. Native macOS app: Swift + SwiftUI with AppKit interop. Research grounding: `research/copper.md`, `research/ts-mac-stacks.md`.

## Problem Statement

While working across AI tools (ChatGPT, Claude, Cursor) and a browser, small valuable fragments accumulate mid-conversation: an answer worth keeping, a link, an idea, follow-up prompts not ready to send. They get scattered across clipboards, stray notes, and memory. There is no low-friction place to capture them from any app and paste them back into a chat when needed.

## Solution

A small always-on-top floating panel that lives beside your work. Double-tap Shift captures the current text selection from any app into the panel. Notes are checklist cards organized into sections, navigable entirely by keyboard (including a vim layer). Multi-select notes and copy them back out as a numbered list ready to paste into a chat. Everything stays in one local JSON file: no account, no sync, no telemetry.

## User Stories

1. As an AI-assisted developer, I want to capture selected text from any app with a double-tap of Shift, so that I can keep a fragment without leaving my current context.
2. As a user, I want a "Captured" toast to appear near my selection, so that I know the capture succeeded without checking the panel.
3. As a user, I want captures to work even in apps that don't expose selections to Accessibility, so that capture is reliable everywhere.
4. As a user, I want captured notes to land in the unsectioned zone at the top of my list, so that new material is always findable in one place.
5. As a user, I want a floating panel that stays on top while I work in other apps, so that my notes are glanceable beside my chat window.
6. As a user, I want the panel to avoid stealing keyboard focus from my active app when I click a checkbox, so that my typing flow is not interrupted.
7. As a user, I want to drag the panel anywhere and have its position remembered, so that it lives where I want it across launches.
8. As a user, I want a menu bar icon that toggles the panel, so that the app occupies no Dock or ⌘Tab space.
9. As a user, I want closing the panel to hide it back to the menu bar rather than quit, so that my notes stay a keystroke away.
10. As a user, I want a global shortcut (⌥Space) to toggle the panel, so that I never need the mouse to reach it.
11. As a user, I want to type a note into a composer at the bottom of the panel, so that I can jot prompts and ideas directly.
12. As a user, I want Return to commit the composer and Shift-Return to insert a newline, so that multi-line notes are possible without friction.
13. As a user, I want each note shown as a checklist card, so that notes double as actionable items.
14. As a user, I want to toggle a note done with Space (or vim `x`), so that I can check items off as I go.
15. As a user, I want done notes to dim with a strikethrough and stay in place, so that completion is visible but nothing jumps around.
16. As a user, I want a "Clear Completed" action in the overflow menu, so that I can flush finished items in one step.
17. As a user, I want inline markdown (bold, italic, code, links) rendered in cards, so that captured formatting survives.
18. As a user, I want long notes clamped to about three lines with an ellipsis, so that one long note doesn't dominate the panel.
19. As a user, I want to edit a note inline with Return (or vim `i`) and see its raw markdown source while editing, so that display polish never blocks editing.
20. As a user, I want to group notes under named sections, so that different threads of work stay separated.
21. As a user, I want to create a section from the Move-to picker or the overflow menu, so that organization happens lazily when I need it.
22. As a user, I want to rename or delete a section from its header, so that structure stays current; deleting a section returns its notes to the unsectioned zone.
23. As a user, I want to move a note to a section via context menu or vim `m`, so that filing is a keystroke.
24. As a user, I want to navigate notes with arrow keys or `j`/`k`, so that my hands never leave the keyboard.
25. As a user, I want to multi-select notes with Shift-arrows, Shift-click, ⌘-click, or vim visual mode `V`, so that I can act on several notes at once.
26. As a user, I want ⌘C to copy a note's text, so that single-fragment reuse is instant.
27. As a user, I want ⇧⌘C (or `y` on a visual selection) to copy selected notes as a numbered plain-text list, so that I can paste a ready-made prompt list into a chat.
28. As a user, I want to reorder notes by drag or ⌥j/⌥k, so that Copy-as-List output matches the order I intend; moving across a section boundary refiles the note.
29. As a user, I want live substring search (⌘F or `/`) that filters cards and highlights matches, so that I can find a fragment in seconds.
30. As a user, I want Escape to walk back: cancel edit, clear search, then hide the panel, so that one key always retreats.
31. As a user, I want to delete notes with ⌫ or `dd` without a confirmation dialog, so that keyboard flow is never interrupted.
32. As a user, I want vim navigation (`gg`/`G`, `{`/`}` between sections, `⌃d`/`⌃u`, `zz` to center), so that list movement feels like my editor.
33. As a user, I want `o`/`O` to open a new note below/above the selection and `p` to paste the clipboard as a new note, so that entry works vim-style too.
34. As a user, I want my notes stored in a single local JSON file with no account, sync, or telemetry, so that my data is fully mine.
35. As a user, I want a Launch at Login toggle in the menu bar menu, so that Bronze is always running.
36. As a builder, I want to clone the repo and build with two commands (`xcodegen` then `xcodebuild` via a make target), so that self-building requires no Xcode project archaeology.
37. As a contributor, I want the core logic testable without the UI, so that changes are verifiable in CI.

## Implementation Decisions

- **Stack**: Swift + SwiftUI; AppKit interop for panel and event handling. Chosen over Tauri/Electron because the hardest parts (Accessibility capture, event taps, non-activating panel) are native code in every stack, and Swift wins every product category (footprint, native feel, API access). See `research/ts-mac-stacks.md`.
- **Identity**: app name Bronze, bundle id `tech.teensy.bronze`. Deployment target macOS 14+.
- **App shell**: menu bar accessory (`LSUIElement`, no Dock icon). Menu bar menu: Show/Hide Panel, Launch at Login, Quit. No settings window in MVP.
- **Panel**: `NSPanel` at `.floating` level, non-activating style mask, vibrancy material, rounded corners, draggable, frame persisted. Close/Escape hides; app keeps running.
- **Capture pipeline**: global double-Shift detection via event tap watching modifier flags; selection read via Accessibility `AXSelectedText`, falling back to simulated ⌘C with pasteboard save/restore. Small toast near the cursor on success. Requires the Accessibility permission; app guides the user through granting it.
- **Capture seam**: selection reading sits behind a `SelectionReader` protocol so the AX/pasteboard implementation is swappable and mockable.
- **State seam (primary)**: a single observable `NotesStore` owns all domain state and operations — add, edit, delete, toggle done, clear completed, section CRUD, move, reorder, search filter, copy-as-list formatting. Pure Swift, no UI imports. Views are thin bindings over it.
- **Data model**: `Note { id, text, done, sectionId?, projectId, createdAt, order }`, `Section { id, name, order }`. `projectId` exists from day one (single implicit project in MVP) so multi-project later is a data migration no-op.
- **Storage**: one JSON file in `~/Library/Application Support/Bronze/`, Codable, debounced atomic writes, top-level `version` field for migrations. In-memory store is source of truth.
- **Markdown**: inline-only rendering via `AttributedString(markdown:)` with `.inlineOnlyPreservingWhitespace`. Raw source preserved in storage and edit mode.
- **Done state**: dim + strikethrough in place; no auto-move, no auto-archive.
- **Sections UX**: created lazily via Move-to picker ("New Section…") or overflow menu; header context menu renames/deletes; unsectioned zone renders at top with no header and receives captures.
- **Keyboard model**: two modes. List focus = normal mode (single-key vim bindings active); editing or composer focus = insert mode (only standard shortcuts active). Two-key sequences (`gg`, `dd`) use a ~400ms buffer.
- **Copy as List**: numbered plain text (`1. …`), selection order = list order.
- **Search**: case-insensitive substring, live filter, hides non-matching notes and empty sections, highlights match ranges. No fuzzy in MVP.
- **Build tooling**: XcodeGen `project.yml` generates the Xcode project; `xcodebuild` drives CLI builds; a Makefile (or justfile) wraps both. No `.xcodeproj` committed.
- **Licensing/distribution**: MIT. MVP runs dev-signed locally; repo structured for a later public release (Developer ID + notarization + GitHub Releases) without restructuring.

## Testing Decisions

- Tests target external behavior of `NotesStore`: given operations, assert resulting state and formatted outputs. No implementation-detail assertions.
- High-value cases: copy-as-list formatting and ordering, search filtering (sections hidden when empty), section delete returning notes to unsectioned, reorder across section boundaries, done/clear-completed, JSON roundtrip with version field.
- `SelectionReader` gets a mock for capture-flow tests (captured text lands unsectioned, pasteboard restore contract).
- No UI tests in MVP; panel/keyboard behavior verified manually. Greenfield repo, so these tests are the prior art.

## Out of Scope (MVP)

Undo, fuzzy search, merge notes, edit-in-new-window, multiple projects, custom shortcut rebinding, settings window, Sparkle updates, notarization, Homebrew cask, bullet-format option for Copy as List, licensing/payments. See `docs/roadmap.md`.

## Further Notes

- Visual identity: Copper's bones (right-edge panel, cards, uppercase section headers, bottom composer) with Bronze's own skin — bronze-warm accent, own typography and spacing. Honest README positioning: "open-source, Copper-inspired."
- Double-Shift can misfire for fast typists/IME users; binding becomes configurable in v0.2, default stays.
- Escape key ordering matters: cancel edit → clear search → hide panel.
