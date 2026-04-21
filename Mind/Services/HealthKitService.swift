import Foundation
import HealthKit
import Combine
import Observation

@MainActor
@Observable
final class HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    // MARK: — Published state

    var lastNightSleep: SleepSummary? = nil
    var weekSleepHistory: [SleepSummary] = []
    var todaySnapshot: BiometricSnapshot? = nil
    var weekSnapshots: [BiometricSnapshot] = []
    var wellnessScore: WellnessScore? = nil
    var isAuthorized = false
    var isLoading = false

    // MARK: — HealthKit types to read

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        ]
        let quantities: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .heartRateVariabilitySDNN,
            .restingHeartRate,
            .walkingHeartRateAverage,
            .oxygenSaturation,
            .respiratoryRate,
            .bodyTemperature,
            .appleSleepingWristTemperature,
            .stepCount,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .appleExerciseTime,
            .appleStandTime,
            .distanceWalkingRunning,
            .flightsClimbed,
            .vo2Max,
            .environmentalAudioExposure,
            .headphoneAudioExposure,
        ]
        for id in quantities {
            if let t = HKObjectType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        // Mindful sessions es HKCategoryType, no quantity
        if let t = HKObjectType.categoryType(forIdentifier: .mindfulSession) { types.insert(t) }
        return types
    }

    // MARK: — Public API

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
        isLoading = true
        defer { isLoading = false }
        async let sleepTask   = fetchSleepData()
        async let snapTask    = fetchWeekSnapshots()
        let (_, snaps) = await (sleepTask, snapTask)
        weekSnapshots = snaps
        todaySnapshot = snaps.last
        wellnessScore = todaySnapshot.map { WellnessScore(snapshot: $0, sleep: lastNightSleep) }
    }

    // MARK: — Sleep

    private func fetchSleepData() async {
        let end   = Date()
        let start = Calendar.current.date(byAdding: .day, value: -8, to: end)!
        let samples = await fetchSleepSamples(from: start, to: end)
        let grouped = groupByNight(samples)
        weekSleepHistory = grouped.suffix(7)
        lastNightSleep   = grouped.last
    }

    // MARK: — Daily snapshots (last 7 days)

    private func fetchWeekSnapshots() async -> [BiometricSnapshot] {
        var result: [BiometricSnapshot] = []
        let cal = Calendar.current
        for daysBack in (0..<7).reversed() {
            let end   = daysBack == 0 ? Date() : cal.startOfDay(for: cal.date(byAdding: .day, value: -(daysBack - 1), to: Date())!)
            let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -daysBack, to: Date())!)
            let snap  = await buildSnapshot(from: start, to: end)
            result.append(snap)
        }
        return result
    }

    private func buildSnapshot(from start: Date, to end: Date) async -> BiometricSnapshot {
        async let hr      = fetchLatestInRange(.heartRate,                unit: HKUnit(from: "count/min"), start: start, end: end)
        async let hrRest  = fetchLatestInRange(.restingHeartRate,         unit: HKUnit(from: "count/min"), start: start, end: end)
        async let hrWalk  = fetchLatestInRange(.walkingHeartRateAverage,  unit: HKUnit(from: "count/min"), start: start, end: end)
        async let hrv     = fetchLatestInRange(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: start, end: end)
        async let o2      = fetchLatestInRange(.oxygenSaturation,         unit: .percent(),               start: start, end: end)
        async let resp    = fetchLatestInRange(.respiratoryRate,          unit: HKUnit(from: "count/min"), start: start, end: end)
        async let tempBody = fetchLatestInRange(.bodyTemperature,         unit: .degreeCelsius(),         start: start, end: end)
        async let tempWrist = fetchLatestInRange(.appleSleepingWristTemperature, unit: .degreeCelsius(), start: start, end: end)
        async let steps   = fetchSum(.stepCount,             unit: .count(),                  start: start, end: end)
        async let active  = fetchSum(.activeEnergyBurned,    unit: .kilocalorie(),            start: start, end: end)
        async let basal   = fetchSum(.basalEnergyBurned,     unit: .kilocalorie(),            start: start, end: end)
        async let exercise = fetchSum(.appleExerciseTime,    unit: .minute(),                 start: start, end: end)
        async let stand   = fetchSum(.appleStandTime,        unit: .minute(),                 start: start, end: end)
        async let dist    = fetchSum(.distanceWalkingRunning, unit: .meter(),                 start: start, end: end)
        async let flights = fetchSum(.flightsClimbed,        unit: .count(),                  start: start, end: end)
        async let vo2     = fetchLatestInRange(.vo2Max,      unit: HKUnit(from: "ml/kg·min"), start: start, end: end)
        async let noiseEnv = fetchAverage(.environmentalAudioExposure, unit: .decibelAWeightedSoundPressureLevel(), start: start, end: end)
        async let noiseHP  = fetchAverage(.headphoneAudioExposure,     unit: .decibelAWeightedSoundPressureLevel(), start: start, end: end)
        async let mindful  = fetchMindfulMinutes(start: start, end: end)

        return await BiometricSnapshot(
            date:               start,
            heartRate:          hr,
            restingHeartRate:   hrRest,
            walkingHeartRate:   hrWalk,
            hrv:                hrv,
            oxygenSaturation:   o2.map { $0 * 100 },
            respiratoryRate:    resp,
            bodyTemperature:    tempBody,
            wristTemperature:   tempWrist,
            steps:              Int(steps ?? 0),
            activeCalories:     active ?? 0,
            basalCalories:      basal ?? 0,
            exerciseMinutes:    Int(exercise ?? 0),
            standMinutes:       Int(stand ?? 0),
            distanceMeters:     dist ?? 0,
            flightsClimbed:     Int(flights ?? 0),
            vo2Max:             vo2,
            noiseEnvironment:   noiseEnv,
            noiseHeadphones:    noiseHP,
            mindfulMinutes:     Int(mindful)
        )
    }

    // MARK: — Generic HealthKit query helpers

    private func fetchLatestInRange(_ id: HKQuantityTypeIdentifier,
                                    unit: HKUnit,
                                    start: Date,
                                    end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1,
                                      sortDescriptors: [sort]) { _, samples, _ in
                let val = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: val)
            }
            store.execute(query)
        }
    }

    private func fetchSum(_ id: HKQuantityTypeIdentifier,
                          unit: HKUnit,
                          start: Date,
                          end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, stats, _ in
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func fetchAverage(_ id: HKQuantityTypeIdentifier,
                              unit: HKUnit,
                              start: Date,
                              end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: .discreteAverage) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func fetchMindfulMinutes(start: Date, end: Date) async -> Double {
        guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return 0 }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(sampleType: type, predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let total = samples?.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0
                continuation.resume(returning: total / 60)
            }
            store.execute(query)
        }
    }

    // MARK: — Sleep helpers

    private func fetchSleepSamples(from start: Date, to end: Date) async -> [HKCategorySample] {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(sampleType: type, predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, _ in
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }
    }

    private func groupByNight(_ samples: [HKCategorySample]) -> [SleepSummary] {
        let cal = Calendar.current
        var buckets: [Date: [HKCategorySample]] = [:]
        for s in samples {
            let hour   = cal.component(.hour, from: s.startDate)
            let anchor = hour < 6
                ? cal.startOfDay(for: s.startDate)
                : cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: s.startDate)!)
            buckets[anchor, default: []].append(s)
        }
        return buckets.keys.sorted().compactMap { buildSleepSummary(date: $0, samples: buckets[$0]!) }
    }

    private func buildSleepSummary(date: Date, samples: [HKCategorySample]) -> SleepSummary? {
        var core: TimeInterval = 0, deep: TimeInterval = 0
        var rem: TimeInterval  = 0, awake: TimeInterval = 0, inBed: TimeInterval = 0
        var earliest: Date = .distantFuture, latest: Date = .distantPast
        for s in samples {
            let d = s.endDate.timeIntervalSince(s.startDate)
            if s.startDate < earliest { earliest = s.startDate }
            if s.endDate   > latest   { latest   = s.endDate }
            switch HKCategoryValueSleepAnalysis(rawValue: s.value) {
            case .inBed:       inBed += d
            case .asleepCore:  core  += d
            case .asleepDeep:  deep  += d
            case .asleepREM:   rem   += d
            case .awake:       awake += d
            default: break
            }
        }
        let total = core + deep + rem
        guard total > 0 else { return nil }
        return SleepSummary(date: date,
                            bedtime: earliest == .distantFuture ? nil : earliest,
                            wakeTime: latest == .distantPast ? nil : latest,
                            totalAsleep: total, inBed: inBed,
                            deepSleep: deep, remSleep: rem,
                            coreSleep: core, awakeTime: awake)
    }
}

