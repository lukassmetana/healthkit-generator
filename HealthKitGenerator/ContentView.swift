import SwiftUI

struct ContentView: View {
    @StateObject private var store = HealthKitStore()
    @State private var showLog = false

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                ForEach(store.availableMetrics.indices, id: \.self) { index in
                    Toggle(store.availableMetrics[index].name, isOn: $store.availableMetrics[index].isSelected)
                }
                .padding(.horizontal)

                DatePicker("Start Date", selection: $store.startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                DatePicker("End Date", selection: $store.endDate, in: store.startDate..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    VStack(alignment: .center, spacing: 4) {
                        Button("Generate Data") {
                            showLog = true
                            store.generateSyntheticData()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!store.isAuthorized)

                        Text("Generate data for selected metrics.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .center, spacing: 4) {
                        Button("Delete Data") {
                            store.deleteSyntheticData()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(!store.isAuthorized)

                        Text("Delete all synthetic data generated from this app.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .center, spacing: 4) {
                        Button("Clear Log") {
                            store.log = ""
                        }
                        .buttonStyle(.bordered)
                        .tint(.gray)

                        Text("Clear the current log output.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider().padding(.top)
        }
        .padding(.top, 16)
        .onAppear {
            store.requestAccess()
        }
        .fullScreenCover(isPresented: $showLog) {
            LogView(store: store)
        }
    }
}
