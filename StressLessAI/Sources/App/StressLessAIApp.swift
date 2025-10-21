import SwiftUI
import AppKit
import os.log

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
        Logger.log("Application finished launching.")

        // Ensure the app can draw over other apps
        NSApp.setActivationPolicy(.accessory)
        Logger.log("Activation policy set to .accessory.")

        NotificationsManager.shared.requestAuth()
        Logger.log("Requested notification authorization.")

        CameraPermission.request { granted in
            DispatchQueue.main.async {
                if granted {
                    Logger.log("Camera permission granted.")
                    CameraManager.shared.start()
                    Logger.log("Camera manager started.")
                    WindowLauncher.open(.telemetry)
                    Logger.log("Telemetry window opened.")
                } else {
                    Logger.log("Camera permission denied.", level: .error)
                    // Optionally, show an alert to the user
                    let alert = NSAlert()
                    alert.messageText = "Camera Permission Required"
                    alert.informativeText = "StressLessAI needs access to your camera to function. Please grant permission in System Settings > Privacy & Security > Camera."
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    NSApp.terminate(nil)
                }
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
