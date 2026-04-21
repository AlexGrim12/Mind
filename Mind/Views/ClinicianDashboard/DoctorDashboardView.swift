import SwiftUI
import Charts

// MARK: - Root

struct DoctorDashboardView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userRole") private var userRole = ""
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    DoctorHomeTab()
                        .navigationTitle("Portal · 師")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                DoctorLogoutButton(onLogout: logout)
                            }
                        }
                }
                .tabItem { 
                    Label("Inicio · 今日", systemImage: selectedTab == 0 ? "house.fill" : "house") 
                }
                .tag(0)

                NavigationStack {
                    DoctorPatientsTab()
                        .navigationTitle("Alumnos · 徒")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem { 
                    Label("Alumnos", systemImage: "person.2.fill") 
                }
                .tag(1)

                NavigationStack {
                    iPadClinicalCalendarZenView()
                        .navigationTitle("Agenda · 契")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem { 
                    Label("Agenda", systemImage: "calendar") 
                }
                .tag(2)

                NavigationStack {
                    DoctorSettingsTab(onLogout: logout)
                        .navigationTitle("Ajustes · 設")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem { 
                    Label("Ajustes", systemImage: "gearshape.fill") 
                }
                .tag(3)
            }
            .tint(Theme.ai)
        }
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
            HankoStamp(kanji: "出", color: Theme.aka.opacity(0.8), size: 28)
        }
        .alert("¿Cerrar sesión?", isPresented: $showAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Salir", role: .destructive) { onLogout() }
        } message: {
            Text("Se cerrará el acceso al portal clínico.")
        }
    }
}

// MARK: - Dashboard Tab

struct DoctorHomeTab: View {
    @State private var reviewPatient: ClinicalPatient?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {

                // Header Zen
                ToriiHeader(title: "Dra. Laura Rivera", subtitle: "Portal de Acompañamiento", kanji: "師")
                    .padding(.top, 20)

                // Summary stats
                HStack(spacing: 12) {
                    ClinicalSummaryZenCard(title: "Alumnos", value: "24", kanji: "徒", color: Theme.ai)
                    ClinicalSummaryZenCard(title: "Sesiones", value: "6", kanji: "会", color: Theme.matchaDeep)
                    ClinicalSummaryZenCard(title: "Alertas", value: "3", kanji: "急", color: Theme.aka)
                }
                .padding(.horizontal, 20)

                // Priority alert
                VStack(alignment: .leading, spacing: 16) {
                    zenSectionHeader(title: "Atención Necesaria", subtitle: "Prioridad en el camino")
                    
                    ClinicalPriorityAlertZenCard(
                        name: "Sofía M.",
                        matricula: "31920442",
                        description: "Tendencia de ánimo en descenso significativo.",
                        tags: ["Ansiedad", "Insomnio"],
                        time: "5 min",
                        action: { reviewPatient = ClinicalPatient.mockSofia }
                    )
                    .padding(.horizontal, 20)
                }

                // Today's sessions
                VStack(alignment: .leading, spacing: 16) {
                    zenSectionHeader(title: "Encuentros de Hoy", subtitle: "Agenda de sincronía")

                    VStack(spacing: 12) {
                        ClinicalSessionZenRow(name: "Sofía M.",   time: "09:00", detail: "Crisis", color: Theme.aka)
                        ClinicalSessionZenRow(name: "Carlos T.",  time: "10:30", detail: "Seguimiento", color: Theme.ai)
                        ClinicalSessionZenRow(name: "Ana P.",     time: "12:00", detail: "Progreso", color: Theme.matchaDeep)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
        }
        .screenBackground()
        .navigationDestination(item: $reviewPatient) { patient in
            iPadPatientDetailZenView(patient: patient)
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
        ZStack {
            Theme.ambientBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar zen
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.sumiSoft)
                    TextField("Buscar alumno...", text: $searchText)
                        .font(.system(.body, design: .serif))
                }
                .padding(12)
                .background(Theme.cardBackground.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.inkLine, lineWidth: 0.5))
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { patient in
                            NavigationLink {
                                iPadPatientDetailZenView(patient: patient)
                            } label: {
                                DoctorPatientZenRow(patient: patient)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
        }
    }
}

struct DoctorPatientZenRow: View {
    let patient: ClinicalPatient
    private var isCritical: Bool { (patient.moodTrend.last?.value ?? 5) <= 4 }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                EnsoCircle(color: isCritical ? Theme.aka : Theme.ai, lineWidth: 1.5)
                    .frame(width: 48, height: 48)
                Text(patient.name.prefix(1))
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.sumi)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(patient.name)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                Text("ID: \(patient.matricula)")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(Theme.sumiSoft)
            }
            Spacer()
            
            if isCritical {
                HankoStamp(kanji: "急", color: Theme.aka, size: 24)
            } else {
                SakuraBlossom(size: 16).opacity(0.4)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(Theme.sumiSoft)
        }
        .cardStyle()
    }
}

