import Foundation

final class StressEngine {
    static let shared = StressEngine()
    private var aboveSince: TimeInterval?
    private let threshold = 72.0
    private let sustain   = 90.0
    private var lastNotifyAt: TimeInterval = 0

    func score(blinkPM: Double, mouth: Double, jitter: Double) -> Double {
        // simple weighted sum with clamp
        let s = min(max( (mouth*0.45) + (min(blinkPM,60)/60.0*100*0.25) + (jitter*0.30), 0), 100)
        return s
    }

    func handle(stress: Double, ts: TimeInterval) {
        if stress >= threshold {
            if aboveSince == nil { aboveSince = ts }
            if let t0 = aboveSince, ts - t0 >= sustain, ts - lastNotifyAt > 300 {
                lastNotifyAt = ts
                NotificationsManager.shared.notifyTakeABreak()
                aboveSince = nil
            }
        } else {
            aboveSince = nil
        }
    }
}
