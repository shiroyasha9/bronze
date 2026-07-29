# Bronze — v0.2+ Roadmap

Features discussed during planning and deliberately cut from MVP. Ordered roughly by priority.

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

## Distribution track (parallel, when going public)

- Apple Developer account ($99/yr), Developer ID signing + notarization.
- **Sparkle** for self-hosted updates (appcast on GitHub Pages or teensy.tech).
- GitHub Releases: notarized `.dmg`/`.zip` via CI (xcodegen + xcodebuild + notarytool in Actions).
- **Homebrew cask** once releases are stable.
- Optional later: small fee for prebuilt binary (code stays MIT; paying skips self-building), e.g. Lemon Squeezy like Copper.

## Explicitly not planned

- Sync, accounts, telemetry of any kind — local-only is the product's identity.
- App Store distribution — sandbox likely conflicts with AX capture; direct download only.