// MARK: - Settings Tab

struct DoctorSettingsTab: View {
    var onLogout: () -> Void
    @State private var showLogoutAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Perfil
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Theme.ai.opacity(0.1)).frame(width: 80, height: 80)
                        EnsoCircle(color: Theme.ai, lineWidth: 2).frame(width: 80, height: 80)
                        Text("師").font(.system(size: 32, weight: .bold, design: .serif)).foregroundStyle(Theme.sumi)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Dra. Laura Rivera")
                            .font(.system(.title3, design: .serif).bold())
                        Text("Psicología Clínica")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(Theme.sumiSoft)
                    }
                    
                    HankoStamp(kanji: "印", color: Theme.matchaDeep, size: 32)
                }
                .cardStyle()
                .padding(.top, 20)

                // Info
                VStack(spacing: 0) {
                    SettingZenRow(icon: "brain", title: "MIND-LINK Portal", value: "v1.0")
                    Divider().background(Theme.inkLine).padding(.leading, 50)
                    SettingZenRow(icon: "shield.checkered", title: "Seguridad", value: "Activa")
                    Divider().background(Theme.inkLine).padding(.leading, 50)
                    SettingZenRow(icon: "heart.text.clipboard", title: "Institución", value: "FI - UNAM")
                }
                .cardStyle()

                // Salida
                Button(action: { showLogoutAlert = true }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Cerrar Sesión")
                            .font(.system(.subheadline, design: .serif).bold())
                    }
                    .foregroundStyle(Theme.aka)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.aka.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.aka.opacity(0.2), lineWidth: 0.5))
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .screenBackground()
        .alert("¿Deseas retirarte?", isPresented: $showLogoutAlert) {
            Button("Permanecer", role: .cancel) { }
            Button("Salir", role: .destructive) { onLogout() }
        } message: {
            Text("Tu sesión será cerrada con respeto.")
        }
    }
}

struct SettingZenRow: View {
    let icon: String; let title: String; let value: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).foregroundStyle(Theme.ai).frame(width: 24)
            Text(title).font(.system(.subheadline, design: .serif))
            Spacer()
            Text(value).font(.system(.caption, design: .serif).bold()).foregroundStyle(Theme.sumiSoft)
        }
        .padding(.vertical, 14)
    }
}

// MARK: — Zen Dashboard Helpers

struct ClinicalSummaryZenCard: View {
    let title: String; let value: String; let kanji: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(kanji).font(.system(size: 16, weight: .bold, design: .serif)).foregroundStyle(color)
                Spacer()
                Circle().fill(color.opacity(0.2)).frame(width: 8, height: 8)
            }
            Text(value).font(.system(size: 28, weight: .black, design: .serif)).foregroundStyle(Theme.sumi)
            Text(title).font(.system(.caption2, design: .serif).bold()).foregroundStyle(Theme.sumiSoft).lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.inkLine, lineWidth: 0.5))
    }
}

struct ClinicalPriorityAlertZenCard: View {
    let name: String; let matricula: String; let description: String
    let tags: [String]; let time: String; var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HankoStamp(kanji: "急", color: Theme.aka, size: 24)
                Text("ATENCIÓN URGENTE").font(.system(.caption, design: .serif).bold()).foregroundStyle(Theme.aka).tracking(1)
                Spacer()
                Text(time).font(.system(.caption2, design: .serif)).foregroundStyle(Theme.sumiSoft)
            }
            
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.aka.opacity(0.1)).frame(width: 44, height: 44)
                    Text(name.prefix(1)).font(.system(.headline, design: .serif)).foregroundStyle(Theme.aka)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(.headline, design: .serif))
                    Text(description).font(.system(.caption, design: .serif)).foregroundStyle(Theme.sumiSoft).lineLimit(1)
                }
            }
            
            Button(action: action) {
                Text("Revisar Síntesis")
                    .font(.system(.caption, design: .serif).bold())
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Theme.primaryGradient)
                    .clipShape(Capsule())
            }
        }
        .cardStyle()
    }
}

struct ClinicalSessionZenRow: View {
    let name: String; let time: String; let detail: String; let color: Color
    var body: some View {
        HStack(spacing: 16) {
            Text(time).font(.system(.subheadline, design: .monospaced).bold()).foregroundStyle(Theme.sumi).frame(width: 50)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(.subheadline, design: .serif).bold())
                Text(detail).font(.system(.caption2, design: .serif)).foregroundStyle(Theme.sumiSoft)
            }
            
            Spacer()
            
            Circle().fill(color).frame(width: 6, height: 6)
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Theme.sumiSoft)
        }
        .padding(14)
        .background(Theme.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.inkLine, lineWidth: 0.5))
    }
}

#Preview {
    DoctorDashboardView()
}
