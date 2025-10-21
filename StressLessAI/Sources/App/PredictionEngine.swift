import Foundation

actor PredictionEngine {
    static let shared = PredictionEngine()

    private init() {}

    func analyze(telemetry: [FaceTelemetry]) -> Bool {
        guard telemetry.count >= 10 else { return false }

        let recentSamples = telemetry.prefix(10)
        let stressLevels = recentSamples.map { $0.stress }

        // Simple linear regression to detect trend
        let xs = Array(0..<stressLevels.count).map { Double($0) }
        let ys = stressLevels
        let sum_x = xs.reduce(0, +)
        let sum_y = ys.reduce(0, +)
        let sum_xy = zip(xs, ys).map(*).reduce(0, +)
        let sum_x2 = xs.map { $0 * $0 }.reduce(0, +)
        let n = Double(xs.count)

        let slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)

        // If the slope is positive and steep enough, trigger an intervention
        return slope > 2.5
    }

    func generateRecommendation(telemetry: [FaceTelemetry]) -> String {
        guard !telemetry.isEmpty else { return "No session data available." }

        let averageStress = telemetry.map { $0.stress }.reduce(0, +) / Double(telemetry.count)

        if averageStress > 72 {
            return "Your stress levels were consistently high. Consider taking a break and practicing some deep breathing exercises."
        } else if averageStress > 40 {
            return "Your stress levels were moderate. It might be helpful to identify any specific triggers from your session."
        } else {
            return "Your stress levels were low. Great job maintaining a calm state!"
        }
    }
}
