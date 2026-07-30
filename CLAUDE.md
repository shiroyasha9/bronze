# Bronze

macOS floating notes panel (SwiftUI + AppKit, xcodegen).

## Local development

- Build and run: `make run`
- `open` reuses a running instance, so after rebuilding always kill and relaunch:

```sh
pkill -9 -x Bronze; sleep 1; open .build/xcode/Build/Products/Debug/Bronze.app
```

- SourceKit per-file diagnostics (e.g. "Cannot find type 'AppModel' in scope") are noise; trust the xcodebuild result.

## Shipping an update (Sparkle)

Use the `release` skill (.claude/skills/release) — it owns the full flow.

The EdDSA private key lives in the login Keychain (created by Sparkle `generate_keys`). Losing it breaks auto-updates for existing users - export a backup with `generate_keys -x <file>`.
