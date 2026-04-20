import Foundation

final class ClinicianService {
    static let shared = ClinicianService()
    private let api = APIClient.shared
    private init() {}

    // MARK: - Dashboard Summary

    func fetchSummary() async throws -> ClinicianSummary {
        try await api.get("/clinician/dashboard/summary")
    }

    // MARK: - Patient List

    func fetchPatients() async throws -> [APIPatient] {
        try await api.get("/clinician/patients")
    }

    // MARK: - Patient Detail

    func fetchPatientDetail(id: String) async throws -> APIPatientDetail {
        try await api.get("/clinician/patients/\(id)/detail")
    }

    // MARK: - Appointments

    func fetchAppointments(date: Date? = nil) async throws -> [APIClinicianAppointment] {
        var path = "/clinician/appointments"
        if let date {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            path += "?date=\(f.string(from: date))"
        }
        return try await api.get(path)
    }

    func createAppointment(patientId: String, date: Date, durationMinutes: Int, notes: String) async throws {
        let body = CreateAppointmentRequest(
            patientId: patientId,
            date: date,
            durationMinutes: durationMinutes,
            notes: notes
        )
        try await api.postDiscardingResponse("/clinician/appointments", body: body)
    }
}
