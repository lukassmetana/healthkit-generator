import SwiftUI

struct ContentView: View {
    @State private var isAuthorized = false
    @State private var log = ""

    var body: some View {
        VStack(spacing: 20) {
            Button("Generate Data") {
                generateAllSources()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

            Button("Delete Data") {
                deleteStepData()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(12)

            ScrollView {
                Text(log)
                    .font(.system(size: 12, design: .monospaced))
                    .padding()
            }
        }
        .padding()
        .onAppear {
            HealthKitManager.shared.requestAuthorization { success, error in
                if success {
                    isAuthorized = true
                    log.append("✅ Authorized\n")
                } else {
                    log.append("❌ Authorization failed: \(error?.localizedDescription ?? "unknown error")\n")
                }
            }
        }
    }

    func deleteStepData() {
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let end = Date()

        HealthKitManager.shared.deleteSteps(startDate: start, endDate: end) { success, error in
            if success {
                log.append("🗑️ Deleted step data from last 24h\n")
            } else {
                log.append("❌ Delete failed: \(error?.localizedDescription ?? "unknown error")\n")
            }
        }
    }

    func generateAllSources() {
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let end = Date()

        let sources: [(name: String, interval: TimeInterval)] = [
            ("Oura", 10),
            ("Apple Watch", 60),
            ("iPhone", 300),
            ("Whoop", 15)
        ]

        for source in sources {
            HealthKitManager.shared.saveRandomSteps(
                startDate: start,
                endDate: end,
                interval: source.interval
            ) { success, error in
                if success {
                    log.append("✅ \(source.name) data written with interval \(Int(source.interval))s\n")
                } else {
                    log.append("❌ Failed to write \(source.name): \(error?.localizedDescription ?? "unknown error")\n")
                }
            }
        }
    }
}
