//
//  HealthKitStore.swift
//  HealthKitGenerator
//
//  Created by Lukas Smetana on 16.05.2025.
//

import Foundation
import HealthKit
import SwiftUI

@MainActor
class HealthKitStore: ObservableObject {
    @Published var log: String = ""
    @Published var isAuthorized: Bool = false

    private let calendar = Calendar.current
    private let healthStore = HealthKitManager.shared

    func requestAccess() {
        let types: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        healthStore.requestAuthorization(types: types) { success, error in
            self.isAuthorized = success
            self.log.append(success ? "✅ Authorized\n" : "❌ Authorization failed: \(error?.localizedDescription ?? "unknown")\n")
        }
    }

    func generateSyntheticData() {
        let types: [HKSampleType] = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let end = Calendar.current.startOfDay(for: Date()).addingTimeInterval(60 * 60 * 24)

        // First: delete old synthetic data
        let group = DispatchGroup()
        for type in types {
            group.enter()
            healthStore.deleteSamples(sampleType: type, startDate: start, endDate: end) { success, error in
                self.log.append(success ? "🗑️ Deleted \(type.identifier)\n" : "❌ Delete failed: \(error?.localizedDescription ?? "unknown")\n")
                group.leave()
            }
        }

        // Then generate new data after deletion completes
        group.notify(queue: .main) {
            self.log.append("🚀 Starting data generation...\n")
            self.generateDataForLast30Days()
        }
    }

    func deleteSyntheticData() {
        let types: [HKSampleType] = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let end = Calendar.current.startOfDay(for: Date()).addingTimeInterval(60 * 60 * 24)

        for type in types {
            HealthKitManager.shared.deleteSamples(sampleType: type, startDate: start, endDate: end) { success, error in
                self.log.append(success ? "🗑️ Deleted \(type.identifier) data\n" : "❌ Failed to delete \(type.identifier): \(error?.localizedDescription ?? "unknown")\n")
            }
        }
    }

    private func generateDataForLast30Days() {
        let now = Date()

        for dayOffset in 0..<30 {
            guard let startOfDay = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            // Steps
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

            // Heart Rate
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

            // HRV
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

            // Sleep
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

    
}
