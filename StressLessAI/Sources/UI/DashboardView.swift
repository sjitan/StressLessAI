import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var store = TelemetryStore.shared
    @State private var scope: Scope = .session

    enum Scope: String, CaseIterable, Identifiable { case session, daily; var id: String { rawValue } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("", selection: $scope) {
                ForEach(Scope.allCases) { Text($0.rawValue.capitalized).tag($0) }
            }
            .pickerStyle(.segmented)

            Chart(scopeData, id: \.ts) { m in
                LineMark(
                    x: .value("Time", store.date(for: m)),
                    y: .value("Stress", m.stress)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(.init(lineWidth: 2))
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                    AxisTick()
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.minute().second())
                }
            }
            .chartYAxis {
                AxisMarks(values: [0,20,40,60,72,80,100])
            }
            .chartOverlay { proxy in
                VStack(spacing: 0) {
                    ZStack {
                        Rectangle().fill(Color.red.opacity(0.2))
                        Text("High Stress (72–100)").font(.caption).foregroundColor(.secondary)
                    }
                    .frame(height: proxy.plotAreaSize.height * 0.28)

                    ZStack {
                        Rectangle().fill(Color.yellow.opacity(0.2))
                        Text("Medium Stress (40–72)").font(.caption).foregroundColor(.secondary)
                    }
                    .frame(height: proxy.plotAreaSize.height * 0.32)

                    ZStack {
                        Rectangle().fill(Color.green.opacity(0.2))
                        Text("Low Stress (0–40)").font(.caption).foregroundColor(.secondary)
                    }
                    .frame(height: proxy.plotAreaSize.height * 0.40)
                }
                .frame(width: proxy.plotAreaSize.width, height: proxy.plotAreaSize.height)
            }
            .chartXAxisLabel("Time")
            .chartYAxisLabel("Stress (0–100)")

            Spacer()
        }
        .padding(16)
    }

    private var scopeData: [FaceTelemetry] {
        guard let last = store.samples.last?.ts else { return [] }
        switch scope {
        case .session: return store.samples.suffix(180) // last few minutes
        case .daily:   return store.samples.filter { $0.ts >= last - 24*3600 }
        }
    }
}
