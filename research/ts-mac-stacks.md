# Native-feeling macOS apps in TypeScript (2026)

Research date: 2026-07-29. Target profile: small floating panel notes/todo app (Raycast-style). Borderless non-activating window, vibrancy/blur, global hotkey, native context menus, menu bar presence, local file storage, tiny footprint.

Primary sources only (official docs, first-party repos, crates.io/npm registry APIs).

---

## 0. Verdict on Glaze (asked first, answered first)

**Glaze is real. It is not a framework.**

Raycast shipped Glaze: private beta 2026-03-04, public 2026-07-01. But it is a closed-source, credit-metered AI app-builder product, not a TS-to-native SDK you can adopt.

| Claim | Reality |
|---|---|
| Made by Raycast | Yes. [raycast.com/blog/introducing-glaze](https://www.raycast.com/blog/introducing-glaze), [meet-glaze](https://www.raycast.com/blog/meet-glaze) |
| TypeScript involved | Yes, apps are TS projects on disk |
| A framework/SDK you can install | **No.** No npm package, no public SDK, no docs for hand-authoring an app from scratch |
| Open source / licensed for reuse | **No.** No repo, no license, no `raycast/glaze` on GitHub |
| Produces "native" AppKit apps | **No.** See below |
| Free | No. Free tier = 120 one-time credits. Pro $20/mo (200 credits). Team $30/seat/mo. [glaze.app/pricing](https://www.glaze.app/pricing) |
| Runs anywhere | **macOS Tahoe + Apple Silicon only.** Windows/Linux "planned" |

**It is a webview app builder, not a native one.** Raycast never states the runtime publicly, but the manual gives it away: a Glaze app is "a normal project on disk there: a renderer (the UI), a backend (the 'main' process), and the files that tie them together" ([manual.glaze.app/advanced/editing-code](https://manual.glaze.app/advanced/editing-code)). "Renderer" + "main process" is Electron's exact process vocabulary. On [HN](https://news.ycombinator.com/item?id=47247033) multiple people asked Raycast CEO thomaspaulmann directly whether it was native or Electron; he answered around the question and never confirmed a stack. Treat "native Mac apps" in Glaze marketing as meaning "real .app bundle that runs offline", not "AppKit".

Sources are hand-editable at `~/Library/Application Support/app.glaze.macos.main/apps/<app>/.glaze-sources`, so you can read what it generates. That is the only way to learn the stack, and it is not a supported integration point.

**Capabilities it does expose** (relevant if you use Glaze as a product rather than a stack): global hotkey, menu bar icon with dropdown, frameless windows, always-on-top floating/utility windows, transparent windows with click-through, custom URL scheme, drag-and-drop, file associations, notifications. Notably **no vibrancy/blur is documented** ([capabilities/windows](https://manual.glaze.app/capabilities/windows), [system-integration](https://manual.glaze.app/capabilities/system-integration), [notifications-menu-bar-tray](https://manual.glaze.app/capabilities/notifications-menu-bar-tray)).

**What Raycast actually uses for extensions:** TypeScript + React + Node, but against Raycast's own component set, not DOM. "Use our built-in UI components... You concentrate on the logic, we push the pixels" ([developers.raycast.com](https://developers.raycast.com/)). The extension developer never controls rendering; the host app does. This is a real TS-to-host-UI bridge, but it only works *inside Raycast*, and it is not published as a standalone app framework. (Raycast has not publicly documented the host renderer as AppKit; widely assumed, unconfirmed from primary source.)

**Bottom line: cross Glaze off the stack list.** It is a competitor/product, not infrastructure.

---

## 1. Tauri v2

**Version:** `tauri` 2.11.5, published 2026-07-01. Minors every 2-3 months, patches every 2-6 weeks. No v3 planned. MSRV 1.85 (edition 2024). ([crates.io/api/v1/crates/tauri](https://crates.io/api/v1/crates/tauri), [v2.tauri.app/release](https://v2.tauri.app/release/))

**NSPanel: third-party, but excellent.** No first-party API; the feature request [tauri#13034](https://github.com/tauri-apps/tauri/issues/13034) is open since 2025-03. [ahkohd/tauri-nspanel](https://github.com/ahkohd/tauri-nspanel) (413 stars, branch `v2.1`, git dependency only, not on crates.io) covers everything Copper needs:

- `StyleMask::nonactivating_panel()`, `.borderless()`
- `CollectionBehavior::can_join_all_spaces()`, `.full_screen_auxiliary()`, `.stationary()`, `.ignores_cycle()`
- `PanelLevel::Floating` .. `ScreenSaver`
- `.no_activate(true)`, `order_front_regardless()`, `.corner_radius(f64)`, `.has_shadow()`, `.hides_on_deactivate()`
- `panel_event!` delegate hooks for `window_did_become_key` / `window_did_resign_key` (dismiss-on-blur)
- `TrackingAreaOptions` for hover

Caveat: last *functional* commits are 2025-09..2025-11; 2026 pushes are dependency/CI churn. Stable, not fast-moving. Companion [ahkohd/tauri-toolkit](https://github.com/ahkohd/tauri-toolkit) (menubar, popover, monitor) and [tauri-macos-menubar-app-example](https://github.com/ahkohd/tauri-macos-menubar-app-example) are both fresh (2026-07-24).

**Vibrancy: first-party and good.** `windowEffects` directly in `tauri.conf.json` (`{ "effects": ["hudWindow"], "state": "active", "radius": 12 }`), or `window-vibrancy` 0.8.0 (2026-07-16) for more control. Full `NSVisualEffectMaterial` set including `HudWindow`, `Popover`, `Sidebar`, `UnderWindowBackground`. 0.8.0 added `NSGlassEffectViewStyle` (Liquid Glass, macOS 26+). Requires `"transparent": true` **and `macOSPrivateApi: true`**. ([docs.rs/window-vibrancy](https://docs.rs/window-vibrancy/0.8.0/window_vibrancy/), [tauri_utils WindowConfig](https://docs.rs/tauri-utils/latest/tauri_utils/config/struct.WindowConfig.html))

**Global shortcut:** `tauri-plugin-global-shortcut` 2.3.2 (2026-05-28), first-party. No Accessibility permission needed for ordinary combos (uses Carbon `RegisterEventHotKey`); media keys are the exception and are [currently broken](https://github.com/tauri-apps/plugins-workspace/issues/2868). Manager must be created on the main thread. ([v2.tauri.app/plugin/global-shortcut](https://v2.tauri.app/plugin/global-shortcut/))

**Tray + menus:** first-party (`tray-icon` feature). Menus are real NSMenu via the first-party [muda](https://github.com/tauri-apps/muda) crate. `showMenuOnLeftClick(false)` so left-click toggles the panel. Context menu at cursor from JS: `Menu.popup()` with no argument opens at current mouse location. Gap: no SF Symbols in menu items ([tauri#15343](https://github.com/tauri-apps/tauri/issues/15343)). ([v2.tauri.app/learn/system-tray](https://v2.tauri.app/learn/system-tray/), [reference/javascript/api/namespacemenu](https://v2.tauri.app/reference/javascript/api/namespacemenu/))

**Autostart / single-instance:** both first-party. Autostart needs an explicit macOS launcher type at init. Single-instance must be registered first in the plugin chain. ([autostart](https://v2.tauri.app/plugin/autostart/), [single-instance](https://v2.tauri.app/plugin/single-instance/))

**Storage:** `tauri-plugin-store` 2.4.4 (JSON KV, debounced autosave), `tauri-plugin-sql` 2.4.0 (SQLite via sqlx, with migrations), or `fs` plugin with scoped permissions. Or just use `rusqlite` in the Rust backend and skip IPC permissions entirely.

**Size:** official claim "less than 600KB" for minimal; ~4MB realistic with full API surface. ([v2.tauri.app/start](https://v2.tauri.app/start/))

**Pain points, in severity order:**

1. **Transparency is a GPU disaster on macOS 26.** [tauri#15471](https://github.com/tauri-apps/tauri/issues/15471) (open, 2026-06-04): `"transparent": true` forces WebKit/WindowServer to recomposite every display frame even with static content. Measured **~8x GPU power on Apple Silicon (620mW vs 75mW)**; 1380% CPU on the GPU process on Intel. Affects Tauri 2.11.2 on macOS 26.5-26.6. The only stated workaround is not using transparency. **This directly threatens the vibrancy design and is the single biggest risk in this report.**
2. `macOSPrivateApi: true` (required for transparency) **bars App Store distribution**. Developer ID + notarization is the only path.
3. Rounded corners: CSS `border-radius` does not round top corners on macOS ([tauri#9287](https://github.com/tauri-apps/tauri/issues/9287), open since 2024). Use nspanel's native `.corner_radius()` instead.
4. WKWebView is version-locked to the OS; no engine pinning. ([webview-versions](https://v2.tauri.app/reference/webview-versions/))
5. Live macOS 26 regressions: [#15707](https://github.com/tauri-apps/tauri/issues/15707), [#15315](https://github.com/tauri-apps/tauri/issues/15315) (Liquid Glass `.icon` bundling fails), [#15517](https://github.com/tauri-apps/tauri/issues/15517).
6. Memory: no official figure. The official benchmark's methodology is disputed ([#5889](https://github.com/tauri-apps/tauri/issues/5889)) because it ignores Chromium's shared read-only pages. WKWebView has measured *worse* than Chromium for some workloads. Needs local measurement, do not assume Tauri wins on RAM.

---

## 2. Electron

**Version:** Electron 43 (43.0.0 on 2026-06-30, 43.2.0 on 2026-07-21), Chromium 150 / Node 24.17. Major every 8 weeks; latest 3 majors supported. Floor is macOS Ventura 13. ([electron-timelines](https://www.electronjs.org/docs/latest/tutorial/electron-timelines), [releases.json](https://releases.electronjs.org/releases.json))

**Non-activating panel: first-party, and purpose-built for exactly this app.** `BrowserWindow({ type: 'panel' })` adds `NSWindowStyleMaskNonactivatingPanel` at runtime and forces `CanJoinAllSpaces | FullScreenAuxiliary` collection behavior. In `native_window_mac.mm`, `Focus()` skips `activateIgnoringOtherApps:` for panels, with the comment: *"If we're a panel window, we do not want to activate the app, which enables Electron-apps to build Spotlight-like experiences."* ([base-window-options.md](https://github.com/electron/electron/blob/main/docs/api/structures/base-window-options.md), [electron_ns_panel.mm](https://github.com/electron/electron/blob/main/shell/browser/ui/cocoa/electron_ns_panel.mm))

This is the one place Electron beats Tauri outright: it is first-party, shipped since 2022, with follow-up fixes in 2023 and 2024.

Supporting APIs: `showInactive()`, `setAlwaysOnTop(true, 'screen-saver')` (levels `floating`..`status` sit *below* the Dock; `pop-up-menu` and above sit over it), `setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true, skipTransformProcessType: true })`, `acceptFirstMouse: true` (**required**, else the first click after showing is swallowed), `hiddenInMissionControl`, `app.dock.hide()`.

**Vibrancy:** first-party `vibrancy` option (14 materials incl. `under-window`, `hud`, `popover`, `sidebar`) plus `setVibrancy(type, { animationDuration })`. **Set `visualEffectState: 'active'`** or a non-activating panel renders grey when not key. `light`/`dark`/`medium-light`/`ultra-dark`/`appearance-based` were removed. `backgroundMaterial` is Windows-only. New in 43: `view.setBackgroundBlur(radius)`.

Transparent-window limits that bite: cannot click through the transparent area, **transparent windows are not resizable**, no native window shadow, and transparency breaks while DevTools is open. ([custom-window-styles](https://github.com/electron/electron/blob/main/docs/tutorial/custom-window-styles.md))

**Global shortcut:** first-party `globalShortcut`. Accessibility permission required only for media keys. **Registration silently fails if another app owns the combo** and `isRegistered` also returns false, so check the return value and surface conflicts. New: `setSuspended()`/`isSuspended()` (2026-04) for rebinding UI.

**Tray + menus:** real NSMenu (`electron_menu_controller.mm`) and real `NSStatusItem` (`tray_icon_cocoa.mm`). Icons must be Template images (`...Template.png` + matching `@2x`); webpack filename hashing breaks this. Use `guid` so the icon keeps its menu-bar position across relaunches. **Gotcha:** `click` is not emitted if you call `setContextMenu` (macOS constraint) so handle `click` -> toggle panel and `right-click` -> `tray.popUpContextMenu(menu)`. `Menu.popup()` defaults `x`/`y` to current cursor position.

**Autostart:** `app.setLoginItemSettings({ openAtLogin: true })`, `type: 'mainAppService'` (SMAppService, macOS 13+). `openAsHidden` deprecated. Legacy path being removed in v44 ([PR #52351](https://github.com/electron/electron/pull/52351)).

**Storage:** `safeStorage` (Keychain-backed; **use the async API**, the sync one may be deprecated), `app.getPath('userData')`, and since Electron 43 ships Node 24, `node:sqlite` is built in with no native addon.

**Size and memory (measured against official `electron-v43.2.0-darwin-arm64`):** 122 MB zip, **282 MB unpacked**. A minimal panel app (frameless + transparent + vibrancy + `type: 'panel'`, one 700x450 window) idles at **~186 MB physical footprint across 4 processes**. Realistic shipped .app: 250-300 MB. Most of the bulk is `Electron Framework.framework` and cannot be shrunk.

**Gaps needing a native addon:**

- **Key-window events.** `become-key`/`resign-key` ([PR #49299](https://github.com/electron/electron/pull/49299), explicitly motivated by NSPanel/Spotlight-style apps) is **open, not merged**. There is no clean JS signal for a panel losing key status, which is precisely what dismiss-on-blur needs. Tauri's nspanel *does* expose this. This is Electron's main hole for Copper.
- **Liquid Glass / `NSGlassEffectView`**: [PR #50415](https://github.com/electron/electron/pull/50415) closed unmerged. No API.
- Frontmost-app / selected-text capture (needs `AXUIElement` + Accessibility TCC).
- Runtime LSUIElement toggling (only `dock.hide()`, which has a documented 1-second debounce bug).
- Per-region vibrancy; native AppKit controls inside the panel.

First-party escape hatch guides exist: [native-code-and-electron-objc-macos.md](https://github.com/electron/electron/blob/main/docs/tutorial/native-code-and-electron-objc-macos.md).

**2025-26 macOS notes:** Electron 42 moved notifications to `UNNotification` and **now requires code signing for notifications to display at all**. Open Tahoe bugs: [#52437](https://github.com/electron/electron/issues/52437) (main-thread deadlock), [#47514](https://github.com/electron/electron/issues/47514) (inconsistent rounded corners), [#26350](https://github.com/electron/electron/issues/26350) (`visibleOnFullScreen` causes Dock dismissal, open since 2020), [#44150](https://github.com/electron/electron/issues/44150) (unfocusable panel with a parent never fires CSS `:hover`).

---

## 3. react-native-macos

**Version:** 0.81.9 (2026-07-13) against RN core 0.86.2. **~5 minors / roughly a year behind.** ([npm](https://registry.npmjs.org/react-native-macos))

**Health: genuinely alive.** 52 PRs merged since 2026-05-01, last commit 2026-07-24, 108 open issues, 4.4k stars, not archived, no maintenance-mode notice. ([microsoft/react-native-macos](https://github.com/microsoft/react-native-macos))

**react-native-windows is not deprecated** (v0.82 shipped). What was deprecated is the old Paper architecture, removed upstream at RN 0.82. Separate signal worth knowing: Microsoft is rewriting the Windows 11 shell in native WinUI, away from React. Org-level, not framework-level.

**Fabric/New Architecture: mid-migration, not done.** Active porting work in [#3037](https://github.com/microsoft/react-native-macos/pull/3037), [#3035](https://github.com/microsoft/react-native-macos/pull/3035), [#3030](https://github.com/microsoft/react-native-macos/pull/3030), all "Fabric and RCTUIKit". CI now builds RNTester New-Arch-only (2026-07-13).

**The problem: every single Copper feature is hand-written AppKit.** There is no JS API for any of them.

| Need | What you write |
|---|---|
| NSPanel non-activating window | Configure `NSPanel` in AppDelegate, host `RCTRootView`. Obj-C |
| NSVisualEffectView vibrancy | Custom Fabric component or `RCTViewManager`. Obj-C/Swift |
| Global hotkey | Native module over Carbon `RegisterEventHotKey`. Obj-C/Swift |
| NSStatusItem menu bar | Native module. The one community lib, [react-native-menubar-extra](https://github.com/okwasniewski/react-native-menubar-extra), is **unmaintained since Nov 2023** and predates Fabric |

**Verdict:** highest native fidelity available, highest cost by a wide margin. You would write more Objective-C for Copper than you would write TypeScript. Only justified if the app's value depends on genuinely native controls and scroll physics, which a notes/todo panel does not.

---

## 4. Everything else

| Stack | Status | Verdict |
|---|---|---|
| **Deno Desktop** | `deno desktop` shipped in **Deno 2.9, 2026-06-25**. Experimental. [docs.deno.com/runtime/desktop](https://docs.deno.com/runtime/desktop/) | **The interesting newcomer.** `Deno.BrowserWindow({ noActivate: true })` is documented as *"Floating, non-activating panel that doesn't steal focus"*, plus `frameless`, `alwaysOnTop`, `Deno.Tray.attachPanel()` (menu-bar-anchored popover that auto-hides on blur), `Deno.dock.setVisible(false)`. One-liners for what costs Tauri a git dependency. **But:** no vibrancy documented; **accelerators are menu-scoped, "global within the focused window", not true system-wide hotkeys**; no clipboard or secure-storage APIs; 40-150 MB binaries. Six weeks old. Prototype before betting on it; the hotkey gap is the likely blocker |
| **NativeScript macOS Node-API** | 0.4.0, **42 stars**, last push 2025-09-06. [NativeScript/macos-node-api](https://github.com/NativeScript/macos-node-api) | Purest "TypeScript writes AppKit" answer that exists: Node-API + libffi over the Obj-C runtime, reaches NSPanel/NSVisualEffectView/NSStatusItem directly. Far too immature to ship a product on |
| **NodeGui** | Core 0.74.2 (2026-05-03) alive but slow; **`react-nodegui` last pushed 2023-11-03** | No. Dead React layer, Qt widgets, does not look native |
| **Socket Runtime** | Last release **v0.5.4, 2023-12-22**; npm `0.6.0-rc.8` 2024-10; still pre-1.0 | No. Abandoned |
| **Wails** | v2.13.0 stable (2026-07-06); **v3 still alpha** (`3.0.0-alpha2.119`, 2026-07-27) | Marginal. Go backend, and the better window/systray API is in the perpetual alpha |
| **Neutralinojs** | v6.9.0 (2026-07-24), active | No. Deliberately minimal, no NSPanel/vibrancy/hotkey primitives |
| **Hydraulic Conveyor** | [conveyor.hydraulic.dev](https://conveyor.hydraulic.dev/) | **Not a UI framework.** Packaging/signing/auto-update tool. Useful *alongside* Electron, irrelevant as a stack choice |
| **Lynx (ByteDance)** | 4.0, very active | No. Desktop uses a custom renderer for "pixel-perfect consistency" (i.e. not AppKit), and quick-start docs cover only iOS/Android/HarmonyOS |
| **`objc` / NodObjC** | `objc` npm 0.23.0 **published 2022-01-21**, self-described experimental | Dead |
| **`@nativewindow/webview`** | napi-rs bindings over Tauri's wry+tao, self-declared beta | Tauri's guts without Rust. If you want this, just use Tauri |
| **Bun** | No official desktop/webview story | N/A |
| **Dioxus / Compose Multiplatform / SwiftUI+JavaScriptCore** | Rust / Kotlin / DIY-Swift | Not TypeScript |

---

## 5. What Copper actually needs, and who delivers it

| Requirement | Tauri v2 | Electron 43 | RN-macOS | Deno Desktop |
|---|---|---|---|---|
| Non-activating panel (no focus steal) | 3rd-party `tauri-nspanel` | **First-party** `type: 'panel'` | Hand-written Obj-C | **First-party** `noActivate` |
| Joins all Spaces / over full-screen | via nspanel `CollectionBehavior` | Forced on by `type: 'panel'` | Obj-C | Undocumented |
| Vibrancy / blur | **First-party** `windowEffects` | **First-party** `vibrancy` | Obj-C | **Missing** |
| Borderless + rounded corners | nspanel `.corner_radius()` (CSS is broken) | `frame: false`, `roundedCorners` | Obj-C | `frameless` |
| Dismiss on losing key window | **Yes**, `panel_event!` delegate | **No** (PR #49299 unmerged) | Obj-C | `Tray.attachPanel()` auto-hides |
| Global hotkey | First-party plugin | First-party module | Obj-C | **Menu-scoped only, not system-wide** |
| Menu bar / tray + native NSMenu | First-party (muda) | First-party (NSStatusItem) | Unmaintained community lib | `Deno.Tray` |
| Context menu at cursor | `Menu.popup()` | `Menu.popup()` / `tray.popUpContextMenu()` | Obj-C | Yes |
| Space-key toggle in panel | Webview keydown; panel must be key window (nspanel `can_become_key_window`) | Webview keydown; `type:'panel'` + `focus()` makes key without activating | Native responder chain | Webview keydown |
| Drag reorder | Webview (dnd-kit etc.) | Webview (dnd-kit etc.) | RN gesture + native views | Webview |
| Local storage | store / sql (SQLite) / fs plugins | `node:sqlite` (built in), `safeStorage` | Obj-C or RN async-storage | **No secure storage** |
| Autostart | First-party plugin | `setLoginItemSettings` | Obj-C | Undocumented |
| Bundle size | **~4 MB** | ~280 MB | ~10-20 MB | 40-150 MB |
| Idle RAM | Unmeasured, disputed | **~186 MB measured** | Low | Unmeasured |

Note that Space-key handling and drag reorder are non-issues on any webview stack. They are ordinary DOM work. The genuinely native requirements are the panel semantics, vibrancy, and the global hotkey.

---

## 6. Recommendation

**1. Tauri v2 + tauri-nspanel.** Best fit for the stated priorities. ~4 MB versus ~280 MB matters for an always-resident panel, first-party vibrancy/hotkey/tray/autostart plugins cover almost everything, and nspanel gives you the one thing Electron lacks: key-window delegate events for reliable dismiss-on-blur. The nspanel API surface reads like it was written for this exact app, because it was.

Accept these risks: a git-only dependency with no functional commits since Nov 2025, and `macOSPrivateApi: true` permanently ruling out the App Store.

**Spike this before committing:** [tauri#15471](https://github.com/tauri-apps/tauri/issues/15471). If the ~8x GPU cost of transparency on macOS 26 also applies to nspanel-created windows, the vibrant design is off the table and the recommendation flips to Electron. Build a transparent nspanel window, leave it idle, and measure GPU power. This is a half-day of work that decides the stack.

**2. Electron 43.** The pragmatic, lower-risk choice. Every panel feature except dismiss-on-blur is first-party and has shipped for years; `type: 'panel'` was built specifically for Spotlight-like apps. You pay ~280 MB on disk and ~186 MB RAM for that, which is a real cost for a small utility but not a disqualifying one, and you will find a workaround for the key-window gap (poll `getFocusedWindow`, or hide on global mouse-down outside bounds). Pick this if you want to spend your time on the app rather than on macOS plumbing.

**3. Deno Desktop.** Watch it, do not ship on it yet. It has the cleanest API of anything here, and if `noActivate` + `Tray.attachPanel()` work as documented it would be the best DX by a distance. Blocked today by no vibrancy, no true system-wide hotkey, and six weeks of production history.

**4. react-native-macos.** Only if native rendering fidelity is the actual product requirement. For a notes panel, you would write hundreds of lines of Objective-C to reach parity with a Tauri config file.

**5. Glaze.** Not a stack. If you want Copper built *for* you rather than *by* you, it is a legitimate product at $20/mo, with the caveats that it is Tahoe + Apple Silicon only, has no documented vibrancy, is closed-source, and locks the app inside Raycast's runtime.

---

## Unresolved questions

- **Does tauri#15471's transparency GPU cost apply to nspanel windows?** nspanel sets transparency on NSWindow directly rather than through tao, so it may sidestep the bug. Untested, and it is the deciding factor between recommendation 1 and 2.
- **Electron dismiss-on-blur:** with `become-key`/`resign-key` unmerged, does the `blur` event fire reliably on a non-activating panel? Needs a prototype.
- **Real idle RAM for a Tauri panel on macOS.** No primary source exists and the official benchmark is disputed (#5889). WKWebView has measured worse than Chromium on some workloads, so Tauri's memory win is assumed, not proven. Measure it.
- **Can a Deno Desktop `noActivate` window get vibrancy** via `getNativeWindow()`, and can it register a system-wide hotkey at all today (possibly via an FFI shim to Carbon `RegisterEventHotKey`)? Docs are silent on both.
- **Does Glaze support vibrancy** despite it being absent from the manual? Only answerable by building an app and reading `.glaze-sources`.
- **Is `visibleOnFullScreen` still triggering the Dock-dismissal bug** (electron#26350, open since 2020) on macOS 26?
- Does Copper need selected-text or frontmost-app awareness? That single requirement forces a native addon plus an Accessibility permission prompt on every stack here.
