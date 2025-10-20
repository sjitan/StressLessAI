import SwiftUI
final class AppState: ObservableObject {
    static let shared = AppState()
    @Published var menuBarEmoji = "🫨"
}
