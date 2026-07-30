import SwiftUI
import ServiceManagement
import Sparkle

@main
struct BronzeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Bronze", image: "MenuBarIcon") {
            Button("Show/Hide Panel") {
                appDelegate.togglePanel()
            }
            .keyboardShortcut(" ", modifiers: .option)

            LaunchAtLoginToggle()

            Divider()

            CheckForUpdatesButton(updater: appDelegate.updaterController.updater)

            Button("Quit Bronze") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

private struct LaunchAtLoginToggle: View {
    @State private var enabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Toggle("Launch at Login", isOn: $enabled)
            .onChange(of: enabled) { _, newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    enabled = SMAppService.mainApp.status == .enabled
                }
            }
    }
}

private struct CheckForUpdatesButton: View {
    let updater: SPUUpdater
    @State private var canCheck = true

    var body: some View {
        Button("Check for Updates…") {
            updater.checkForUpdates()
        }
        .disabled(!canCheck)
        .onReceive(updater.publisher(for: \.canCheckForUpdates)) { canCheck = $0 }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    private var panelController: PanelController?
    private var captureController: CaptureController?
    private var panelHotkey: GlobalHotkey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = PanelController(model: model)
        panelController = controller
        controller.show()
        let tracker = PasteboardTracker()
        model.pasteboardTracker = tracker
        captureController = CaptureController(model: model, tracker: tracker)
        panelHotkey = GlobalHotkey { [weak self] in
            Task { @MainActor in self?.togglePanel() }
        }
    }

    func togglePanel() {
        panelController?.toggle()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.saveNow()
    }
}
