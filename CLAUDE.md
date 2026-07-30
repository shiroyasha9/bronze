# Bronze

macOS floating notes panel (SwiftUI + AppKit, xcodegen).

## Local development

- Build and run: `make run`
- `open` reuses a running instance, so after rebuilding always kill and relaunch:

```sh
pkill -9 -x Bronze; sleep 1; open .build/xcode/Build/Products/Debug/Bronze.app
```

- SourceKit per-file diagnostics (e.g. "Cannot find type 'AppModel' in scope") are noise; trust the xcodebuild result.
