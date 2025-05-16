import SwiftUI

struct ContentView: View {
    @StateObject private var store = HealthKitStore()

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                ForEach(store.availableMetrics.indices, id: \.self) { index in
                    Toggle(store.availableMetrics[index].name, isOn: $store.availableMetrics[index].isSelected)
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    VStack(alignment: .center, spacing: 4) {
                        Button("Generate Data") {
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

            // Log display
            ScrollViewReader { proxy in
                ScrollView {
                    Text(store.log)
                        .font(.system(.footnote, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("logBottom")
                }
                .frame(maxHeight: .infinity)
                .onChange(of: store.log) { _ in
                    withAnimation {
                        proxy.scrollTo("logBottom", anchor: .bottom)
                    }
                }
            }
        }
        .padding(.top, 16)
        .onAppear {
            store.requestAccess()
        }
    }
}
