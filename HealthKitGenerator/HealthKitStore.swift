import Foundation
import HealthKit
import SwiftUI

struct MetricDefinition: Identifiable {
    let id = UUID()
    let name: String
    let typeIdentifier: HKQuantityTypeIdentifier
    let unit: HKUnit
    let valueRange: ClosedRange<Double>
    let interval: TimeInterval
    let deviceName: String
    var isSelected: Bool
}

@MainActor
class HealthKitStore: ObservableObject {
    @Published var log: String = ""
    @Published var isAuthorized: Bool = false

    private let calendar = Calendar.current
    private let healthStore = HealthKitManager.shared

    @Published var availableMetrics: [MetricDefinition] = [
        MetricDefinition(name: "Steps", typeIdentifier: .stepCount, unit: .count(), valueRange: 5...40, interval: 60, deviceName: "Apple Watch", isSelected: true),
        MetricDefinition(name: "Heart Rate", typeIdentifier: .heartRate, unit: HKUnit(from: "count/min"), valueRange: 60...100, interval: 300, deviceName: "Apple Watch", isSelected: true),
        MetricDefinition(name: "Resting HR", typeIdentifier: .restingHeartRate, unit: HKUnit(from: "count/min"), valueRange: 50...90, interval: 600, deviceName: "Oura Ring", isSelected: true),
        MetricDefinition(name: "HRV", typeIdentifier: .heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), valueRange: 20...100, interval: 3600, deviceName: "Oura Ring", isSelected: true),
        MetricDefinition(name: "Respiratory Rate", typeIdentifier: .respiratoryRate, unit: HKUnit(from: "count/min"), valueRange: 12...20, interval: 600, deviceName: "Garmin", isSelected: true),
        MetricDefinition(name: "Body Temp", typeIdentifier: .bodyTemperature, unit: .degreeCelsius(), valueRange: 36.0...37.50, interval: 3600, deviceName: "Oura Ring", isSelected: true),
        MetricDefinition(name: "Basal Energy", typeIdentifier: .basalEnergyBurned, unit: .kilocalorie(), valueRange: 50...75, interval: 3600, deviceName: "Garmin", isSelected: true),
        MetricDefinition(name: "Active Energy", typeIdentifier: .activeEnergyBurned, unit: .kilocalorie(), valueRange: 5...15, interval: 1800, deviceName: "Apple Watch", isSelected: true)
    ]

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

    func endOfDay(for date: Date) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components)!
    }

    func generateSyntheticData() {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

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
        let group = DispatchGroup()

        for dayOffset in 0..<30 {
            guard let startOfDay = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            for metric in availableMetrics where metric.isSelected {
                group.enter()
                healthStore.saveRandomQuantitySamples(
                    typeIdentifier: metric.typeIdentifier,
                    unit: metric.unit,
                    valueRange: metric.valueRange,
                    startDate: startOfDay,
                    endDate: endOfDay,
                    interval: metric.interval,
                    deviceName: metric.deviceName,
                    completion: { success, error in
                        self.log.append(
                            success
                            ? "✅ \(metric.name) for \(startOfDay.formatted())\n"
                            : "❌ \(metric.name) error: \(error?.localizedDescription ?? "unknown")\n"
                        )
                        group.leave()
                    }
                )
            }

            // Sleep data
            if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                let sleepStart = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: startOfDay)!
                let sleepEnd = calendar.date(byAdding: .hour, value: 8, to: sleepStart)!
                let sample = HKCategorySample(
                    type: sleepType,
                    value: HKCategoryValueSleepAnalysis.asleep.rawValue,
                    start: sleepStart,
                    end: sleepEnd,
                    metadata: ["DeviceName": "Oura Ring"]
                )

                group.enter()
                healthStore.save(sample: sample) { success, error in
                    self.log.append(
                        success
                        ? "✅ Sleep for \(startOfDay.formatted())\n"
                        : "❌ Sleep error: \(error?.localizedDescription ?? "unknown")\n"
                    )
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            self.log.append("🏁 Finished generating data for all selected metrics.\n")
        }
    }

    func deleteSyntheticData() {
        let startDelete = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let endDelete = calendar.date(byAdding: .day, value: 1, to: Date())!

        for type in sampleTypes {
            healthStore.deleteSamples(sampleType: type, startDate: startDelete, endDate: endDelete) { success, error in
                self.log.append(success ? "🗑️ Deleted \(type.identifier) data\n" : "❌ Failed to delete \(type.identifier): \(error?.localizedDescription ?? "unknown")\n")
            }
        }
    }
}