// MARK: — Sleep models

struct SleepSummary: Identifiable {
    let id = UUID()
    let date: Date
    let bedtime: Date?
    let wakeTime: Date?
    let totalAsleep: TimeInterval
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

    var formattedTotal: String { fmt(totalAsleep) }
    var formattedDeep:  String { fmt(deepSleep) }
    var formattedREM:   String { fmt(remSleep) }

    private func fmt(_ t: TimeInterval) -> String {
        let h = Int(t / 3600), m = Int((t.truncatingRemainder(dividingBy: 3600)) / 60)
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    var weekdayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEE"; f.locale = Locale(identifier: "es_MX")
        return f.string(from: date)
    }

    var shortDate: String {
        let f = DateFormatter(); f.dateFormat = "d MMM"; f.locale = Locale(identifier: "es_MX")
        return f.string(from: date)
    }
}

enum SleepQuality: String {
    case excellent = "Excelente"
    case good      = "Bueno"
    case fair      = "Regular"
    case poor      = "Insuficiente"

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
        case .excellent: return "Dormiste muy bien. Tu concentración y estado de ánimo se benefician de este descanso."
        case .good:      return "Buen descanso. Intenta mantener un horario consistente para optimizar tu recuperación."
        case .fair:      return "Sueño por debajo de lo recomendado. Puede afectar tu ánimo y concentración hoy."
        case .poor:      return "Pocas horas de sueño. Considera una siesta corta y evita cafeína después de las 2 PM."
        }
    }
}

