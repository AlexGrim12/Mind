import SwiftData
import Foundation

@Model
final class JournalEntry {
    var id: UUID
    var date: Date
    var prompt: String
    var body: String
    var aiSummary: String?       // generado on-device por LLM, visible solo para el estudiante
    var sharedTopics: [String]   // temas anonimizados enviados al profesional (si consentimiento activo)
    var isSharedWithClinician: Bool

    init(prompt: String, body: String) {
        self.id = UUID()
        self.date = Date()
        self.prompt = prompt
        self.body = body
        self.aiSummary = nil
        self.sharedTopics = []
        self.isSharedWithClinician = false
    }
}

/// Prompts rotatorios estilo Pennebaker
enum JournalPrompt: CaseIterable {
    case deepestThoughts
    case recentChallenge
    case relationship
    case school
    case bodyFeelings
    case gratitude

    var text: String {
        switch self {
        case .deepestThoughts:
            return "Escribe sobre tus pensamientos y sentimientos más profundos de hoy, sin filtros."
        case .recentChallenge:
            return "¿Qué situación reciente te ha costado trabajo manejar? Descríbela con detalle."
        case .relationship:
            return "¿Hay alguien en tu vida que ocupe mucho espacio en tu mente ahora? ¿Qué sientes al respecto?"
        case .school:
            return "¿Cómo te está afectando la escuela o el trabajo en este momento?"
        case .bodyFeelings:
            return "¿Dónde sientes la tensión en tu cuerpo hoy? ¿Qué crees que la causa?"
        case .gratitude:
            return "Escribe sobre algo pequeño que hoy valoras, aunque todo lo demás esté difícil."
        }
    }

    static func promptForMood(score: Int) -> String {
        switch score {
        case 0...3: return recentChallenge.text
        case 4...6: return deepestThoughts.text
        default:    return gratitude.text
        }
    }
}
