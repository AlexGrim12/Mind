import Foundation

// MARK: - Auth

struct LoginRequest: Encodable {
    let identifier: String
    let password: String
}

struct AuthResponse: Decodable {
    let id: String
    let identifier: String
    let name: String?
    let role: String    // "patient" | "clinician"
    let token: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case identifier, name, role, token
    }
}

// MARK: - Patient → Mood Sync

struct MoodSyncRequest: Encodable {
    let date: Date
    let score: Int
    let energy: Double
    let context: String
    let source: String
}

struct SyncResponse: Decodable {
    let success: Int?
    let failed: Int?
    let message: String?
}

// MARK: - Patient → Journal

struct JournalShareRequest: Encodable {
    let date: Date
    let sharedTopics: [String]
}

// MARK: - Patient → Questionnaire

struct QuestionnaireSubmitRequest: Encodable {
    let type: String        // "PHQ-9" | "GAD-7"
    let answers: [Int]
    let score: Int
    let severity: String    // "minimal" | "mild" | "moderate" | "severe"
}

// MARK: - Patient → Appointments

struct APIPatientAppointment: Identifiable, Decodable {
    let id: String
    let date: Date
    let durationMinutes: Int
    let clinicianName: String?
    let notes: String?
    let status: String?     // "upcoming" | "completed" | "cancelled"

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case date, durationMinutes, clinicianName, notes, status
    }
}

// MARK: - Clinician → Dashboard Summary

struct ClinicianSummary: Decodable {
    let activePatients: Int
    let alerts: Int
    let sessionsToday: Int
}

// MARK: - Clinician → Patient List

struct APIPatient: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let identifier: String          // matricula / cédula
    let status: String              // "stable" | "attention" | "crisis"
    let moodTrend: [APIMoodPoint]?
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, identifier, status, moodTrend, tags
    }

    var statusColor: String {
        switch status {
        case "crisis":    return "crisisRed"
        case "attention": return "moodYellow"
        default:          return "moodGreen"
        }
    }

    var isCritical: Bool { status == "crisis" }
}

struct APIMoodPoint: Decodable, Identifiable, Hashable {
    var id: String { day }
    let day: String
    let value: Int
}

// MARK: - Clinician → Patient Detail

struct APIPatientDetail: Decodable {
    let id: String
    let name: String
    let identifier: String
    let status: String
    let moodHistory: [APIMoodPoint]
    let tags: [String]
    let aiSummary: String?
    let latestQuestionnaires: LatestQuestionnaires?

    struct LatestQuestionnaires: Decodable {
        let phq9Score: Int?
        let gad7Score: Int?
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, identifier, status, moodHistory, tags, aiSummary, latestQuestionnaires
    }

    var isCritical: Bool { status == "crisis" }
    var displaySummary: String { aiSummary ?? "Sin síntesis disponible para este paciente." }
}

// MARK: - Clinician → Appointments

struct APIClinicianAppointment: Identifiable, Decodable {
    let id: String
    let patientName: String
    let avatarLetter: String?
    let date: Date
    let durationMinutes: Int
    let sessionType: String?    // "followUp" | "evaluation" | "crisis" | "firstVisit"
    let status: String?         // "upcoming" | "completed" | "cancelled"
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case patientName, avatarLetter, date, durationMinutes, sessionType, status, notes
    }

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Clinician → Create Appointment

struct CreateAppointmentRequest: Encodable {
    let patientId: String
    let date: Date
    let durationMinutes: Int
    let notes: String
}
