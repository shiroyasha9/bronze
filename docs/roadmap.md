# Bronze — v0.2+ Roadmap

Features discussed during planning and deliberately cut from MVP. Ordered roughly by priority.

## Shipped since v0.1.0

- **Section-aware note filing** — composer notes land in the active section; `#section` token with fuzzy autocomplete overrides; destination label in the composer. Vim `p` pastes after the selection in the same section. (spec: specs/new-note-section-assignment.md)
- **Sparkle auto-updates** — signed appcast attached to each GitHub Release; `make appcast` + the `release` skill own the flow.
- **Developer ID signing, notarization, dmg** — `make dmg`, manual for now (CI later).
- **Paid prebuilt binary** — pay-what-you-want on Gumroad, same build free on GitHub Releases.
- Escape unfocuses the composer instead of hiding the panel; the panel hotkey brings a visible-but-unfocused panel to front; alerts anchor to the panel's screen.

## v0.2

- **Fuzzy search** — replace substring matching; committed as the immediate next feature. Needs scoring tuned so results never feel random (likely Smith-Waterman-ish subsequence scoring like fzf, weighted toward word starts).
- **Undo** — ⌘Z / vim `u`. Store-level operation log; unlocks guilt-free no-confirm delete.
- **Custom shortcuts** — rebind capture chord (double-Shift default), panel toggle, and per-action bindings. Requires a settings window.
- **Settings window** — hotkey rebinding, capture on/off, Copy-as-List format (numbered vs `-` bullets), panel opacity/material.
- **Merge Notes** (⇧⌘M) — combine selected notes into one; define join rule (newline join, keep earliest position).
- **Move to** submenu parity — full Copper-style context menu with section submenu.

## v0.3+

- **Multiple projects** — project switcher in panel header; schema already carries `projectId`, so this is UI + a picker, no migration.
- **Edit in New Window** (⌘↩) — detached editor window for long notes.
- **Expand** — in-place expansion of clamped notes (context-menu item exists in Copper; semantics TBD).

## Distribution track (parallel)

- CI releases: xcodegen + xcodebuild + notarytool + generate_appcast in GitHub Actions (today the flow is local via `make appcast`).
- **Homebrew cask** once releases are stable.

## Explicitly not planned

- Sync, accounts, telemetry of any kind — local-only is the product's identity.
- App Store distribution — sandbox likely conflicts with AX capture; direct download only.
