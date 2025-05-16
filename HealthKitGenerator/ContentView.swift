import SwiftUI

struct ContentView: View {
    @StateObject private var store = HealthKitStore()

    var body: some View {
        VStack(spacing: 20) {
            Button("Generate Data") {
                store.generateSyntheticData()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

            Button("Delete Data") {
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
