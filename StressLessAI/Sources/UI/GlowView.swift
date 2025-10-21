import SwiftUI

struct GlowView: View {
    @ObservedObject var state = GlowState.shared

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .border(state.glowColor, width: 10)
            .edgesIgnoringSafeArea(.all)
    }
}

class GlowWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.ignoresMouseEvents = true
        self.contentView = NSHostingView(rootView: GlowView())
    }
}