// MARK: — Biometric Snapshot

struct BiometricSnapshot: Identifiable {
    let id = UUID()
    let date: Date

    // Cardiovascular
    let heartRate: Double?
    let restingHeartRate: Double?
    let walkingHeartRate: Double?
    let hrv: Double?
    let oxygenSaturation: Double?   // %
    let respiratoryRate: Double?    // breaths/min

    // Temperature
    let bodyTemperature: Double?    // °C
    let wristTemperature: Double?   // °C (Series 8+ while sleeping)

    // Activity
    let steps: Int
    let activeCalories: Double
    let basalCalories: Double
    let exerciseMinutes: Int
    let standMinutes: Int
    let distanceMeters: Double
    let flightsClimbed: Int
    let vo2Max: Double?             // ml/kg·min

    // Environment & Mind
    let noiseEnvironment: Double?   // dBA
    let noiseHeadphones: Double?    // dBA
    let mindfulMinutes: Int

    // Computed
    var totalCalories: Double { activeCalories + basalCalories }
    var distanceKm: Double    { distanceMeters / 1000 }

    var weekdayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEE"; f.locale = Locale(identifier: "es_MX")
        return f.string(from: date)
    }

    var activityLevel: ActivityLevel {
        switch steps {
        case 10000...: return .high
        case 6000..<10000: return .moderate
        case 2000..<6000:  return .low
        default:           return .sedentary
        }
    }
}

