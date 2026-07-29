# Copper (shadcn) - research

Accessed 2026-07-29. Primary sources only: the product page, its privacy/terms pages, the official demo video hosted on the site, and the checkout endpoint. No shadcn X/Twitter post about Copper is indexed by search yet, and `x.com` is not fetchable (HTTP 402 via WebFetch, CAPTCHA via mirrors), so nothing here comes from his posts.

Sources used throughout:

- P = https://shadcn.com/copper (landing page)
- V = https://shadcn.com/copper.mp4 (official demo video linked from P; 47s, 1920x1080, h264 - frames inspected directly)
- PR = https://shadcn.com/copper/privacy
- T = https://shadcn.com/copper/terms
- S = https://store.shadcn.com/checkout/buy/91fe6f9b-b424-4685-8213-3b99caf64cb9 (redirects to `store.shadcn.com/checkout/cart/...`)
- D = https://shadcn.com/copper/download (license-gated endpoint)

## 1. What it is

A paid, local-only macOS app by shadcn for holding scratch material while you work across AI tools. Product page, verbatim: "Copper combines the useful parts of a to-do list, a clipboard, and a scratchpad into one app built specifically for AI-assisted work." (P) The framing is the mid-conversation "I'll need this later" problem: you are in ChatGPT, then Claude, then Cursor, then Chrome, and "you've got little things scattered everywhere. An answer you want to keep. A link. An idea. Or three follow-up prompts before the current one is even finished." (P) shadcn says he built it for himself and has "been using it every day for months," across "multiple projects and multiple apps." (P) Meta description: "The useful parts of a to-do list, a clipboard, and a scratchpad in one app built for AI-assisted work. Capture with a keystroke, copy it back when you need it." (P, `<meta name="description">`)

## 2. Feature set

The 12-item list in the task brief is confirmed exactly - it is a title card near the end of the demo video (V, ~46s), two columns:

| Column 1 | Column 2 |
| --- | --- |
| Merge Notes | Local Files |
| Sections | No Tracking |
| Markdown | No Account |
| Copy as List | Free Updates |
| Search | Keyboard-First |
| Custom Shortcuts | Native Mac App |

What each one demonstrably means, from the video and the prose pages:

- **Capture shortcut** - select text anywhere, press Shift twice, and it lands in Copper. "Whenever I find something worth keeping, I hit Shift twice and capture it." (P) The video shows the selection made in an AI chat window, a small black "Captured" toast appearing next to the selection, and the note appearing in the panel (V, ~12s).
- **Merge Notes** - context-menu item, shortcut Shift-Cmd-M (V, ~40s). Behavior not shown.
- **Sections** - notes are grouped under small uppercase headers with a hairline rule; the demo shows `RESEARCH` and `CONFIGURATION FORMATS` (V, ~12-20s).
- **Markdown** - notes render inline bold and italic; e.g. a captured note reads "Use **TOML as the default declarative format**, backed by a published schema" with the bold preserved from the source (V, ~12s).
- **Copy as List** - context-menu item, Shift-Cmd-C. In the demo two notes are multi-selected, copied as a list, and pasted into the chat composer where they appear as "1. How should configuration migrations work? 2. Should plugins own their configuration schema?" (V, ~40-44s).
- **Search** - a search field is the first element in the panel header (V, ~12s). Search behavior is never exercised on camera.
- **Custom Shortcuts** - claimed on the feature card only; no configuration UI is shown.
- **Local Files / No Tracking / No Account** - "Copper doesn't sync anything, doesn't collect anything, and doesn't need an account. Your notes are saved to a local file." (P) "Copper saves your notes to a file on your Mac. That file is the only copy." (PR) "No analytics, no telemetry, no crash reports, no usage data." (PR)
- **Free Updates** - "Future updates to Copper are part of what you paid for." (T)
- **Keyboard-First / Native Mac App** - claimed on the feature card; every context-menu item in the demo has a keyboard equivalent, which is consistent.

Full context menu on a note (V, ~40s), verbatim with shortcuts:

```
Copy                 ⌘C
Copy as List        ⇧⌘C
Mark as Done       Space
Expand              (disabled in this state)
─────
Edit                   ↩
Edit in New Window    ⌘↩
Merge Notes         ⇧⌘M
Move to                ▸
```

The menu is clipped by the bottom of the screen in the recording, so there may be items below "Move to" (a Delete, most likely). "Move to" has a submenu arrow, presumably targeting sections.

## 3. UX / interaction model

- **Window style**: a narrow floating panel pinned to the right edge of the screen, rounded corners, translucent over the desktop, staying on top of the AI app window and surviving focus changes (V, ~12-24s). No menu bar icon is visible in any frame, and the panel is not a menu bar dropdown - it stays put while the user works in another app. Whether it also has a Dock presence is not shown.
- **Panel layout**, top to bottom: a `Search` field with a magnifier icon, an overflow `...` button to its right, then the sectioned note list, then a composer pinned to the bottom (V, ~12s).
- **Note = checklist item**: every note is a rounded card with an empty circular checkbox on the left and wrapped text on the right. "Mark as Done / Space" in the context menu and the landing-page line "check them off as I go" (P) confirm the checklist semantics. No frame in the video shows a checked note, so the done state (strikethrough? moved? hidden?) is unknown.
- **Composer**: the bottom card is an inline note-in-progress - it has its own checkbox circle and a placeholder reading `Add a note or a prompt (development)`. Typing into it grows the card, and pressing return commits it into the list above; a new empty composer takes its place (V, ~30-36s). The parenthetical "(development)" is not one of the visible section names, so it likely names the active project/list rather than the section - unconfirmed.
- **Selection**: notes get a blue outline when selected, and multiple notes can be selected at once (two are outlined simultaneously before "Copy as List") (V, ~40s).
- **Truncation**: long notes are clamped to about three lines with a trailing ellipsis, which lines up with the "Expand" menu item.
- **The loop the product sells** (title cards, verbatim, V): "Capture the 'I'll need this later' with a quick shortcut" -> "It works everywhere." -> "Write down the prompts already in your head, but not ready to send." -> "Send them to your chat with one shortcut..." -> feature grid -> "shadcn.com/copper".
- **Apps shown**: the Dock in the demo shows ChatGPT, Claude, and Chrome (V, ~22s); the landing page names "ChatGPT, Claude, or Cursor" (P). Copy back out is plain Cmd-C then paste ("then Cmd C back into ChatGPT, Claude, or Cursor" - P).

