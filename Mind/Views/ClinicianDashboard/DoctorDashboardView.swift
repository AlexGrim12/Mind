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
                DoctorAgendaTab()
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
        APIClient.shared.clearSession()
        isLoggedIn = false
        userRole = ""
    }
}

// MARK: - Logout Button

private struct DoctorLogoutButton: View {
    var onLogout: () -> Void
    @State private var showAlert = false

    var body: some View {
        Button { showAlert = true } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundStyle(Color.red.opacity(0.8))
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
    @State private var summary: ClinicianSummary?
    @State private var alertPatient: APIPatient?
    @State private var patients: [APIPatient] = []
    @State private var isLoading = true
    @State private var errorMsg: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // Header
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
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Label("Portal Clínico · MIND-LINK", systemImage: "brain.filled.head.profile")
                        .font(.caption)
                        .foregroundStyle(Color.indigo.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Summary cards from API
                if isLoading {
                    summarySkeletonGrid
                } else if let s = summary {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ClinicalSummaryCard(title: "Pacientes Activos", value: "\(s.activePatients)",
                                            icon: "person.3.fill",                   color: .blue)
                        ClinicalSummaryCard(title: "Sesiones Hoy",      value: "\(s.sessionsToday)",
                                            icon: "calendar.badge.clock",            color: .green)
                        ClinicalSummaryCard(title: "Alertas",           value: "\(s.alerts)",
                                            icon: "exclamationmark.triangle.fill",   color: .orange)
                        ClinicalSummaryCard(title: "Seguimientos",      value: "—",
                                            icon: "arrow.triangle.2.circlepath",     color: .indigo)
                    }
                    .padding(.horizontal, 20)
                }

                // Crisis patients from API
                let crisisPatients = patients.filter(\.isCritical)
                if !crisisPatients.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alertas Prioritarias")
                            .font(.title3.bold())
                            .padding(.horizontal, 20)
                        ForEach(crisisPatients) { patient in
                            APIAlertCard(patient: patient)
                                .padding(.horizontal, 20)
                        }
                    }
                }

                // Error banner
                if let errorMsg {
                    Label(errorMsg, systemImage: "wifi.slash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .task { await loadDashboard() }
        .refreshable { await loadDashboard() }
        .navigationDestination(item: $alertPatient) { patient in
            APIPatientDetailView(patient: patient)
        }
    }

    private var summarySkeletonGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(height: 110)
                    .redacted(reason: .placeholder)
            }
        }
        .padding(.horizontal, 20)
    }

    private func loadDashboard() async {
        isLoading = true
        errorMsg = nil
        async let summaryResult = ClinicianService.shared.fetchSummary()
        async let patientsResult = ClinicianService.shared.fetchPatients()
        do {
            summary = try await summaryResult
            patients = try await patientsResult
        } catch {
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Alert Card (real data)

struct APIAlertCard: View {
    let patient: APIPatient
    @State private var isPulsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.red.opacity(0.2)).frame(width: 12, height: 12)
                        .scaleEffect(isPulsing ? 1.8 : 1).opacity(isPulsing ? 0 : 1)
                        .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: isPulsing)
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                }
                .onAppear { isPulsing = true }
                Text("ATENCIÓN REQUERIDA")
                    .font(.caption.bold()).foregroundStyle(.red).tracking(0.5)
                Spacer()
            }

            HStack(spacing: 14) {
                Circle()
                    .fill(LinearGradient(colors: [Color.red.opacity(0.2), Color.orange.opacity(0.1)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text(patient.name.prefix(1))
                            .font(.title2.bold()).foregroundStyle(.red)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text(patient.name).font(.headline)
                    Text("Matrícula: \(patient.identifier)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            // Tags from API
            if let tags = patient.tags, !tags.isEmpty {
                ClinicalFlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in ClinicalTagBadge(tag: tag) }
                }
            }
        }
        .padding(18)
        .background(LinearGradient(
            colors: [Color.red.opacity(0.04), Color(UIColor.secondarySystemGroupedBackground)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.red.opacity(0.25), lineWidth: 1.5))
    }
}

// MARK: - Patients Tab

struct DoctorPatientsTab: View {
    @State private var patients: [APIPatient] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMsg: String?

    private var filtered: [APIPatient] {
        guard !searchText.isEmpty else { return patients }
        return patients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.identifier.contains(searchText)
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando pacientes…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMsg {
                ContentUnavailableView(
                    "Sin conexión",
                    systemImage: "wifi.slash",
                    description: Text(errorMsg)
                )
            } else {
                List {
                    ForEach(filtered) { patient in
                        NavigationLink {
                            APIPatientDetailView(patient: patient)
                        } label: {
                            DoctorPatientRow(patient: patient)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Nombre o matrícula")
                .overlay {
                    if filtered.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
        }
        .task { await loadPatients() }
        .refreshable { await loadPatients() }
    }

    private func loadPatients() async {
        isLoading = true
        errorMsg = nil
        do {
            patients = try await ClinicianService.shared.fetchPatients()
        } catch {
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }
}

struct DoctorPatientRow: View {
    let patient: APIPatient

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.indigo.opacity(0.2), Color.purple.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(patient.name.prefix(1))
                            .font(.system(size: 20, weight: .bold)).foregroundStyle(.indigo)
                    )
                if patient.isCritical {
                    Circle().fill(Color.red).frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 7, weight: .black)).foregroundStyle(.white)
                        )
                        .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 1.5))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(patient.name).font(.headline)
                    Spacer()
                    statusBadge
                }
                Text("Matrícula: \(patient.identifier)")
                    .font(.subheadline).foregroundStyle(.secondary)
                if let tags = patient.tags, !tags.isEmpty {
                    Text(tags.prefix(2).joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private var statusBadge: some View {
        let (label, color): (String, Color) = {
            switch patient.status {
            case "crisis":    return ("Crisis", Color.red)
            case "attention": return ("Atención", Color.orange)
            default:          return ("Estable", Color.green)
            }
        }()
        Text(label)
            .font(.caption.bold()).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.1)).clipShape(Capsule())
    }
}

