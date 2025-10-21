import SwiftUI
import Charts

struct ReportView: View {
    @State private var telemetryData: [FaceTelemetry] = []

    var body: some View {
        VStack {
            Text("Stress Report")
                .font(.title)
                .padding()

            if telemetryData.isEmpty {
                Text("No data available to generate a report.")
                    .padding()
                Spacer()
            } else {
                Chart(telemetryData, id: \.ts) { m in
                    LineMark(
                        x: .value("Time", Date(timeIntervalSince1970: m.ts)),
                        y: .value("Stress", m.stress)
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...100)
                .padding()
            }
        }
        .onAppear(perform: loadData)
    }

    private func loadData() {
        Task {
            // In a real app, you might fetch this from a database
            // For now, we'll just use the in-memory samples for demonstration
            self.telemetryData = await TelemetryStore.shared.samples
        }
    }
}
