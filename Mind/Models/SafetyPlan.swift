import SwiftData
import Foundation

@Model
final class SafetyPlan {
    var id: UUID
    var updatedAt: Date

    // 6 pasos Stanley-Brown
    var warningSignals: [String]       // Paso 1: señales de alerta
    var copingStrategies: [String]     // Paso 2: estrategias internas
    var distractingContacts: [Contact] // Paso 3: personas que distraen
    var supportContacts: [Contact]     // Paso 4: personas de apoyo
    var professionals: [Contact]       // Paso 5: profesionales
    var crisisLines: [CrisisLine]      // Paso 6: líneas de crisis

    var reasonsToLive: [String]        // Ancla motivacional

    init() {
        self.id = UUID()
        self.updatedAt = Date()
        self.warningSignals = []
        self.copingStrategies = []
        self.distractingContacts = []
        self.supportContacts = []
        self.professionals = []
        self.crisisLines = CrisisLine.defaults
        self.reasonsToLive = []
    }
}

struct Contact: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var phone: String
    var relationship: String
}

struct CrisisLine: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var number: String
    var country: String

    static let defaults: [CrisisLine] = [
        CrisisLine(name: "SAPTEL", number: "55 5259-8121", country: "México"),
        CrisisLine(name: "Línea de la Vida", number: "800 911-2000", country: "México"),
        CrisisLine(name: "988 Lifeline", number: "988", country: "EUA"),
        CrisisLine(name: "Teléfono Esperanza", number: "075", country: "España"),
    ]
}
