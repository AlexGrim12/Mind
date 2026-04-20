import SwiftUI
import Charts

// MARK: - Root

struct DoctorDashboardView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userRole") private var userRole = ""

    var body: some View {
        TabView {
            NavigationStack {
                DoctorHomeTab()
                    .navigationTitle("Dashboard")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            DoctorLogoutButton(onLogout: logout)
                        }
                    }
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                DoctorPatientsTab()
                    .navigationTitle("Pacientes")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("Pacientes", systemImage: "person.2.fill") }

            NavigationStack {
                iPadClinicalCalendarView()
                    .navigationTitle("Agenda")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("Agenda", systemImage: "calendar") }

            NavigationStack {
                DoctorSettingsTab(onLogout: logout)
                    .navigationTitle("Configuración")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
        }
        .tint(.indigo)
    }

    private func logout() {
        isLoggedIn = false
        userRole = ""
    }
}

// MARK: - Logout Button

private struct DoctorLogoutButton: View {
    var onLogout: () -> Void
    @State private var showAlert = false

    var body: some View {
        Button {
            showAlert = true
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundStyle(.red.opacity(0.8))
        }
        .alert("¿Cerrar sesión?", isPresented: $showAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar sesión", role: .destructive) { onLogout() }
        } message: {
            Text("Volverás a la pantalla de inicio de sesión.")
        }
    }
}

// MARK: - Dashboard Tab

struct DoctorHomeTab: View {
    @State private var reviewPatient: ClinicalPatient?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // Header — compact for iPhone
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bienvenida,")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Dra. Rivera")
                                .font(.system(size: 26, weight: .black))
                        }
                        Spacer()
                        Label("IA · On-Device", systemImage: "checkmark.seal.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Label("Portal Clínico · MIND-LINK", systemImage: "brain.filled.head.profile")
                        .font(.caption)
                        .foregroundStyle(.indigo.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Summary stats — 2-column grid adapted for iPhone
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ClinicalSummaryCard(title: "Pacientes Activos", value: "24", icon: "person.3.fill",         color: .blue)
                    ClinicalSummaryCard(title: "Sesiones Hoy",      value: "6",  icon: "calendar.badge.clock", color: .green)
                    ClinicalSummaryCard(title: "Alertas",           value: "3",  icon: "exclamationmark.triangle.fill", color: .orange)
                    ClinicalSummaryCard(title: "Seguimientos",      value: "12", icon: "arrow.triangle.2.circlepath",   color: .indigo)
                }
                .padding(.horizontal, 20)

                // Priority alert
                VStack(alignment: .leading, spacing: 12) {
                    Text("Alertas Prioritarias")
                        .font(.title3.bold())
                        .padding(.horizontal, 20)

                    ClinicalPriorityAlertCard(
                        name: "Sofía M.",
                        matricula: "31920442",
                        description: "Tendencia de ánimo en descenso significativo los últimos 3 días.",
                        tags: ["Ansiedad", "Insomnio", "Exámenes"],
                        time: "Hace 5 min",
                        action: { reviewPatient = ClinicalPatient.mockSofia }
                    )
                    .padding(.horizontal, 20)
                }

                // Today's sessions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sesiones de Hoy")
                        .font(.title3.bold())
                        .padding(.horizontal, 20)

                    VStack(spacing: 10) {
                        ClinicalSessionRow(name: "Sofía M.",   time: "09:00 AM", detail: "Seguimiento de crisis")
                        ClinicalSessionRow(name: "Carlos T.",  time: "10:30 AM", detail: "Seguimiento post-crisis")
                        ClinicalSessionRow(name: "Ana P.",     time: "12:00 PM", detail: "Evaluación de progreso")
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationDestination(item: $reviewPatient) { patient in
            iPadPatientDetailView(patient: patient)
        }
    }
}

// MARK: - Patients Tab

struct DoctorPatientsTab: View {
    @State private var searchText = ""

    private var filtered: [ClinicalPatient] {
        guard !searchText.isEmpty else { return ClinicalPatient.allMocks }
        return ClinicalPatient.allMocks.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.matricula.contains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { patient in
                NavigationLink {
                    iPadPatientDetailView(patient: patient)
                } label: {
                    DoctorPatientRow(patient: patient)
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Buscar por nombre o matrícula")
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}

struct DoctorPatientRow: View {
    let patient: ClinicalPatient

    private var isCritical: Bool { (patient.moodTrend.last?.value ?? 5) <= 4 }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar with optional crisis badge
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.indigo.opacity(0.2), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(patient.name.prefix(1))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.indigo)
                    )
                if isCritical {
                    Circle()
                        .fill(.red)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(.white)
                        )
                        .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 1.5))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(patient.name)
                        .font(.headline)
                    Spacer()
                    if isCritical {
                        Text("Crisis")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                Text("Matrícula: \(patient.matricula)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !patient.tags.isEmpty {
                    Text(patient.tags.prefix(2).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings Tab

struct DoctorSettingsTab: View {
    var onLogout: () -> Void
    @State private var showLogoutAlert = false

    var body: some View {
        List {
            Section("Perfil") {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.indigo.opacity(0.2), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 58, height: 58)
                        Text("DR")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.indigo)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dra. Laura Rivera")
                            .font(.headline)
                        Text("Psicología clínica · CBT · Adolescentes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Label("Portal activo", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Sistema") {
                Label("MIND-LINK Portal Clínico", systemImage: "brain.filled.head.profile")
                    .foregroundStyle(.indigo)
                Label("IA On-Device · Activa", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Label("v1.0 · UANL · 2025", systemImage: "info.circle")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .listStyle(.insetGrouped)
        .alert("¿Cerrar sesión?", isPresented: $showLogoutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar sesión", role: .destructive) { onLogout() }
        } message: {
            Text("Serás redirigido a la pantalla de inicio de sesión.")
        }
    }
}

#Preview {
    DoctorDashboardView()
}
