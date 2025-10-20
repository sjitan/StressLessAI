import SwiftUI
import AppKit

@main
struct StressLessAIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        MenuBarExtra { MenuContent() } label: { Text(AppState.shared.menuBarEmoji) }
            .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ note: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotificationsManager.shared.requestAuth()
        CameraPermission.request { _ in
            DispatchQueue.main.async {
                CameraManager.shared.start()
                WindowLauncher.open(.telemetry)
            }
        }
    }
}

struct MenuContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Open Telemetry (⌘T)") { WindowLauncher.open(.telemetry) }.keyboardShortcut("t")
            Button("View Dashboard (⌘D)") { WindowLauncher.open(.dashboard) }.keyboardShortcut("d")
            Divider()
            Button("Quit (⌘Q)") { NSApp.terminate(nil) }.keyboardShortcut("q")
        }
        .padding(8)
        .frame(width: 240)
    }
}