// MARK: - Patient Detail View (API-driven)

struct APIPatientDetailView: View {
    let patient: APIPatient
    @State private var detail: APIPatientDetail?
    @State private var isLoading = true
    @State private var noteText = ""
    @State private var isSaved = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            if isLoading {
                ProgressView("Cargando perfil…")
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let d = detail {
                detailContent(d)
            } else {
                ContentUnavailableView(
                    "No disponible",
                    systemImage: "person.fill.questionmark",
                    description: Text("No se pudo cargar el perfil del paciente.")
                )
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(patient.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDetail() }
    }

    private func loadDetail() async {
        isLoading = true
        detail = try? await ClinicianService.shared.fetchPatientDetail(id: patient.id)
        isLoading = false
    }

    @ViewBuilder private func detailContent(_ d: APIPatientDetail) -> some View {
        VStack(spacing: 16) {
            // Crisis banner
            if d.isCritical {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Alerta de crisis activa").font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(14)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            }

            // Mood trend chart
            if !d.moodHistory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Tendencia · \(d.moodHistory.count) días",
                          systemImage: "waveform.path.ecg.rectangle.fill")
                        .font(.headline)
                    Chart {
                        ForEach(Array(d.moodHistory.enumerated()), id: \.offset) { i, pt in
                            AreaMark(x: .value("Día", i), yStart: .value("Min", 0), yEnd: .value("Score", pt.value))
                                .foregroundStyle(LinearGradient(
                                    colors: [Color.indigo.opacity(0.25), .clear],
                                    startPoint: .top, endPoint: .bottom
                                ))
                                .interpolationMethod(.catmullRom)
                            LineMark(x: .value("Día", i), y: .value("Score", pt.value))
                                .foregroundStyle(Color.indigo)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                                .interpolationMethod(.catmullRom)
                        }
                        RuleMark(y: .value("Umbral", 4))
                            .foregroundStyle(Color.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    }
                    .chartYScale(domain: 0...10)
                    .chartXAxis(.hidden)
                    .frame(height: 140)
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
            }

            // Questionnaire scores
            if let q = d.latestQuestionnaires, q.phq9Score != nil || q.gad7Score != nil {
                HStack(spacing: 12) {
                    if let phq = q.phq9Score {
                        ScoreCard(label: "PHQ-9", score: phq, max: 27, thresholds: (5, 10, 15))
                    }
                    if let gad = q.gad7Score {
                        ScoreCard(label: "GAD-7", score: gad, max: 21, thresholds: (5, 10, 15))
                    }
                }
                .padding(.horizontal, 20)
            }

            // AI Summary
            VStack(alignment: .leading, spacing: 14) {
                Label("Síntesis de IA · On-Device", systemImage: "brain.head.profile")
                    .font(.headline)
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.indigo).frame(width: 3)
                    Text(d.displaySummary)
                        .font(.body).foregroundStyle(Color.primary.opacity(0.85)).lineSpacing(4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(
                    colors: [Color.indigo.opacity(0.06), Color.purple.opacity(0.03)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.indigo.opacity(0.12), lineWidth: 1))

                if !d.tags.isEmpty {
                    Text("Etiquetas de Análisis").font(.headline).foregroundStyle(.secondary)
                    ClinicalFlowLayout(spacing: 10) {
                        ForEach(d.tags, id: \.self) { tag in ClinicalTagBadge(tag: tag) }
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)

            // Private notes
            VStack(alignment: .leading, spacing: 14) {
                Text("Notas Privadas").font(.headline)
                ZStack(alignment: .topLeading) {
                    if noteText.isEmpty {
                        Text("Escribe tus observaciones pre-sesión aquí…")
                            .foregroundStyle(.tertiary).padding(.horizontal, 8).padding(.vertical, 12)
                    }
                    TextEditor(text: $noteText)
                        .frame(minHeight: 150).scrollContentBackground(.hidden)
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: noteText) { isSaved = false }

                if isSaved {
                    Label("Notas guardadas", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold()).foregroundStyle(.green).transition(.opacity)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { isSaved = true }
                } label: {
                    Label("Guardar Notas", systemImage: "square.and.arrow.down")
                        .fontWeight(.bold).frame(maxWidth: .infinity).padding()
                        .background(Color.indigo).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .sensoryFeedback(.success, trigger: isSaved)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)

            Spacer(minLength: 50)
        }
        .padding(.top, 16)
        .animation(.easeInOut(duration: 0.25), value: isSaved)
    }
}

// MARK: - Agenda Tab (API-driven)

struct DoctorAgendaTab: View {
    @State private var appointments: [APIClinicianAppointment] = []
    @State private var selectedDate = Date()
    @State private var isLoading = true

    private var appointmentsForSelected: [APIClinicianAppointment] {
        appointments.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var upcomingGrouped: [(Date, [APIClinicianAppointment])] {
        let upcoming = appointments.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
        let grouped = Dictionary(grouping: upcoming) { appt in
            Calendar.current.startOfDay(for: appt.date)
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando agenda…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appointments.isEmpty {
                ContentUnavailableView(
                    "Sin citas agendadas",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("No hay sesiones próximas en el sistema.")
                )
            } else {
                agendaList
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .task { await loadAgenda() }
        .refreshable { await loadAgenda() }
    }

    private var agendaList: some View {
        List {
            ForEach(upcomingGrouped, id: \.0) { date, appts in
                Section(header: Text(date, style: .date).font(.headline)) {
                    ForEach(appts) { appt in
                        AgendaRow(appointment: appt)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func loadAgenda() async {
        isLoading = true
        appointments = (try? await ClinicianService.shared.fetchAppointments()) ?? []
        isLoading = false
    }
}

struct AgendaRow: View {
    let appointment: APIClinicianAppointment

    private var typeColor: Color {
        switch appointment.sessionType {
        case "crisis":    return .red
        case "evaluation": return .teal
        case "firstVisit": return .orange
        default:           return .indigo
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Time column
            VStack(spacing: 2) {
                Text(appointment.timeString)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(typeColor)
                Circle().fill(typeColor).frame(width: 6, height: 6)
            }
            .frame(width: 60)

            // Detail
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(appointment.patientName).font(.headline)
                    Spacer()
                    if let status = appointment.status {
                        let statusColor: Color = status == "completed" ? .green : status == "cancelled" ? .secondary : .blue
                        Text(status.capitalized)
                            .font(.caption.bold()).foregroundStyle(statusColor)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(statusColor.opacity(0.1)).clipShape(Capsule())
                    }
                }
                if let notes = appointment.notes, !notes.isEmpty {
                    Text(notes).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                }
                Text("\(appointment.durationMinutes) minutos")
                    .font(.caption).foregroundStyle(.secondary)
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
                            .fill(LinearGradient(
                                colors: [Color.indigo.opacity(0.2), Color.purple.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 58, height: 58)
                        Text("DR")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.indigo)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dra. Laura Rivera").font(.headline)
                        Text("Psicología clínica · CBT · Adolescentes")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Label("Portal activo", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Sistema") {
                Label("MIND-LINK Portal Clínico", systemImage: "brain.filled.head.profile")
                    .foregroundStyle(Color.indigo)
                Label("IA On-Device · Activa", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Label("v1.0 · UANL · 2025", systemImage: "info.circle")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) { showLogoutAlert = true } label: {
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
