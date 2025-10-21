import Foundation

final class StressEngine {
    static let shared = StressEngine()

    // --- Tunable Parameters ---
    private struct Weights {
        let mouthOpen: Double = 0.35
        let blinkRate: Double = 0.15 // Reduced sensitivity
        let jitter: Double = 0.20
        let frown: Double = 0.30     // Increased sensitivity
    }
    private let weights = Weights()
    // --------------------------

    private var aboveSince: TimeInterval?
    private let threshold = 72.0
    private let sustain   = 90.0
    private var lastNotifyAt: TimeInterval = 0

    func score(blinkPM: Double, mouth: Double, jitter: Double, frown: Double) -> Double {
        let mouthScore = mouth * weights.mouthOpen
        let blinkScore = (min(blinkPM, 60) / 60.0 * 100) * weights.blinkRate
        let jitterScore = jitter * weights.jitter
        let frownScore = frown * weights.frown

        let totalScore = min(max(mouthScore + blinkScore + jitterScore + frownScore, 0), 100)

        Logger.log(String(format: "Stress Score Components -> Mouth: %.1f, Blink: %.1f, Jitter: %.1f, Frown: %.1f. Final Score: %.1f", mouthScore, blinkScore, jitterScore, frownScore, totalScore))

        return totalScore
    }

    func handle(stress: Double, ts: TimeInterval) {
        if stress >= threshold {
            if aboveSince == nil {
                aboveSince = ts
                Logger.log("Stress threshold of \(threshold) exceeded. Starting timer.")
            }
            if let t0 = aboveSince, ts - t0 >= sustain {
                Logger.log("Stress has been sustained above threshold for \(sustain) seconds.")
                if ts - lastNotifyAt > 300 {
                    Logger.log("Triggering 'Take a Break' notification.")
                    lastNotifyAt = ts
                    NotificationsManager.shared.notifyTakeABreak()
                    aboveSince = nil // Reset after notification
                }
            }
        } else {
            if aboveSince != nil {
                Logger.log("Stress level dropped below threshold. Resetting timer.")
                aboveSince = nil
            }
        }
    }
}
