import SwiftData
import Foundation

@Model
final class MoodEntry {
    var id: UUID
    var date: Date
    var score: Int           // 0–10
    var energy: Double       // 0.0–1.0 (cansancio ↔ activación)
    var context: MoodContext
    var company: MoodCompany
    var activity: MoodActivity
    var voiceNoteURL: String?
    var source: MoodSource

    init(
        score: Int,
        energy: Double = 0.5,
        context: MoodContext = .home,
        company: MoodCompany = .alone,
        activity: MoodActivity = .resting,
        voiceNoteURL: String? = nil,
        source: MoodSource = .iPhone
    ) {
        self.id = UUID()
        self.date = Date()
        self.score = score
        self.energy = energy
        self.context = context
        self.company = company
        self.activity = activity
        self.voiceNoteURL = voiceNoteURL
        self.source = source
    }
}

enum MoodSource: String, Codable {
    case iPhone, watch
}

enum MoodContext: String, Codable, CaseIterable {
    case school = "Escuela"
    case home   = "Casa"
    case social = "Redes"

    var icon: String {
        switch self {
        case .school: "building.columns"
        case .home:   "house"
        case .social: "iphone"
        }
    }
}

enum MoodCompany: String, Codable, CaseIterable {
    case alone   = "Solo"
    case friends = "Amigos"
    case family  = "Familia"

    var icon: String {
        switch self {
        case .alone:   "person"
        case .friends: "person.2"
        case .family:  "house.and.flag"
        }
    }
}

enum MoodActivity: String, Codable, CaseIterable {
    case studying  = "Estudiando"
    case resting   = "Descansando"
    case exercising = "Ejercicio"

    var icon: String {
        switch self {
        case .studying:   "book"
        case .resting:    "moon"
        case .exercising: "figure.run"
        }
    }
}

extension MoodEntry {
    /// Color de la rueda según el score (0–10)
    var moodColor: String {
        switch score {
        case 0...2: return "moodPurple"
        case 3...4: return "moodBlue"
        case 5...6: return "moodGreen"
        case 7...8: return "moodYellow"
        default:    return "moodRed"
        }
    }

    var moodLabel: String {
        switch score {
        case 0...2: return "Muy bajo"
        case 3...4: return "Bajo"
        case 5...6: return "Neutral"
        case 7...8: return "Bien"
        default:    return "Excelente"
        }
    }
}
