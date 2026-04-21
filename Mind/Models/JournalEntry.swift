import SwiftData
import Foundation

@Model
final class JournalEntry {
    var id: UUID
    var date: Date
    var prompt: String
    var body: String

    /// Resumen generado on-device (Apple Foundation Models) visible solo para el autor.
    var aiSummary: String?
    /// Emoción/estado principal detectado (opcional, para badges).
    var aiMood: String?
    /// Fecha de generación del resumen (para saber si está al día).
    var aiSummaryDate: Date?

    /// Nombre de archivo de la nota de audio (sin ruta), dentro de Documents/Journal/Audio/
    var audioFileName: String?
    /// Transcripción generada por Apple Speech (on-device).
    var audioTranscript: String?
    /// Duración en segundos del audio original.
    var audioDuration: Double?

    /// Nombres de archivos de imágenes adjuntas, en Documents/Journal/Images/
    var imageFileNames: [String]?

    /// Temas anonimizados enviados al profesional (si consentimiento activo).
    var sharedTopics: [String]?
    var isSharedWithClinician: Bool

    init(prompt: String, body: String) {
        self.id = UUID()
        self.date = Date()
        self.prompt = prompt
        self.body = body
        self.aiSummary = nil
        self.aiMood = nil
        self.aiSummaryDate = nil
        self.audioFileName = nil
        self.audioTranscript = nil
        self.audioDuration = nil
        self.imageFileNames = []
        self.sharedTopics = []
        self.isSharedWithClinician = false
    }

    // MARK: — Helpers de presentación

    /// Texto efectivo (combina cuerpo escrito + transcripción de audio si existe).
    var combinedText: String {
        let t = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = (audioTranscript ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        switch (t.isEmpty, a.isEmpty) {
        case (false, false): return "\(t)\n\n🎙️ \(a)"
        case (false, true):  return t
        case (true, false):  return a
        default:             return ""
        }
    }

    /// ¿La nota tiene algún contenido?
    var hasContent: Bool {
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || audioFileName != nil
        || !(imageFileNames ?? []).isEmpty
    }

    /// Vista previa breve para listas.
    var preview: String {
        let source = combinedText.replacingOccurrences(of: "\n", with: " ")
        if source.isEmpty {
            if audioFileName != nil { return "Nota de voz · sin transcripción" }
            if !(imageFileNames ?? []).isEmpty { return "\(imageFileNames?.count ?? 0) imagen(es)" }
            return "Entrada vacía"
        }
        return String(source.prefix(140))
    }

    /// Fecha legible (corta) para listas.
    var shortDate: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_ES")
        df.dateFormat = "d MMM · HH:mm"
        return df.string(from: date)
    }

    /// Kanji del mes (decorativo).
    var monthKanji: String {
        let month = Calendar.current.component(.month, from: date)
        let kanji = ["一月","二月","三月","四月","五月","六月","七月","八月","九月","十月","十一月","十二月"]
        return kanji[(month - 1).clamped(to: 0...11)]
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
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
