import SwiftUI
import Charts

struct ReportView: View {
    @State private var sessions: [Session] = []
    @State private var selectedSessionId: Int64?
    @State private var selectedSessionTelemetry: [Telemetry] = []
    @State private var selectedSessionRecommendation: String?

    var body: some View {
        NavigationSplitView {
            List(sessions, id: \.id, selection: $selectedSessionId) { session in
                VStack(alignment: .leading) {
                    Text("Session \(session.id)")
                        .font(.headline)
                    Text(session.startTime, style: .date)
                    Text(session.startTime, style: .time)
                }
            }
            .navigationTitle("Past Sessions")
            .onAppear(perform: loadSessions)
        } detail: {
            if let sessionId = selectedSessionId {
                VStack {
                    Text("Report for Session \(sessionId)")
                        .font(.title)
                        .padding()

                    if selectedSessionTelemetry.isEmpty {
                        Text("No telemetry data for this session.")
                    } else {
                        Chart(selectedSessionTelemetry, id: \.timestamp) { item in
                            LineMark(
                                x: .value("Time", item.timestamp),
                                y: .value("Stress", item.stress)
                            )
                            .interpolationMethod(.catmullRom)
                        }
                        .chartYScale(domain: 0...100)
                        .padding()

                        if let recommendation = selectedSessionRecommendation {
                            Text("Recommendation:")
                                .font(.headline)
                                .padding(.top)
                            Text(recommendation)
                                .padding()
                        }
                    }
                }
                .onChange(of: selectedSessionId, perform: loadTelemetry)
            } else {
                Text("Select a session to view the report.")
            }
        }
    }

    private func loadSessions() {
        Task {
            self.sessions = await DataLayer.shared.fetchAllSessions()
        }
    }

    private func loadTelemetry(for sessionId: Int64?) {
        guard let sessionId = sessionId else { return }
        Task {
            self.selectedSessionTelemetry = await DataLayer.shared.fetchTelemetry(for: sessionId)
            self.selectedSessionRecommendation = sessions.first { $0.id == sessionId }?.recommendation
        }
    }
}
