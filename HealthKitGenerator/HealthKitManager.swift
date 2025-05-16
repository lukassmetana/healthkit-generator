import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    // Request permission to write and read specific types
    func requestAuthorization(types: Set<HKSampleType>, completion: @escaping (Bool, Error?) -> Void) {
        healthStore.requestAuthorization(toShare: types, read: types) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    func save(sample: HKCategorySample, completion: ((Bool, Error?) -> Void)? = nil) {
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion?(success, error)
            }
        }
    }

    // Save random quantity samples
    func saveRandomQuantitySamples(
        typeIdentifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        valueRange: ClosedRange<Int>,
        startDate: Date,
        endDate: Date,
        interval: TimeInterval,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            completion?(false, NSError(domain: "HealthKitManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Quantity type not available"
            ]))
            return
        }

        var samples: [HKQuantitySample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let value = Int.random(in: valueRange)
            let quantity = HKQuantity(unit: unit, doubleValue: Double(value))
            let sampleEnd = currentDate.addingTimeInterval(interval)

            let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: currentDate, end: sampleEnd)
            samples.append(sample)

            currentDate = sampleEnd
        }

        healthStore.save(samples) { success, error in
            DispatchQueue.main.async {
                completion?(success, error)
            }
        }
    }

    // Delete samples by type and time range
    func deleteSamples(
        sampleType: HKSampleType,
        startDate: Date,
        endDate: Date,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])

        healthStore.deleteObjects(of: sampleType, predicate: predicate) { success, _, error in
            DispatchQueue.main.async {
                completion?(success, error)
            }
        }
    }
}
