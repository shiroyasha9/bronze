# Spec: Keyboard Shortcut Guide

## Problem Statement

Bronze is keyboard-driven (Vim-style navigation, chords, visual mode) but none of its ~35 shortcuts are discoverable inside the app. New users never learn the fast paths; even the developer forgets rare bindings. Direct competitors (Tot, Antinote, Raycast Notes) all punt shortcut docs to the web - there is no in-app reference to imitate or fall back on.

## Solution

An in-panel shortcut guide overlay, opened from a new "Keyboard Shortcuts" item in the ellipsis menu or via ⌘/ (and "?" when not typing). The overlay covers the panel with a glass-consistent surface listing every shortcut, grouped by activity, with two aligned keycap columns - Standard and Vim - so each audience scans its own column instantly. Esc, ⌘/, "?", or a click anywhere dismisses it. The ellipsis menu also gains keycap hints on items that have bindings.

## User Stories

1. As a new user, I want a "Keyboard Shortcuts" menu item in the ellipsis menu, so that I can discover the guide without knowing any shortcut.
2. As a keyboard user, I want ⌘/ to toggle the guide, so that I can open it without touching the mouse.
3. As a Vim user, I want "?" to open the guide when I'm not typing in a text field, so that the muzzle-memory binding from other tools works here.
4. As a Vim user, I want a dedicated Vim keycap column, so that I can scan only my bindings and ignore the standard ones.
5. As a non-Vim user, I want a Standard keycap column, so that I'm not confused by single-letter Vim keys.
6. As a user, I want shortcuts grouped by activity (Capture, Navigate, Select, Organize, Panel), so that I can find the binding for what I'm trying to do.
7. As a user, I want actions with two bindings shown on one row (e.g. toggle done: Space / x), so that I see they're equivalent rather than duplicates.
8. As a user, I want the guide to scroll, so that all shortcuts are reachable inside the small panel.
9. As a Vim user, I want j/k to scroll the guide while it is open, so that the guide itself behaves like the rest of the app.
10. As a user, I want Esc, ⌘/, "?", or a click anywhere on the overlay to dismiss it, so that closing is effortless.
11. As a user, I want normal panel keys suppressed while the guide is open, so that browsing the guide can't accidentally delete or toggle notes.
12. As a user, I want the overlay to match the panel's glass aesthetic with a subtle fade/scale-in, so that it feels native to Bronze.
13. As a menu user, I want keycap hints beside ellipsis-menu items that have shortcuts, so that I learn bindings at the moment of use.
14. As a user, I want ⌘⇧N to add a section, so that the most common menu action has a fast path.
15. As a user, I want destructive Clear actions to remain shortcut-free, so that I can't mass-delete notes by accident.

## Implementation Decisions

- Presentation: full-panel overlay rendered inside the existing panel window - no new NSWindow, sheet, or popover. Bronze's single-surface always-on-top feel is preserved (decision from grilling; competitor research confirmed overlay is the dominant pattern in Linear/Slack/Superhuman).
- Triggers: menu item, ⌘/ anywhere in the panel, "?" only when no text field (editor, composer, search) has focus. "?" is a printable character, so it must never fire while typing.
- Dismissal: Esc, ⌘/, "?", or click anywhere on the overlay. No close button. Scrolling does not dismiss.
- Input while open: key routing swallows all panel keys except the dismiss keys and j/k, which scroll the guide.
- Data source: a static declarative item list (label, standard key, vim key, section) owned by the guide view. Deliberately NOT derived from the key router - the router's chords, modes, and context-dependence make declarative unification a high-risk refactor with marginal gain. Revisit only if user-customizable bindings ever land.
- Layout: small-caps section headers; each row = label left, then two right-aligned keycap columns headed "Standard" and "Vim"; rounded keycap tokens styled via existing design tokens; Vim-only actions leave the Standard cell empty.
- Sections and contents: Capture (new note, insert below/above, edit), Navigate (cursor, half-page, first/last, section jumps, center), Select (visual mode, toggle done, delete, copy, paste, clear), Organize (move-to-section, add section, reorder), Panel (show/hide, search, pin, shortcut guide itself, quit).
- Ellipsis menu: "Keyboard Shortcuts" appended at the bottom after a divider, showing ⌘/. "Add Section…" shows ⌘⇧N. Both bindings are actually routed by the key router (SwiftUI keycaps on menu items alone only fire while the menu is open). Clear submenu and toggles stay bare.
- State: a single published boolean on the app model toggles the overlay; the root panel view conditionally overlays the guide.
- No search field in v1: at ~35 grouped entries, scanning beats searching.

## Testing Decisions

- The Core package holds all automated tests; the App layer (SwiftUI/AppKit UI) has none by convention. This feature is pure App-layer UI and touches nothing in Core, so no automated tests are added.
- Good tests here would only assert external behavior (overlay visible/hidden, keys routed); the app currently has no seam for driving the key monitor or panel window headlessly, and building one for a static guide is not worth the surface area.
- Verification is manual: build via `make run`, kill and relaunch the app, then exercise every trigger, dismiss path, and the two keycap columns.

## Out of Scope

- User-customizable keybindings (no note app peer offers in-app rebinding; only the global hotkey would ever warrant it).
- Search/filter inside the guide.
- A declarative shortcut table shared with the key router.
- Shortcuts for Clear actions or menu toggles.
- A separate help window, printable version, or web documentation.

## Further Notes

- Competitor scan (2026-07): Tot, Antinote, Raycast Notes, Unclutter ship no in-app guide - this is a small differentiator.
- "?"-only triggering was rejected as primary because it cannot fire while any text field is focused; ⌘/ (Slack convention) is the reliable binding, "?" (Linear convention) is the bonus.
- The guide view's static list will drift if bindings change; the ellipsis menu item is the reminder that the guide exists and must be updated alongside any KeyRouter change.
