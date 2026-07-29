import SwiftUI
import ServiceManagement

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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
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
