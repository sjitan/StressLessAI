import Foundation

actor PredictionEngine {
    static let shared = PredictionEngine()

    // EMA parameters
    private let shortAlpha = 2.0 / (5.0 + 1.0) // 5-sample EMA
    private let longAlpha = 2.0 / (20.0 + 1.0) // 20-sample EMA

    private var shortTermEMA: Double = 0.0
    private var longTermEMA: Double = 0.0
    private var samplesProcessed = 0
    private var lastNotificationTimestamp: Date?

    private init() {}

    func process(latestStress: Double) -> Bool {
        if samplesProcessed == 0 {
            shortTermEMA = latestStress
            longTermEMA = latestStress
        } else {
            shortTermEMA = shortAlpha * latestStress + (1 - shortAlpha) * shortTermEMA
            longTermEMA = longAlpha * latestStress + (1 - longAlpha) * longTermEMA
        }
        samplesProcessed += 1

        // To prevent notification spam, only trigger once every 5 minutes at most
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        if let lastNotif = lastNotificationTimestamp, lastNotif > fiveMinutesAgo {
            return false
        }

        // A significant rising trend is detected when the short-term average
        // crosses above the long-term average by a notable margin.
        if shortTermEMA > longTermEMA * 1.5 && samplesProcessed > 20 {
            Logger.log("Rising stress trend detected. Short EMA: \(shortTermEMA), Long EMA: \(longTermEMA)")
            lastNotificationTimestamp = Date()
            return true
        }

        return false
    }

    func generateRecommendation(telemetry: [FaceTelemetry]) -> String {
        guard !telemetry.isEmpty else {
            return "No session data was recorded. Unable to generate a recommendation."
        }

        let averageStress = telemetry.map { $0.stress }.reduce(0, +) / Double(telemetry.count)
        let peakStress = telemetry.map { $0.stress }.max() ?? 0

        var recommendation = "Session Report:\n"
        recommendation += String(format: "Average Stress: %.1f / 100\n", averageStress)
        recommendation += String(format: "Peak Stress: %.1f / 100\n\n", peakStress)

        if averageStress > 72 {
            recommendation += "Your stress levels were consistently high during this session. This may indicate a period of significant pressure. Consider taking a longer break to decompress. Techniques like mindfulness or a short walk can be very effective."
        } else if averageStress > 40 {
            recommendation += "Your stress levels were in the moderate range. It could be helpful to reflect on the moments that led to the peak stress level. Identifying these triggers is the first step toward managing them."
        } else {
            recommendation += "Your stress levels were generally low. This is a great sign of a well-managed state. Keep up the excellent work in maintaining your calm and focus."
        }

        return recommendation
    }
}