enum ActivityLevel: String {
    case high      = "Muy activo"
    case moderate  = "Activo"
    case low       = "Poco activo"
    case sedentary = "Sedentario"

    var color: String {
        switch self {
        case .high:     return "moodGreen"
        case .moderate: return "moodBlue"
        case .low:      return "moodYellow"
        case .sedentary: return "moodPurple"
        }
    }
}

// MARK: — Wellness Score (0–100)

struct WellnessScore {
    let total: Int           // 0–100
    let sleepScore: Int      // 0–25
    let activityScore: Int   // 0–25
    let cardiovascularScore: Int  // 0–25
    let recoveryScore: Int   // 0–25

    var label: String {
        switch total {
        case 80...:   return "Excelente"
        case 60..<80: return "Bueno"
        case 40..<60: return "Regular"
        default:      return "Necesita atención"
        }
    }

    var insight: String {
        switch total {
        case 80...:
            return "Tu cuerpo está en muy buen estado hoy. Aprovecha para rendir al máximo."
        case 60..<80:
            return "Buena condición general. Mantén tu rutina de actividad y sueño."
        case 40..<60:
            return "Algunos indicadores están por debajo. Prioriza descanso y movimiento hoy."
        default:
            return "Tu cuerpo necesita recuperación. Descansa, hidratate y evita el estrés innecesario."
        }
    }

    var color: String {
        switch total {
        case 80...:   return "moodGreen"
        case 60..<80: return "moodBlue"
        case 40..<60: return "moodYellow"
        default:      return "moodPurple"
        }
    }

    init(snapshot: BiometricSnapshot, sleep: SleepSummary?) {
        // Sleep (25 pts)
        var s = 0
        if let sl = sleep {
            s += min(Int(sl.totalHours / 8.0 * 15), 15)   // hasta 15 pts por horas
            s += min(Int(sl.deepHours  / 1.5 * 5),  5)    // hasta 5 pts por sueño profundo
            s += min(Int(sl.remHours   / 1.5 * 5),  5)    // hasta 5 pts por REM
        }
        sleepScore = min(s, 25)

        // Activity (25 pts)
        var a = 0
        a += min(snapshot.steps / 400, 10)                  // hasta 10 pts por pasos (10k = máx)
        a += min(snapshot.exerciseMinutes / 3, 10)           // hasta 10 pts por ejercicio (30 min = máx)
        a += min(snapshot.flightsClimbed, 5)                 // hasta 5 pts por pisos
        activityScore = min(a, 25)

        // Cardiovascular (25 pts)
        var c = 0
        if let hrv = snapshot.hrv {
            c += hrv > 50 ? 10 : hrv > 30 ? 7 : hrv > 20 ? 4 : 2
        }
        if let rhr = snapshot.restingHeartRate {
            c += rhr < 60 ? 8 : rhr < 70 ? 6 : rhr < 80 ? 4 : 2
        }
        if let o2 = snapshot.oxygenSaturation {
            c += o2 >= 98 ? 7 : o2 >= 95 ? 5 : o2 >= 90 ? 2 : 0
        }
        cardiovascularScore = min(c, 25)

        // Recovery (25 pts) — temp, respiration, mindfulness, noise
        var r = 0
        if let resp = snapshot.respiratoryRate {
            r += (resp >= 12 && resp <= 20) ? 8 : 3
        }
        if let temp = snapshot.wristTemperature ?? snapshot.bodyTemperature {
            r += (temp >= 36.0 && temp <= 37.5) ? 7 : 3
        }
        r += min(snapshot.mindfulMinutes * 2, 10)            // hasta 10 pts por mindfulness (5 min = máx)
        recoveryScore = min(r, 25)

        total = sleepScore + activityScore + cardiovascularScore + recoveryScore
    }
}
