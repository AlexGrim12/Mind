import SwiftUI
import SwiftData

struct ClinicianView: View {
    @AppStorage("sharesMood")           private var sharesMood = true
    @AppStorage("sharesQuestionnaires") private var sharesQuestionnaires = true
    @AppStorage("sharesTopics")         private var sharesTopics = true
    @AppStorage("sharesBiometrics")     private var sharesBiometrics = true
    @AppStorage("sharesSleep")          private var sharesSleep = true
    @State private var health = HealthKitService.shared
    @State private var showDashboard = false
    @State private var showUnlinkAlert = false

    private let clinicianName = "Dra. Laura Rivera"
    private let clinicianSpec = "Psicología clínica · CBT · Adolescentes"
    private let snapshots: [(date: String, content: String, count: Int)] = [
        ("12 abr", "Tendencia, cuestionarios, temas", 3),
        ("5 abr",  "Tendencia, temas", 2),
        ("29 mar", "Tendencia", 1),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // Perfil del Maestro/Guía Zen
                    ToriiHeader(title: "Tu Guía", subtitle: "Acompañamiento profesional", kanji: "師")
                        .padding(.top, 20)

                    ClinicianProfileZenCard(
                        name: clinicianName,
                        specialty: clinicianSpec,
                        onViewDashboard: { showDashboard = true }
                    )
                    .staggered(0)

                    // Control de Consentimiento
                    SharingControlZenCard(
                        sharesMood: $sharesMood,
                        sharesQuestionnaires: $sharesQuestionnaires,
                        sharesTopics: $sharesTopics,
                        sharesBiometrics: $sharesBiometrics,
                        sharesSleep: $sharesSleep
                    )
                    .staggered(1)

                    // Lo que el Guía observa
                    ClinicalPreviewZenCard(
                        sharesMood: sharesMood,
                        sharesQuestionnaires: sharesQuestionnaires,
                        sharesTopics: sharesTopics,
                        sharesBiometrics: sharesBiometrics,
                        sharesSleep: sharesSleep,
                        snapshot: health.todaySnapshot,
                        sleep: health.lastNightSleep
                    )
                    .staggered(2)

                    // Historial de Sincronía
                    SnapshotHistoryZenCard(snapshots: snapshots)
                        .staggered(3)

                    // Desvincular con estilo sutil
                    Button(role: .destructive) {
                        Haptics.warning()
                        showUnlinkAlert = true
                    } label: {
                        Text("Cerrar vínculo temporalmente")
                            .font(.system(.caption, design: .serif).bold())
                            .foregroundStyle(Theme.aka.opacity(0.8))
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Theme.aka.opacity(0.05))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.aka.opacity(0.2), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 20)
                    .staggered(4)

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
            }
            .screenBackground()
            .navigationTitle("Psicólogo · 師")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { if health.todaySnapshot == nil { await health.fetchAll() } }
        .sheet(isPresented: $showDashboard) { ClinicianDashboardView() }
        .alert("¿Cerrar vínculo?", isPresented: $showUnlinkAlert) {
            Button("Mantener", role: .cancel) { }
            Button("Confirmar", role: .destructive) { }
        } message: {
            Text("Tu guía dejará de recibir el flujo de tu energía hasta que decidas reconectar.")
        }
    }
}

// MARK: — Clinician Profile Zen

struct ClinicianProfileZenCard: View {
    let name: String
    let specialty: String
    let onViewDashboard: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                ZStack {
                    EnsoCircle(color: Theme.matcha, lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulse ? 1.05 : 1.0)
                    
                    Text("師")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.sumi)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(.system(.headline, design: .serif))
                    Text(specialty).font(.system(.caption, design: .serif)).foregroundStyle(Theme.sumiSoft)
                    
