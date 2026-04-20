import Foundation
import HealthKit
import Combine

@MainActor
final class WatchHealthService: ObservableObject {
    private let store = HKHealthStore()

    @Published var heartRate: Double? = nil
    @Published var hrv: Double? = nil
    @Published var oxygenSaturation: Double? = nil
    @Published var steps: Int = 0
    @Published var stressLevel: StressLevel = .unknown
    @Published var isAuthorized = false

    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
    ]

    enum StressLevel: String {
        case unknown  = "–"
        case low      = "Bajo"
        case moderate = "Moderado"
        case high     = "Alto"

        var color: String {
            switch self {
            case .unknown:  return "gray"
            case .low:      return "green"
            case .moderate: return "yellow"
            case .high:     return "red"
            }
        }

        var emoji: String {
            switch self {
            case .unknown:  return "❓"
            case .low:      return "😌"
            case .moderate: return "😐"
            case .high:     return "😰"
            }
        }
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchAll()
        } catch {
            isAuthorized = false
        }
    }

    func fetchAll() async {
        async let fetchedHR    = fetchLatest(.heartRate, unit: HKUnit(from: "count/min"))
        async let fetchedHRV   = fetchLatest(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let fetchedO2    = fetchLatest(.oxygenSaturation, unit: .percent())
        async let fetchedSteps = fetchStepsToday()

        let (hrVal, hrvVal, o2Val, stepsVal) = await (fetchedHR, fetchedHRV, fetchedO2, fetchedSteps)

        heartRate        = hrVal
        hrv              = hrvVal
        oxygenSaturation = o2Val.map { $0 * 100 }
        steps            = stepsVal

        updateStressLevel()
    }

    // MARK: — Private helpers

    private func fetchLatest(_ identifier: HKQuantityTypeIdentifier,
                              unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type,
                                      predicate: HKQuery.predicateForSamples(
                                        withStart: Date().addingTimeInterval(-3600),
                                        end: Date()),
                                      limit: 1,
                                      sortDescriptors: [sort]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchStepsToday() async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
            let query = HKStatisticsQuery(quantityType: type,
                                           quantitySamplePredicate: predicate,
                                           options: .cumulativeSum) { _, stats, _ in
                let count = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                continuation.resume(returning: count)
            }
            store.execute(query)
        }
    }

    private func updateStressLevel() {
        guard let hrv = hrv else { stressLevel = .unknown; return }
        // HRV clínico: >50ms = bajo estrés, 20-50 = moderado, <20 = alto
        switch hrv {
        case 50...:   stressLevel = .low
        case 20..<50: stressLevel = .moderate
        default:      stressLevel = .high
        }
    }

    // Snapshot para enviar al iPhone
    var contextPayload: [String: Any] {
        var d: [String: Any] = ["stressLevel": stressLevel.rawValue]
        if let hr = heartRate { d["heartRate"] = hr }
        if let hrv = hrv { d["hrv"] = hrv }
        if let o2 = oxygenSaturation { d["o2"] = o2 }
        d["steps"] = steps
        return d
    }
}
