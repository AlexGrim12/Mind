import Foundation
import Combine
import Observation
import WatchConnectivity
import WatchKit

@Observable
final class WatchStore: NSObject {
    var streak = 0
    var avgMood: Double = 0
    var todayDone = false
    var nextApptDate: Date? = nil
    var nextApptClinician: String? = nil
    var isSending = false
    var lastSentScore: Int? = nil
    var remoteCheckinRequestAt: Date? = nil
    var lastPhoneContextSyncAt: Date? = nil

    private var latestBiometricPayload: [String: Any] = [:]

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendBiometrics(_ payload: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        var enriched = payload
        enriched["capturedAt"] = Date().timeIntervalSince1970
        enriched["lastSentScore"] = lastSentScore ?? -1

        let device = WKInterfaceDevice.current()
        device.isBatteryMonitoringEnabled = true
        if device.batteryLevel >= 0 {
            enriched["watchBattery"] = Int(device.batteryLevel * 100)
        }

        latestBiometricPayload = enriched

        // transferUserInfo garantiza entrega aunque el iPhone no esté en primer plano
        WCSession.default.transferUserInfo(enriched)
    }

    func sendMood(score: Int) {
        DispatchQueue.main.async { self.isSending = true }
        WCSession.default.sendMessage(["score": score], replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.isSending = false
                if reply["ok"] as? Bool == true {
                    self?.lastSentScore = score
                    self?.todayDone = true
                }
            }
        }, errorHandler: { [weak self] _ in
            DispatchQueue.main.async { self?.isSending = false }
        })
    }
}

extension WatchStore: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {}

    func session(_ session: WCSession,
                 didReceiveApplicationContext context: [String: Any]) {
        DispatchQueue.main.async {
            self.streak    = context["streak"] as? Int ?? 0
            self.avgMood   = context["avgMood"] as? Double ?? 0
            self.todayDone = context["todayDone"] as? Bool ?? false
            if let ts = context["phoneSyncAt"] as? TimeInterval {
                self.lastPhoneContextSyncAt = Date(timeIntervalSince1970: ts)
            }
            if let ts = context["nextApptDate"] as? TimeInterval {
                self.nextApptDate = Date(timeIntervalSince1970: ts)
            }
            self.nextApptClinician = context["nextApptClinician"] as? String
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {
        guard let command = message["command"] as? String else {
            replyHandler(["ok": false])
            return
        }

        switch command {
        case "syncNow":
            var response = latestBiometricPayload
            response["ok"] = true
            response["capturedAt"] = Date().timeIntervalSince1970
            response["lastSentScore"] = lastSentScore ?? -1
            replyHandler(response)

        case "startMoodCheckin":
            DispatchQueue.main.async {
                self.remoteCheckinRequestAt = Date()
            }
            replyHandler(["ok": true])

        default:
            replyHandler(["ok": false])
        }
    }
}
