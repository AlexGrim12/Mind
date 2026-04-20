import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    // MARK: — Published state

    @Published var lastNightSleep: SleepSummary? = nil
    @Published var weekSleepHistory: [SleepSummary] = []
    @Published var isAuthorized = false
    @Published var isLoading = false

    private let readTypes: Set<HKObjectType> = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]

    // MARK: — Public API

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchSleep()
        } catch {
            isAuthorized = false
        }
    }

    func fetchSleep() async {
        isLoading = true
        defer { isLoading = false }

        // Fetch last 8 days of sleep samples
        let end   = Date()
        let start = Calendar.current.date(byAdding: .day, value: -8, to: end)!

        let samples = await fetchSleepSamples(from: start, to: end)
        let grouped = groupByNight(samples)

        weekSleepHistory = grouped.suffix(7)
        lastNightSleep   = grouped.last
    }

    // MARK: — Private helpers

    private func fetchSleepSamples(from start: Date, to end: Date) async -> [HKCategorySample] {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(sampleType: type,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sort]) { _, results, _ in
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }
    }

    /// Groups raw samples into per-night summaries (night = sleep window ending before noon)
    private func groupByNight(_ samples: [HKCategorySample]) -> [SleepSummary] {
        let cal = Calendar.current

        // Bucket samples by the morning date they belong to
        var buckets: [Date: [HKCategorySample]] = [:]
        for sample in samples {
            let hour = cal.component(.hour, from: sample.startDate)
            // Treat sleep starting before 6 AM as belonging to the previous day's night
            let anchor = hour < 6
                ? cal.startOfDay(for: sample.startDate)
                : cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: sample.startDate)!)
            buckets[anchor, default: []].append(sample)
        }

        return buckets.keys.sorted().compactMap { date in
            buildSummary(date: date, samples: buckets[date]!)
        }
    }

    private func buildSummary(date: Date, samples: [HKCategorySample]) -> SleepSummary? {
        var inBed: TimeInterval = 0
        var core: TimeInterval  = 0
        var deep: TimeInterval  = 0
        var rem: TimeInterval   = 0
        var awake: TimeInterval = 0

        var earliest: Date = .distantFuture
        var latest:   Date = .distantPast

        for s in samples {
            let duration = s.endDate.timeIntervalSince(s.startDate)
            if s.startDate < earliest { earliest = s.startDate }
            if s.endDate   > latest   { latest   = s.endDate }

            switch HKCategoryValueSleepAnalysis(rawValue: s.value) {
            case .inBed:        inBed += duration
            case .asleepCore:   core  += duration
            case .asleepDeep:   deep  += duration
            case .asleepREM:    rem   += duration
            case .awake:        awake += duration
            default: break
            }
        }

        let totalAsleep = core + deep + rem
        guard totalAsleep > 0 else { return nil }

        return SleepSummary(
            date:         date,
            bedtime:      earliest == .distantFuture ? nil : earliest,
            wakeTime:     latest   == .distantPast   ? nil : latest,
            totalAsleep:  totalAsleep,
            inBed:        inBed,
            deepSleep:    deep,
            remSleep:     rem,
            coreSleep:    core,
            awakeTime:    awake
        )
    }
}

// MARK: — Sleep data model

struct SleepSummary: Identifiable {
    let id = UUID()
    let date: Date
    let bedtime: Date?
    let wakeTime: Date?
    let totalAsleep: TimeInterval   // seconds
    let inBed: TimeInterval
    let deepSleep: TimeInterval
    let remSleep: TimeInterval
    let coreSleep: TimeInterval
    let awakeTime: TimeInterval

    var totalHours: Double { totalAsleep / 3600 }
    var deepHours: Double  { deepSleep / 3600 }
    var remHours: Double   { remSleep / 3600 }
    var coreHours: Double  { coreSleep / 3600 }

    var quality: SleepQuality {
        switch totalHours {
        case 8...:      return .excellent
        case 6..<8:     return .good
        case 4..<6:     return .fair
        default:        return .poor
        }
    }

    var formattedTotal: String { formatHours(totalAsleep) }
    var formattedDeep:  String { formatHours(deepSleep) }
    var formattedREM:   String { formatHours(remSleep) }

    private func formatHours(_ interval: TimeInterval) -> String {
        let h = Int(interval / 3600)
        let m = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    var weekdayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: "es_MX")
        return f.string(from: date)
    }

    var shortDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "es_MX")
        return f.string(from: date)
    }
}

enum SleepQuality: String {
    case excellent = "Excelente"
    case good      = "Bueno"
    case fair      = "Regular"
    case poor      = "Insuficiente"

    var color: String {
        switch self {
        case .excellent: return "moodGreen"
        case .good:      return "moodBlue"
        case .fair:      return "moodYellow"
        case .poor:      return "moodPurple"
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "moon.stars.fill"
        case .good:      return "moon.fill"
        case .fair:      return "moon"
        case .poor:      return "exclamationmark.triangle"
        }
    }

    var insight: String {
        switch self {
        case .excellent:
            return "Dormiste muy bien. Tu concentración y estado de ánimo se benefician de este descanso."
        case .good:
            return "Buen descanso. Intenta mantener un horario consistente para optimizar tu recuperación."
        case .fair:
            return "Sueño por debajo de lo recomendado. Esto puede afectar tu ánimo y concentración hoy."
        case .poor:
            return "Pocas horas de sueño. Considera una siesta corta y evita cafeína después de las 2 PM."
        }
    }
}
