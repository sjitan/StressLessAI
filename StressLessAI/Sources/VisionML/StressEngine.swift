import Foundation

final class StressEngine {
    static let shared = StressEngine()
    private var aboveSince: TimeInterval?
    private let threshold = 72.0
    private let sustain   = 90.0
    private var lastNotifyAt: TimeInterval = 0

    func score(blinkPM: Double, mouth: Double, jitter: Double) -> Double {
        // simple weighted sum with clamp
        let mouthWeight = 0.45
        let blinkWeight = 0.25
        let jitterWeight = 0.30

        let mouthScore = mouth * mouthWeight
        let blinkScore = (min(blinkPM, 60) / 60.0 * 100) * blinkWeight
        let jitterScore = jitter * jitterWeight

        let totalScore = min(max(mouthScore + blinkScore + jitterScore, 0), 100)

        Logger.log(String(format: "Stress score components -> Mouth: %.2f, Blink: %.2f, Jitter: %.2f. Final Score: %.2f", mouthScore, blinkScore, jitterScore, totalScore))

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