## 4. Data model

Confirmed: **one local file**, no sync, no server copy. "Your notes are saved to a local file." (P) "Copper saves your notes to a file on your Mac. That file is the only copy. I never see them, and I couldn't hand them to anyone who asked." (PR) The terms push backup responsibility to the user: notes are stored locally and you keep your own backups (T).

Not stated anywhere: the file's format, its path, or whether it is one file per project. The "Markdown" feature and the singular "a file" together suggest a single Markdown or Markdown-like document rather than a folder of notes, but that is inference, not a claim any page makes.

## 5. Positioning and pricing

- **$39, one-time.** "If this feels like something you'd use, it's $39. One-time purchase." (P)
- **Launch pricing**: "Launch price. $49 next week." (P) - so the page was live within roughly a week of 2026-07-29, and the price is set to rise to $49.
- **Refunds**: 30 days, by email. "If Copper isn't for you, send me an email within 30 days and I'll refund your purchase." (P) Contact is m@shadcn.com, processed through Lemon Squeezy (T).
- **License**: "A license to use Copper on the Macs you use, for work or for your own projects. One person, one license." (T) Future updates included. No resale, no key sharing; the terms describe it as an honor system with no enforcement after install (T).
- **Warranty**: as-is, liability capped at the purchase price (T).
- **Requirements**: "macOS 14 or later. Copper needs Accessibility access to read your text selection and listen for its shortcuts." (P)
- **Target user**: people doing AI-assisted work in several tools at once - the whole page is written to a developer using ChatGPT/Claude/Cursor/Chrome side by side.

## 6. Tech

- The only self-description is the video's "Native Mac App" card (V) plus "Everything stays on your Mac" (P). **Nothing on any page says SwiftUI, AppKit, Electron, or Tauri**, and there is no public statement about how it is built.
- Circumstantial support for native: macOS 14 minimum, Accessibility API use for reading the text selection and registering a global double-Shift hotkey, standard macOS context menus with standard shortcut glyphs, and a translucent panel window (P, V).
- **Updates**: self-hosted, not the App Store. "Copper asks my server whether a newer version exists, and downloads it if one is one [sic]." Those requests carry only IP and version number (PR). Consistent with Sparkle or a hand-rolled equivalent; not stated which.
- **Payments/licensing**: Lemon Squeezy. Activation sends the license key to Lemon Squeezy servers during install (PR).
- The marketing site itself is Next.js on Vercel (`_next` chunks, `server: Vercel`), and uses Vercel Analytics - "counts page views without cookies and without building a profile of you" (PR). This says nothing about the app.

## 7. Distribution

Direct only, license-gated. There is no App Store link anywhere on the product, privacy, or terms pages, and no App Store listing exists for it - the "Copper" on the Mac App Store (id1048885755) is an unrelated PCB viewer. Purchase goes through a Lemon Squeezy checkout at `store.shadcn.com` (S), and "After checkout you'll get a one-line install command." (P) The install presumably calls `https://shadcn.com/copper/download`, which is live and returns HTTP 400 with the plain-text body `Missing license key. Get one at https://shadcn.com/copper` when called without credentials (D).

Copper is also unlisted on shadcn's own homepage: https://shadcn.com lists shadcn/ui, shadcn/registry, shadcn/ds, and v0, with zero occurrences of "copper" in the HTML. The `/copper` page is reachable only if you have the URL.

## Unresolved questions

- Notes file format and location on disk. Markdown? JSON? One file or one per project? None of the pages say.
- Whether the app is SwiftUI or AppKit - no primary source states any implementation detail beyond "Native Mac App".
- Whether shadcn announced Copper on X. Nothing is indexed, and x.com could not be fetched. Worth re-checking his profile manually.
- Exact launch date. Only inferable as "within about a week before 2026-07-29" from the "$49 next week" line.
- What "(development)" in the composer placeholder refers to - a project, a workspace, or the active section.
- Whether the context menu has items below "Move to" (Delete?); the recording clips them at the screen edge.
- What "Expand", "Merge Notes", and "Move to" actually do - all three appear only as menu items, never exercised.
- Done-state behavior after "Mark as Done", and whether completed notes are archived or deleted.
- Search behavior (fuzzy? section-scoped? live filter?) - the field is visible but never used on camera.
- What "Custom Shortcuts" is configurable down to, and whether the double-Shift capture chord can be changed.
- Menu bar presence, Dock behavior, launch-at-login, and multi-monitor placement of the panel.
- Team/volume licensing, and whether an App Store release is planned.
