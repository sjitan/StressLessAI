import Foundation
import Combine
import CoreGraphics

struct FaceTelemetry: Identifiable {
    let ts: TimeInterval                // stream seconds
    var id: TimeInterval { ts }
    let blinkPM: Double
    let mouthOpen: Double
    let jitter: Double
    let frown: Double
    let stress: Double
    let box: CGRect
}

@MainActor
final class TelemetryStore: ObservableObject {
    static let shared = TelemetryStore()
    @Published var latest: FaceTelemetry?
    @Published var samples: [FaceTelemetry] = []

    private var sessionStart: Date?
    private var firstTS: TimeInterval?

    func push(_ m: FaceTelemetry) {
        if sessionStart == nil { sessionStart = Date(); firstTS = m.ts }
        latest = m
        samples.append(m)

        GlowState.shared.stressLevel = m.stress

        Task {
            await DataLayer.shared.insert(telemetry: m)
            if await PredictionEngine.shared.process(latestStress: m.stress) {
                NotificationsManager.shared.notifyRisingStress()
            }
        }
        let cutoff = m.ts - 600
        if let i = samples.firstIndex(where: { $0.ts >= cutoff }), i > 0 { samples.removeFirst(i) }
    }

    func date(for m: FaceTelemetry) -> Date {
        guard let s = sessionStart, let f = firstTS else { return Date() }
        return s.addingTimeInterval(m.ts - f)
    }

    func clear() {
        latest = nil
        samples.removeAll(keepingCapacity: false)
        sessionStart = nil
        firstTS = nil
    }
}
