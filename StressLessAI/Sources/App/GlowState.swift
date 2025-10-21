import Foundation
import SwiftUI

final class GlowState: ObservableObject {
    static let shared = GlowState()
    @Published var stressLevel: Double = 0.0

    var glowColor: Color {
        switch stressLevel {
        case 0..<40:
            return .clear // No glow for low stress
        case 40..<72:
            return .yellow.opacity(0.6)
        default:
            return .red.opacity(0.7)
        }
    }
}
