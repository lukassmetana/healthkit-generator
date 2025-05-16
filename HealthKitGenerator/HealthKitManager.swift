//
//  HealthKitManager.swift
//  HealthKitGenerator
//
//  Created by Lukas Smetana on 15.05.2025.
//

import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    // Types of data we want to write
    private var writableTypes: Set<HKSampleType> {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return []
        }
        return [stepType]
    }

    // Request permission to write data
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        healthStore.requestAuthorization(toShare: writableTypes, read: nil) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    // Save random step data for a specific date
    func saveRandomSteps(
        startDate: Date,
        endDate: Date,
        interval: TimeInterval,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion?(false, NSError(
                domain: "HealthKitManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Step Count Type not available"]
            ))
            return
        }

        var samples: [HKQuantitySample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let steps = Int.random(in: 5...40) // simulate light-to-heavy movement
            let quantity = HKQuantity(
                unit: HKUnit.count(),
                doubleValue: Double(steps)
            )
            let sampleEnd = currentDate.addingTimeInterval(interval)

            let sample = HKQuantitySample(
                type: stepType,
                quantity: quantity,
                start: currentDate,
                end: sampleEnd
            )
            samples.append(sample)
            currentDate = sampleEnd
        }

        healthStore.save(samples) { success, error in
            DispatchQueue.main.async {
                completion?(success, error)
            }
        }
    }

    func deleteSteps(startDate: Date, endDate: Date, completion: ((Bool, Error?) -> Void)? = nil) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion?(false, NSError(domain: "HealthKitManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Step Count Type not available"]))
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])

        healthStore.deleteObjects(of: stepType, predicate: predicate) { success, _, error in
            DispatchQueue.main.async {
                completion?(success, error)
            }
        }
    }
}

