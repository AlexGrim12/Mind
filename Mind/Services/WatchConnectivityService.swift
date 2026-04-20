import Foundation
import Combine
import WatchConnectivity
import SwiftData

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published var isPaired = false
    @Published var isWatchAppInstalled = false
    @Published var isReachable = false
    @Published var latestHeartRate: Double? = nil
    @Published var latestHRV: Double? = nil
    @Published var latestO2: Double? = nil
    @Published var latestSteps: Int = 0
    @Published var latestStressLevel: String = "–"
    @Published var watchBatteryLevel: Int? = nil
    @Published var lastWatchSyncDate: Date? = nil
    @Published var lastWatchMoodScore: Int? = nil
    @Published var isRequestingLiveSync = false
    @Published var watchActionMessage = "Sincronización pendiente"

    private var modelContext: ModelContext?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func requestWatchSyncNow() {
        guard WCSession.default.activationState == .activated else {
            watchActionMessage = "Watch no disponible"
            return
        }
        guard WCSession.default.isReachable else {
            watchActionMessage = "Abre Mind en Watch para sincronizar en vivo"
            return
        }

        isRequestingLiveSync = true
        WCSession.default.sendMessage(["command": "syncNow"], replyHandler: { [weak self] reply in
            Task { @MainActor in
                guard let self else { return }
                self.isRequestingLiveSync = false
                self.applyWatchPayload(reply)
                self.watchActionMessage = "Watch actualizado"
            }
        }, errorHandler: { [weak self] _ in
            Task { @MainActor in
                self?.isRequestingLiveSync = false
                self?.watchActionMessage = "No se pudo sincronizar ahora"
            }
        })
    }

    func requestWatchMoodCheckin() {
        guard WCSession.default.activationState == .activated else {
            watchActionMessage = "Watch no disponible"
            return
        }
        guard WCSession.default.isReachable else {
            watchActionMessage = "Abre Mind en Watch para enviar la acción"
            return
        }

        WCSession.default.sendMessage(["command": "startMoodCheckin"], replyHandler: { [weak self] _ in
            Task { @MainActor in
                self?.watchActionMessage = "Check-in abierto en Watch"
            }
        }, errorHandler: { [weak self] _ in
            Task { @MainActor in
                self?.watchActionMessage = "No fue posible abrir el check-in"
            }
        })
    }

    // Push latest context to Watch (call after any mood save or appointment change)
    func pushContext(moodEntries: [MoodEntry], appointments: [Appointment]) {
        guard WCSession.default.activationState == .activated else { return }

        let recentScores = moodEntries.prefix(7).map(\.score)
        let avg = recentScores.isEmpty ? 0.0 : Double(recentScores.reduce(0, +)) / Double(recentScores.count)

        let nextAppt = appointments.first { $0.isUpcoming }
        var context: [String: Any] = [
            "streak": moodEntries.count,
            "avgMood": avg,
            "todayDone": moodEntries.first.map { Calendar.current.isDateInToday($0.date) } ?? false,
            "phoneSyncAt": Date().timeIntervalSince1970
        ]

        if let appt = nextAppt {
            context["nextApptDate"] = appt.date.timeIntervalSince1970
            context["nextApptClinician"] = appt.clinicianName
        }

        try? WCSession.default.updateApplicationContext(context)
    }

    private func applyWatchPayload(_ payload: [String: Any]) {
        latestHeartRate = payload["heartRate"] as? Double
        latestHRV = payload["hrv"] as? Double
        latestO2 = payload["o2"] as? Double
        latestSteps = payload["steps"] as? Int ?? latestSteps
        latestStressLevel = payload["stressLevel"] as? String ?? latestStressLevel
        watchBatteryLevel = payload["watchBattery"] as? Int

        if let sent = payload["lastSentScore"] as? Int, sent >= 0 {
            lastWatchMoodScore = sent
        }

        if let ts = payload["capturedAt"] as? TimeInterval {
            lastWatchSyncDate = Date(timeIntervalSince1970: ts)
        } else {
            lastWatchSyncDate = Date()
        }
    }
}

// MARK: — WCSessionDelegate (iPhone side)

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in
            isPaired = session.isPaired
            isWatchAppInstalled = session.isWatchAppInstalled
            isReachable = session.isReachable
            watchActionMessage = session.isWatchAppInstalled ? "Listo para sincronizar" : "Instala la app en Apple Watch"
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            watchActionMessage = session.isReachable ? "Watch conectado en vivo" : "Watch sin conexión en vivo"
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    // Receive biometrics transferred from Watch
    nonisolated func session(_ session: WCSession,
                             didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            self.applyWatchPayload(userInfo)
            self.watchActionMessage = "Datos del Watch recibidos"
        }
    }

    // Receive mood check-in sent from Watch
    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        guard let score = message["score"] as? Int else {
            replyHandler(["ok": false])
            return
        }

        Task { @MainActor in
            guard let context = self.modelContext else { replyHandler(["ok": false]); return }
            let entry = MoodEntry(score: score, source: .watch)
            context.insert(entry)
            try? context.save()
            replyHandler(["ok": true])
        }
    }
}
