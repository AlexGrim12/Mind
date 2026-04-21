import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Wrapper sobre Apple Foundation Models (on-device LLM, iOS 26+).
/// El texto del diario **nunca sale del dispositivo**.
/// Cuando el framework no está disponible (simulador o iOS < 26),
/// cae a un sintetizador heurístico local que ya es útil para el usuario.
@MainActor
final class LLMService {

    struct JournalDigest {
        let summary: String
        let mood: String?
        let topics: [String]
    }

    /// Flujo de conveniencia: resumen + mood + temas en una sola llamada.
    func digestJournal(_ text: String) async -> JournalDigest {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return JournalDigest(summary: "Sin contenido para resumir.", mood: nil, topics: [])
        }

        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            if let fm = await foundationModelsDigest(text) {
                return fm
            }
        }
        #endif

        return JournalDigest(
            summary: simulatedSummary(for: text),
            mood: simulatedMood(for: text),
            topics: simulatedTopics(for: text)
        )
    }

    /// API original conservada por compatibilidad.
    func summarizeJournal(_ text: String) async -> String {
        await digestJournal(text).summary
    }

    /// API original conservada por compatibilidad.
    func extractTopics(_ text: String) async -> [String] {
        await digestJournal(text).topics
    }

    // MARK: — Apple Foundation Models (iOS 26+)

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private func foundationModelsDigest(_ text: String) async -> JournalDigest? {
        do {
            let session = LanguageModelSession(instructions: """
            Eres un acompañante empático que ayuda a una persona joven a reflexionar sobre su diario \
            personal. Respondes siempre en español, con calidez, sin juzgar, sin dar diagnósticos \
            médicos, sin usar el nombre de la persona. Eres breve y cuidadoso.
            """)

            async let summaryTask: String? = {
                let prompt = """
                Resume en 2 o 3 frases, en segunda persona (tú), el contenido emocional principal de esta entrada de diario. \
                Evita repetir frases textuales largas. Enfócate en cómo se siente la persona y qué situación describe:

                \(text)
                """
                let r = try? await session.respond(to: prompt)
                return r?.content
            }()

            async let moodTask: String? = {
                let prompt = """
                Clasifica el estado emocional general de esta entrada en UNA sola palabra en español \
                (por ejemplo: cansancio, esperanza, ansiedad, calma, rabia, alivio, tristeza, gratitud). \
                Solo devuelve la palabra, sin puntos ni explicaciones.

                \(text)
                """
                let r = try? await session.respond(to: prompt)
                return r?.content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }()

            async let topicsTask: [String] = {
                let prompt = """
                Extrae de 3 a 5 temas generales y anónimos de este texto, en español. \
                Devuelve solo las palabras separadas por coma, sin detalles personales, sin nombres propios.

                \(text)
                """
                let r = try? await session.respond(to: prompt)
                return (r?.content ?? "")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }()

            let summary = (await summaryTask) ?? simulatedSummary(for: text)
            let mood = await moodTask
            let topics = await topicsTask

            return JournalDigest(
                summary: summary,
                mood: (mood?.isEmpty == true) ? nil : mood,
                topics: topics.isEmpty ? simulatedTopics(for: text) : topics
            )
        } catch {
            return nil
        }
    }
    #endif

    // MARK: — Fallback heurístico (también sirve como generador cuando no hay FM)

    private func simulatedSummary(for text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmed.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        let wc = words.count

        if wc < 12 {
            return "Una entrada breve. Tomaste un momento para registrar cómo te sentías, y eso ya es un paso."
        }

        let sentences = trimmed
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let first = sentences.first ?? ""
        let lead = String(first.prefix(140))

        let tone = simulatedMood(for: trimmed) ?? "mixto"
        return "Tu entrada sugiere un estado emocional \(tone). Hablas de: «\(lead)…». Recuerda que escribir lo que sientes ya te ayuda a ordenarlo."
    }

    private func simulatedMood(for text: String) -> String? {
        let lower = text.lowercased()
        let buckets: [(String, [String])] = [
            ("ansiedad",  ["ansia", "nervios", "agobio", "agotad", "preocup", "estres"]),
            ("tristeza",  ["triste", "llor", "vacío", "vacio", "solo ", "sola ", "sin ganas"]),
            ("rabia",     ["rabia", "enfad", "coraje", "furia", "odio"]),
            ("cansancio", ["cansad", "agotad", "sin fuerzas", "quemad"]),
            ("gratitud",  ["gracias", "agradec", "valoro", "aprecio"]),
            ("esperanza", ["mejor", "esperanza", "avanc", "posible"]),
            ("calma",     ["tranquil", "calma", "paz", "relajad"]),
            ("alegría",   ["feliz", "content", "alegr", "riendo", "sonri"])
        ]
        for (mood, keywords) in buckets {
            if keywords.contains(where: { lower.contains($0) }) { return mood }
        }
        return nil
    }

    private func simulatedTopics(for text: String) -> [String] {
        let lower = text.lowercased()
        var topics: [String] = []
        let pairs: [(String, [String])] = [
            ("Escuela / estudios",   ["clase", "examen", "escuela", "universidad", "profesor", "tarea"]),
            ("Trabajo",              ["trabajo", "jefe", "oficina", "turno", "empleo"]),
            ("Familia",              ["familia", "mamá", "mama", "papá", "papa", "hermano", "hermana"]),
            ("Amistad",              ["amig", "amiga"]),
            ("Relación de pareja",   ["pareja", "novio", "novia", "relación"]),
            ("Sueño",                ["dormir", "sueño", "cansancio", "insomnio"]),
            ("Cuerpo",               ["cuerpo", "dolor", "cabeza", "espalda"]),
            ("Futuro",               ["futuro", "mañana", "próxim"]),
            ("Autoestima",           ["no valgo", "no sirvo", "soy mal", "no puedo"]),
            ("Gratitud",             ["gracias", "agradec", "aprecio"])
        ]
        for (topic, keywords) in pairs where keywords.contains(where: { lower.contains($0) }) {
            topics.append(topic)
        }
        if topics.isEmpty {
            topics = ["Emociones", "Vida diaria"]
        }
        return Array(topics.prefix(5))
    }
}
