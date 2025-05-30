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

    func endOfDay(for date: Date) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components)!
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
        valueRange: ClosedRange<Double>,
        startDate: Date,
        endDate: Date,
        interval: TimeInterval,
        deviceName: String? = nil,
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
            let value = Double.random(in: valueRange)
            let quantity = HKQuantity(unit: unit, doubleValue: Double(value))

            // Clamp sample end time to not exceed endDate
            let sampleEnd = min(currentDate.addingTimeInterval(interval), endDate)

            let device: HKDevice? = deviceName.map {
                HKDevice(
                    name: $0,
                    manufacturer: $0,
                    model: $0,
                    hardwareVersion: nil,
                    firmwareVersion: nil,
                    softwareVersion: nil,
                    localIdentifier: nil,
                    udiDeviceIdentifier: nil
                )
            }

            let sample = HKQuantitySample(
                type: quantityType,
                quantity: quantity,
                start: currentDate,
                end: sampleEnd,
                device: device,
                metadata: deviceName != nil ? ["DeviceName": deviceName!] : nil
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