                    HStack(spacing: 6) {
                        Circle().fill(Theme.matcha).frame(width: 6, height: 6)
                        Text("Vínculo Activo").font(.system(.caption2, design: .serif).bold()).foregroundStyle(Theme.matchaDeep)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.matcha.opacity(0.1), in: Capsule())
                }
                Spacer()
            }

            Button(action: { Haptics.impact(.light); onViewDashboard() }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Explorar Portal Clínico")
                        .font(.system(.subheadline, design: .serif).weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .cardStyle()
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

// MARK: — Sharing Control Zen

struct SharingControlZenCard: View {
    @Binding var sharesMood: Bool
    @Binding var sharesQuestionnaires: Bool
    @Binding var sharesTopics: Bool
    @Binding var sharesBiometrics: Bool
    @Binding var sharesSleep: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Flujo de Información").font(.system(.headline, design: .serif))
                Spacer()
                HankoStamp(kanji: "信", color: Theme.ai, size: 24) // "Trust"
            }

            VStack(spacing: 0) {
                SharingZenRow(kanji: "心", title: "Ánimo", subtitle: "Tendencias numéricas", isOn: $sharesMood)
                Divider().background(Theme.inkLine).padding(.leading, 44)
                SharingZenRow(kanji: "問", title: "Consultas", subtitle: "PHQ-9 / GAD-7", isOn: $sharesQuestionnaires)
                Divider().background(Theme.inkLine).padding(.leading, 44)
                SharingZenRow(kanji: "題", title: "Temas", subtitle: "Conceptos clave", isOn: $sharesTopics)
                Divider().background(Theme.inkLine).padding(.leading, 44)
                SharingZenRow(kanji: "脈", title: "Vitalidad", subtitle: "Biométricos básicos", isOn: $sharesBiometrics)
                Divider().background(Theme.inkLine).padding(.leading, 44)
                SharingZenRow(kanji: "眠", title: "Sueño", subtitle: "Calidad del descanso", isOn: $sharesSleep)
            }
        }
        .cardStyle()
    }
}

struct SharingZenRow: View {
    let kanji: String
    let title: String; let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text(kanji)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(isOn ? Theme.ai : Theme.sumiSoft)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(.subheadline, design: .serif).weight(.bold))
                    .foregroundStyle(isOn ? Theme.textPrimary : Theme.sumiSoft)
                Text(subtitle).font(.system(.caption2, design: .serif)).foregroundStyle(Theme.sumiSoft.opacity(0.8))
            }
            Spacer()
            Toggle("", isOn: $isOn).tint(Theme.ai).labelsHidden()
        }
        .padding(.vertical, 12)
    }
}

// MARK: — Clinical Preview Zen

struct ClinicalPreviewZenCard: View {
    let sharesMood: Bool
    let sharesQuestionnaires: Bool
    let sharesTopics: Bool
    let sharesBiometrics: Bool
    let sharesSleep: Bool
    let snapshot: BiometricSnapshot?
    let sleep: SleepSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Visión del Guía").font(.system(.headline, design: .serif))
                Spacer()
                Image(systemName: "eye.fill").foregroundStyle(Theme.sumiSoft)
            }

            VStack(spacing: 10) {
                if sharesMood { PreviewZenPill(kanji: "心", text: "Ritmo emocional estable", color: Theme.asagi) }
                if sharesQuestionnaires { PreviewZenPill(kanji: "問", text: "Cuestionarios al día", color: Theme.matchaDeep) }
                if sharesTopics { PreviewZenPill(kanji: "題", text: "Foco: Bienestar Universitario", color: Theme.moodPurple) }
                if sharesBiometrics { PreviewZenPill(kanji: "脈", text: "Signos vitales en armonía", color: Theme.aka) }
                if sharesSleep { PreviewZenPill(kanji: "眠", text: "Descanso reparador", color: Theme.ai) }
            }
        }
        .cardStyle()
    }
}

struct PreviewZenPill: View {
    let kanji: String; let text: String; let color: Color
    var body: some View {
        HStack(spacing: 12) {
            Text(kanji).font(.system(size: 14, weight: .bold, design: .serif)).foregroundStyle(color)
            Text(text).font(.system(.caption, design: .serif)).foregroundStyle(Theme.sumi)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.15), lineWidth: 0.5))
    }
}

// MARK: — Snapshot History Zen

struct SnapshotHistoryZenCard: View {
    let snapshots: [(date: String, content: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Sincronía Pasada").font(.system(.headline, design: .serif))
            
            ForEach(Array(snapshots.enumerated()), id: \.offset) { i, snap in
                HStack(spacing: 14) {
                    Circle()
                        .fill(Theme.kinari)
                        .frame(width: 32, height: 32)
                        .overlay(Text("\(i+1)").font(.system(size: 12, design: .serif)).foregroundStyle(Theme.sumiSoft))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snap.date).font(.system(.caption, design: .serif).weight(.bold))
                        Text(snap.content).font(.system(.caption2, design: .serif)).foregroundStyle(Theme.sumiSoft)
                    }
                    Spacer()
                    SakuraBlossom(size: 12)
                        .opacity(0.6)
                }
                if i < snapshots.count - 1 {
                    Divider().background(Theme.inkLine)
                }
            }
        }
        .cardStyle()
    }
}
