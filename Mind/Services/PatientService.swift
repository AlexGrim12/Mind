import Foundation

final class PatientService {
    static let shared = PatientService()
    private let api = APIClient.shared
    private init() {}

    // MARK: - Mood Sync

    /// Fire-and-forget: syncs a single mood entry to the backend after local save.
    func syncMood(score: Int, energy: Double, context: String, source: String) async {
        let body = MoodSyncRequest(
            date: Date(),
            score: score,
            energy: energy,
            context: context,
            source: source
        )
        try? await api.postDiscardingResponse("/patient/moods", body: [body])
    }

    // MARK: - Journal Share

    /// Fire-and-forget: shares extracted journal topics with the clinician.
    func shareJournalTopics(_ topics: [String]) async {
        guard !topics.isEmpty else { return }
        let body = JournalShareRequest(date: Date(), sharedTopics: topics)
        try? await api.postDiscardingResponse("/patient/journal-shares", body: body)
    }

    // MARK: - Questionnaire

    /// Fire-and-forget: submits questionnaire result to the backend.
    func submitQuestionnaire(type: String, answers: [Int], score: Int, severity: String) async {
        let body = QuestionnaireSubmitRequest(
            type: type,
            answers: answers,
            score: score,
            severity: severity
        )
        try? await api.postDiscardingResponse("/patient/questionnaires", body: body)
    }

    // MARK: - Appointments

    /// Returns the patient's confirmed appointments from the server.
    func fetchAppointments() async throws -> [APIPatientAppointment] {
        try await api.get("/patient/appointments")
    }
}
