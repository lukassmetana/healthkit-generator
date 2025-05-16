import Foundation
import HealthKit
import SwiftUI

@MainActor
class HealthKitStore: ObservableObject {
    @Published var log: String = ""
    @Published var isAuthorized: Bool = false

    private let calendar = Calendar.current
    private let healthStore = HealthKitManager.shared

    // Expanded set of sample types for both authorization and data generation
    private let sampleTypes: [HKSampleType] = [
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
        HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]

    func requestAccess() {
        let types = Set(sampleTypes)
        healthStore.requestAuthorization(types: types) { success, error in
            self.isAuthorized = success
            self.log.append(success ? "✅ Authorized\n" : "❌ Authorization failed: \(error?.localizedDescription ?? "unknown")\n")
        }
    }

    func generateSyntheticData() {
        let start = calendar.date(byAdding: .day, value: -30, to: Date())!
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!

        // Delete existing data before generating new
        let group = DispatchGroup()
        for type in sampleTypes {
            group.enter()
            healthStore.deleteSamples(sampleType: type, startDate: start, endDate: end) { success, error in
                self.log.append(success ? "🗑️ Deleted \(type.identifier)\n" : "❌ Delete failed: \(error?.localizedDescription ?? "unknown")\n")
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.log.append("🚀 Starting data generation...\n")
            self.generateDataForLast30Days()
        }
    }

    private func generateDataForLast30Days() {
        let now = Date()

        for dayOffset in 0..<30 {
            guard let startOfDay = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            // heartRateVariabilitySDNN (20-100 ms every hour)
            healthStore.saveRandomQuantitySamples(
                typeIdentifier: .heartRateVariabilitySDNN,
                unit: .secondUnit(with: .milli),
                valueRange: 20...100,
                startDate: startOfDay,
                endDate: endOfDay,
                interval: 3600
            ) { success, error in
                self.log.append(success ? "✅ HRV for \(startOfDay.formatted())\n" : "❌ HRV error: \(error?.localizedDescription ?? "unknown")\n")
            }

            // restingHeartRate (50-90 bpm every 10 minutes)
            healthStore.saveRandomQuantitySamples(
                typeIdentifier: .restingHeartRate,
                unit: HKUnit(from: "count/min"),
                valueRange: 50...90,
                startDate: startOfDay,
                endDate: endOfDay,
                interval: 600
            ) { success, error in
                self.log.append(success ? "✅ Resting HR for \(startOfDay.formatted())\n" : "❌ Resting HR error: \(error?.localizedDescription ?? "unknown")\n")
            }

            // respiratoryRate (12-20 breaths/min every 10 minutes)
            healthStore.saveRandomQuantitySamples(
                typeIdentifier: .respiratoryRate,
                unit: HKUnit(from: "count/min"),
                valueRange: 12...20,
                startDate: startOfDay,
                endDate: endOfDay,
                interval: 600
            ) { success, error in
                self.log.append(success ? "✅ Respiratory Rate for \(startOfDay.formatted())\n" : "❌ Respiratory Rate error: \(error?.localizedDescription ?? "unknown")\n")
            }

            // bodyTemperature (36.0-37.5 °C every hour)
            healthStore.saveRandomQuantitySamples(
                typeIdentifier: .bodyTemperature,
                unit: HKUnit.degreeCelsius(),
                valueRange: 3600...3750, // values in milli-Celsius, so divide by 100
                startDate: startOfDay,
                endDate: endOfDay,
                interval: 3600
            ) { success, error in
                self.log.append(success ? "✅ Body Temp for \(startOfDay.formatted())\n" : "❌ Body Temp error: \(error?.localizedDescription ?? "unknown")\n")
            }

            // stepCount (5-40 steps per minute)
            healthStore.saveRandomQuantitySamples(
                typeIdentifier: .stepCount,
                unit: .count(),
                valueRange: 5...40,
                startDate: startOfDay,
                endDate: endOfDay,
                interval: 60
            ) { success, error in
                self.log.append(success ? "✅ Steps for \(startOfDay.formatted())\n" : "❌ Steps error: \(error?.localizedDescription ?? "unknown")\n")
            }

            // heartRate (60-100 bpm every 5 minutes)
            healthStore.saveRandomQuantitySamples(
                typeIdentifier: .heartRate,
                unit: HKUnit(from: "count/min"),
                valueRange: 60...100,
                startDate: startOfDay,
                endDate: endOfDay,
                interval: 300
            ) { success, error in
                self.log.append(success ? "✅ HR for \(startOfDay.formatted())\n" : "❌ HR error: \(error?.localizedDescription ?? "unknown")\n")
            }

            // basalEnergyBurned (50-75 kcal hourly)
            healthStore.saveRandomQuantitySamples(
                typeIdentifier: .basalEnergyBurned,
                unit: HKUnit.kilocalorie(),
                valueRange: 50...75,
                startDate: startOfDay,
                endDate: endOfDay,
                interval: 3600
            ) { success, error in
                self.log.append(success ? "✅ Basal Energy Burned for \(startOfDay.formatted())\n" : "❌ Basal Energy error: \(error?.localizedDescription ?? "unknown")\n")
            }

            // activeEnergyBurned (5-15 kcal every 30 minutes)
            healthStore.saveRandomQuantitySamples(
                typeIdentifier: .activeEnergyBurned,
                unit: HKUnit.kilocalorie(),
                valueRange: 5...15,
                startDate: startOfDay,
                endDate: endOfDay,
                interval: 1800
            ) { success, error in
                self.log.append(success ? "✅ Active Energy Burned for \(startOfDay.formatted())\n" : "❌ Active Energy error: \(error?.localizedDescription ?? "unknown")\n")
            }

            // appleMoveTime (1-5 minutes every 15 minutes)
            healthStore.saveRandomQuantitySamples(
                typeIdentifier: .appleMoveTime,
                unit: HKUnit.minute(),
                valueRange: 1...5,
                startDate: startOfDay,
                endDate: endOfDay,
                interval: 900
            ) { success, error in
                self.log.append(success ? "✅ Apple Move Time for \(startOfDay.formatted())\n" : "❌ Apple Move Time error: \(error?.localizedDescription ?? "unknown")\n")
            }

            // appleExerciseTime (1-4 minutes every 15 minutes)
            healthStore.saveRandomQuantitySamples(
                typeIdentifier: .appleExerciseTime,
                unit: HKUnit.minute(),
                valueRange: 1...4,
                startDate: startOfDay,
                endDate: endOfDay,
                interval: 900
            ) { success, error in
                self.log.append(success ? "✅ Apple Exercise Time for \(startOfDay.formatted())\n" : "❌ Apple Exercise Time error: \(error?.localizedDescription ?? "unknown")\n")
            }

            // Sleep (one sample per day from 11pm to 7am)
            if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                let sleepStart = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: startOfDay)!
                let sleepEnd = calendar.date(byAdding: .hour, value: 8, to: sleepStart)!

                let sample = HKCategorySample(
                    type: sleepType,
                    value: HKCategoryValueSleepAnalysis.asleep.rawValue,
                    start: sleepStart,
                    end: sleepEnd
                )

                healthStore.save(sample: sample) { success, error in
                    self.log.append(success ? "✅ Sleep for \(startOfDay.formatted())\n" : "❌ Sleep error: \(error?.localizedDescription ?? "unknown")\n")
                }
            }
        }
    }

    func deleteSyntheticData() {
        let start = calendar.date(byAdding: .day, value: -30, to: Date())!
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!

        for type in sampleTypes {
            healthStore.deleteSamples(sampleType: type, startDate: start, endDate: end) { success, error in
                self.log.append(success ? "🗑️ Deleted \(type.identifier) data\n" : "❌ Failed to delete \(type.identifier): \(error?.localizedDescription ?? "unknown")\n")
            }
        }
    }
}
