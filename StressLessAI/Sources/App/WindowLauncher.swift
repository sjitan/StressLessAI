import AppKit
import SwiftUI

enum WindowKind { case telemetry, dashboard }

enum WindowLauncher {
    static func open(_ kind: WindowKind) {
        let view: any View = {
            switch kind {
            case .telemetry: return TelemetryView()
            case .dashboard: return DashboardView()
            }
        }()
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 960, height: 600),
                         styleMask: [.titled,.closable,.miniaturizable,.resizable],
                         backing: .buffered, defer: false)
        w.center(); w.title = "StressLessAI"
        w.contentView = NSHostingView(rootView: AnyView(view))
        w.makeKeyAndOrderFront(nil)
    }
}
