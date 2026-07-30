# New-note section assignment

## Problem Statement

Every note created in Bronze lands in the unsectioned zone, regardless of what the user is doing. When working inside a section, adding a related note means typing it in the composer, finding it in the unsectioned zone, and manually moving it into the intended section with the Move to menu or a drag. This triage step repeats for nearly every note and makes sections feel like an after-the-fact filing chore rather than a natural part of capture.

## Solution

Notes created from inside the panel land where the user is working, while capture from other apps stays predictable.

- The composer files new notes into the active section: the section of the currently selected note, or the unsectioned inbox when nothing is selected.
- A `#section` token typed in the composer overrides the default. A fuzzy autocomplete popup suggests sections; a confirmed token is stripped from the note text and sets the destination.
- A subtle trailing label in the composer always shows where the note will go, so the destination is never a surprise.
- Vim paste (`p`) inserts the new note directly after the selected note, inheriting its section, matching how `o`/`O` already behave.
- Shift-Shift capture continues to land in the unsectioned inbox, since it fires while Bronze is hidden and any in-panel context would be stale and invisible.

## User Stories

1. As a Bronze user, I want a note typed in the composer to land in the section of my selected note, so that I do not have to move it there afterwards.
2. As a Bronze user, I want composer notes to land in the unsectioned inbox when nothing is selected, so that today's behavior is preserved when I have no context.
3. As a Bronze user, I want to type a `#section` token in the composer, so that I can file a note into any section without changing my selection.
4. As a Bronze user, I want a fuzzy autocomplete popup when I type `#`, so that I can pick a section with a few keystrokes.
5. As a Bronze user, I want the autocomplete popup to stay passive until I engage it, so that typing `#` inside prompts or code snippets does not hijack my keystrokes.
6. As a Bronze user, I want a `#` that I dismiss or never confirm to remain literal text in my note, so that Markdown headings and code fragments survive untouched.
7. As a Bronze user, I want a confirmed section token stripped from the note text, so that the saved note contains only my content.
8. As a Bronze user, I want an unambiguous `#prefix` to resolve on commit even if I never opened the popup, so that filing stays a no-extra-keystroke flow once I know my section names.
9. As a Bronze user, I want a trailing label in the composer showing the destination section or "Inbox", so that I always know where the note will land before pressing Return.
10. As a Bronze user, I want the destination label to update the moment a token is confirmed, so that the override is visibly acknowledged.
11. As a Bronze user, I want composer notes appended to the end of the target section, so that section order stays chronological and familiar.
12. As a Bronze user, I want the existing scroll-to-new-note behavior to follow the note into its section, so that I can see what I just added.
13. As a Vim-bindings user, I want `p` to paste the clipboard as a note directly after my selected note in the same section, so that paste lands where my cursor is.
14. As a Vim-bindings user, I want `p` with no selection to keep appending to the inbox, so that the fallback stays predictable.
15. As a Vim-bindings user, I want `o` and `O` to keep creating notes adjacent to the selection in the same section, so that in-panel creation is consistent everywhere.
16. As a capture user, I want Shift-Shift captures to always land in the unsectioned inbox, so that capture never silently mis-files into a section I forgot was active.
17. As a user with several notes selected, I want the anchor note's section to be the composer target, so that multi-selection has one deterministic destination.
18. As a user with an active search, I want the selected filtered note's section to be the composer target, so that the rule stays the same under search.
19. As a user who mis-filed a note, I want the existing Move to menu and drag behavior unchanged, so that recovery stays one keystroke away.
20. As a user who typos a token, I want an unmatched `#text` to stay literal with no section created, so that typos never spawn junk sections.

## Implementation Decisions

- The note store's create operation accepts an optional target section and appends the note at the end of that section's run, defaulting to the unsectioned zone. The existing insert-adjacent operations already cover the `o`/`O`/`p` cases.
- The app model resolves the composer's default destination from the current selection anchor at commit time; it is not cached or sticky. No selection resolves to the unsectioned inbox.
- The Vim paste command switches from append-to-inbox to insert-after-anchor, inheriting the anchor's section. Without a selection it falls back to the current append-to-inbox behavior.
- Shift-Shift capture keeps its current code path and always files into the unsectioned zone. This is a deliberate product decision, not a gap.
- Section token parsing is a pure function living in the core module: given composer text and the section list, it yields the resolved section (if any) and the cleaned note text. This keeps the parsing logic testable without UI.
- A token is only honored in two cases: the user confirmed a suggestion in the autocomplete popup, or the token text is an unambiguous case-insensitive prefix of exactly one section name at commit time. Anything else leaves the text untouched.
- The autocomplete popup triggers only when `#` is typed at a word boundary. It renders passively; arrow keys, Tab, and Return engage it only while it is visible and highlighted. Escape dismisses it and leaves the `#` literal.
- The token may appear anywhere in the composer text. Confirmed tokens are stripped along with one adjacent space.
- Tokens never create sections. Section creation remains the existing Add Section flow.
- The destination label is a tertiary-styled text element at the trailing edge of the composer, using existing design tokens. It shows the resolved section name or "Inbox" and updates live.
- Section names are matched case-insensitively. Duplicate section names resolve to the first match in section order.

## Testing Decisions

- Tests assert external behavior only: which section a created note ends up in, its position in display order, and what text survives parsing — never internal array layouts or view state.
- The core note store is the primary seam, exercised through its public API exactly as the existing store tests do (adding notes, then asserting on display order and per-section queries). New tests cover targeted creation, section-end placement, and paste-after-anchor placement.
- The token parser is the second seam: pure input/output tests over composer text plus a section list, covering confirmed matches, unambiguous prefixes, ambiguous prefixes, unmatched tokens, word-boundary triggering, and stripping behavior.
- Prior art: the existing core test suites for store operations, persistence, and search establish the style — small swift-testing cases against the public core API with no UI involvement.
- Popup interaction (arrow keys, Tab, Escape) is verified manually; no UI test harness exists and adding one is out of scope.

## Out of Scope

- Creating sections from the composer token.
- Any change to Shift-Shift capture behavior or a post-capture section picker.
- Sticky or last-used section memory.
- Top-of-section insertion modes or per-section composers.
- Changes to the Move to menu, drag-and-drop, or section management.
- A UI test harness for the autocomplete popup.

## Further Notes

- The design was driven by prior art: Things files into the focused project, Todoist parses `#project` tokens with autocomplete confirmation, Apple Reminders adds to the current list. Bronze combines the first two and keeps capture inbox-only like Things' Quick Entry.
- Notes in Bronze are often AI prompts containing `#` in code or Markdown; the confirmation-guarded token design exists specifically so that literal `#` text is never consumed by accident.
- If the no-creation rule stings in practice, a "Create section" row in the autocomplete popup is the natural follow-up.
