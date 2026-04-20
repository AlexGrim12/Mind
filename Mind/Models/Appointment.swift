import SwiftData
import Foundation

@Model
final class Appointment {
    var id: UUID
    var date: Date
    var duration: AppointmentDuration
    var clinicianName: String
    var clinicianPhotoURL: String?
    var isRemote: Bool
    var videoURL: String?
    var sessionRating: SessionRating?
    var notes: String

    init(
        date: Date,
        duration: AppointmentDuration = .full,
        clinicianName: String,
        isRemote: Bool = false,
        videoURL: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.clinicianName = clinicianName
        self.clinicianPhotoURL = nil
        self.isRemote = isRemote
        self.videoURL = videoURL
        self.sessionRating = nil
        self.notes = ""
    }

    var isPast: Bool { date < Date() }
    var isUpcoming: Bool { date > Date() }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "es_MX")
        return f.string(from: date)
    }
}

enum AppointmentDuration: String, Codable, CaseIterable {
    case express = "Express · 15 min"
    case full    = "Sesión completa · 50 min"

    var minutes: Int {
        switch self {
        case .express: 15
        case .full:    50
        }
    }

    var icon: String {
        switch self {
        case .express: "bolt"
        case .full:    "clock"
        }
    }
}

/// Session Rating Scale — 4 ítems (1–10 cada uno)
struct SessionRating: Codable {
    var relationship: Double   // ¿Me sentí escuchado/a?
    var goals: Double          // ¿Hablamos de lo que quería?
    var approach: Double       // ¿El enfoque fue bueno para mí?
    var overall: Double        // ¿Cómo salgo en general?

    var average: Double {
        (relationship + goals + approach + overall) / 4
    }
}
