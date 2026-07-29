# Bronze

An open-source, Copper-inspired scratchpad for AI-assisted work. Native macOS, keyboard-first, local-only.

Capture selected text from any app with a double-tap of Shift. Notes live as checklist cards in a floating panel beside your work. Copy them back out as a numbered list, ready to paste into ChatGPT, Claude, or Cursor.

- Floating always-on-top panel, menu bar accessory (no Dock icon)
- Double-Shift capture from any app
- Sections, inline markdown, live search
- Full keyboard map plus a vim layer
- One local JSON file — no account, no sync, no telemetry
- MIT licensed

## Build

Requires Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
make gen     # generate Bronze.xcodeproj
make build   # build the app
make test    # run core tests
make run     # build and launch
```

## Docs

- [MVP spec](docs/spec.md)
- [Roadmap](docs/roadmap.md)
- [Research notes](research/)
