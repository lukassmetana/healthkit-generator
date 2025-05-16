import SwiftUI

struct ContentView: View {
    @StateObject private var store = HealthKitStore()

    var body: some View {
        VStack(spacing: 20) {
            ForEach(store.availableMetrics.indices, id: \.self) { index in
                Toggle(store.availableMetrics[index].name, isOn: $store.availableMetrics[index].isSelected)
            }
            .padding(.horizontal)
            
            Button("Generate Selected Data") {
                store.generateSyntheticData()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

            Button("Delete All Data") {
                store.deleteSyntheticData()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(12)

            ScrollView {
                Text(store.log)
                    .font(.system(size: 12, design: .monospaced))
                    .padding()
            }
        }
        .padding()
        .onAppear {
            store.requestAccess()
        }
    }
}
