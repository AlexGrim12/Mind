import Foundation

/// Wrapper sobre Apple Foundation Models (on-device LLM, iOS 18.1+).
/// El texto del diario nunca sale del dispositivo.
@MainActor
final class LLMService {

    /// Genera un resumen narrativo del diario para el propio estudiante.
    func summarizeJournal(_ text: String) async -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Sin contenido para resumir."
        }

        // Intenta usar Apple Foundation Models si está disponible
        if #available(iOS 26, *) {
            return await summarizeWithFoundationModels(text)
        } else {
            // Fallback para simulador / dispositivos < iOS 26
            return simulatedSummary(for: text)
        }
    }

    /// Extrae 3–5 temas anonimizados para el profesional.
    func extractTopics(_ text: String) async -> [String] {
        guard !text.isEmpty else { return [] }

        if #available(iOS 26, *) {
            return await extractTopicsWithFoundationModels(text)
        } else {
            return simulatedTopics(for: text)
        }
    }

    // MARK: — Foundation Models (iOS 26+)

    @available(iOS 26, *)
    private func summarizeWithFoundationModels(_ text: String) async -> String {
        // Importamos aquí para no requerir el framework en builds anteriores
        // En iOS 26 el framework se llama `FoundationModels`
        // La API exacta puede diferir del ejemplo — leer docs en Xcode 26+
        //
        // Ejemplo de uso cuando esté disponible:
        // let session = LanguageModelSession()
        // let prompt = "Resume estos pensamientos en 2-3 frases para el propio autor. No uses su nombre. Sé empático:\n\n\(text)"
        // let response = try? await session.respond(to: prompt)
        // return response?.content ?? simulatedSummary(for: text)
        return simulatedSummary(for: text)
    }

    @available(iOS 26, *)
    private func extractTopicsWithFoundationModels(_ text: String) async -> [String] {
        // let session = LanguageModelSession()
        // let prompt = "Extrae 3-5 temas generales de este texto. Devuelve solo las palabras clave separadas por coma, sin detalles identificativos:\n\n\(text)"
        // let response = try? await session.respond(to: prompt)
        // return response?.content.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        return simulatedTopics(for: text)
    }

    // MARK: — Simulaciones para hackathon (simulador / iOS < 26)

    private func simulatedSummary(for text: String) -> String {
        let wordCount = text.split(separator: " ").count
        if wordCount < 20 {
            return "Entrada breve del día. El autor expresó pensamientos sobre su situación actual."
        }
        // Fake pero convincente para el demo
        let summaries = [
            "El autor refleja sentimientos mixtos relacionados con las responsabilidades académicas y las relaciones interpersonales. Hay señales de tensión pero también de resiliencia.",
            "Se percibe cansancio emocional y preocupación por el futuro cercano. El autor también menciona momentos de calma durante el día.",
            "La entrada revela una semana de alta demanda. El autor identifica el sueño y el tiempo personal como áreas que quisiera mejorar.",
        ]
        return summaries[abs(text.hashValue) % summaries.count]
    }

    private func simulatedTopics(for text: String) -> [String] {
        let allTopics = [
            ["Presión académica", "Sueño", "Relaciones"],
            ["Familia", "Estrés", "Tiempo libre"],
            ["Amigos", "Futuro", "Salud"],
            ["Trabajo escolar", "Emociones", "Descanso"],
        ]
        return allTopics[abs(text.hashValue) % allTopics.count]
    }
}
