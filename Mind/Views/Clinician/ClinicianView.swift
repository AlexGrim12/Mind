import SwiftUI
import SwiftData

struct ClinicianView: View {
    @AppStorage("sharesMood")           private var sharesMood = true
    @AppStorage("sharesQuestionnaires") private var sharesQuestionnaires = true
    @AppStorage("sharesTopics")         private var sharesTopics = true
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
            ZStack { Theme.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Perfil animado
                        ClinicianProfileCard(
                            name: clinicianName,
                            specialty: clinicianSpec,
                            onViewDashboard: { showDashboard = true }
                        )
                        .staggered(0, base: 0)

                        // Qué ve
                        SharingControlCard(
                            sharesMood: $sharesMood,
                            sharesQuestionnaires: $sharesQuestionnaires,
                            sharesTopics: $sharesTopics
                        )
                        .staggered(1, base: 0)

                        // Vista previa de lo que ve el psicólogo
                        ClinicalPreviewCard(
                            sharesMood: sharesMood,
                            sharesQuestionnaires: sharesQuestionnaires,
                            sharesTopics: sharesTopics
                        )
                        .staggered(2, base: 0)

                        // Historial
                        SnapshotHistoryCard(snapshots: snapshots)
                            .staggered(3, base: 0)

                        // Desvincular
                        Button(role: .destructive) {
                            Haptics.warning()
                            showUnlinkAlert = true
                        } label: {
                            Label("Desvincular psicólogo", systemImage: "person.fill.xmark")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.systemRed).opacity(0.08))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                        }
                        .pressEffect()
                        .staggered(4, base: 0)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20).padding(.top, 16)
                }
            }
            .navigationTitle("Mi psicólogo")
        }
        .sheet(isPresented: $showDashboard) { ClinicianDashboardView() }
        .alert("¿Desvincular?", isPresented: $showUnlinkAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Desvincular", role: .destructive) { }
        } message: {
            Text("Tu psicólogo dejará de recibir actualizaciones. Puedes reconectarte después.")
        }
    }
}

// MARK: — Profile card con pulse

struct ClinicianProfileCard: View {
    let name: String
    let specialty: String
    let onViewDashboard: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Theme.moodGreen.opacity(0.3), lineWidth: 2)
                        .frame(width: 72, height: 72)
                        .scaleEffect(pulse ? 1.12 : 1)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)

                    Circle()
                        .fill(LinearGradient(colors: [Theme.accent, Theme.moodPurple],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 68, height: 68)

                    Text("DR").font(.title2.bold()).foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(name).font(.headline).foregroundStyle(Theme.textPrimary)
                    Text(specialty).font(.caption).foregroundStyle(Theme.secondaryText)
                    HStack(spacing: 5) {
                        Circle().fill(Theme.moodGreen).frame(width: 8, height: 8)
                        Text("Vinculado · activo").font(.caption.bold()).foregroundStyle(Theme.moodGreen)
                    }
                }
                Spacer()
            }

            // Ver portal
            Button(action: { Haptics.impact(.light); onViewDashboard() }) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("Ver portal del psicólogo")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .pressEffect()
        }
        .cardStyle()
        .onAppear { pulse = true }
    }
}

// MARK: — Sharing control

struct SharingControlCard: View {
    @Binding var sharesMood: Bool
    @Binding var sharesQuestionnaires: Bool
    @Binding var sharesTopics: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("¿Qué ve mi psicólogo?").font(.headline)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
            }

            VStack(spacing: 0) {
                SharingRow(icon: "chart.line.uptrend.xyaxis", color: Theme.moodBlue,
                           title: "Tendencia de ánimo", subtitle: "Gráfica numérica · no texto",
                           isOn: $sharesMood)
                Divider().padding(.leading, 54)
                SharingRow(icon: "list.clipboard.fill", color: Theme.moodGreen,
                           title: "Cuestionarios", subtitle: "PHQ-9 / GAD-7",
                           isOn: $sharesQuestionnaires)
                Divider().padding(.leading, 54)
                SharingRow(icon: "tag.fill", color: Theme.moodPurple,
                           title: "Temas del diario", subtitle: "Anonimizados, sin texto crudo",
                           isOn: $sharesTopics)
            }
        }
        .cardStyle()
    }
}

struct SharingRow: View {
    let icon: String; let color: Color
    let title: String; let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOn ? color : Color(.systemGray5))
                    .frame(width: 34, height: 34)
                    .animation(.springy, value: isOn)
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(isOn ? .white : Theme.secondaryText)
                    .animation(.springy, value: isOn)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                    .foregroundStyle(isOn ? Theme.textPrimary : Theme.secondaryText)
                    .animation(.smooth, value: isOn)
                Text(subtitle).font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Toggle("", isOn: $isOn).tint(color).labelsHidden()
                .onChange(of: isOn) { _, _ in Haptics.selection() }
        }
        .padding(.vertical, 12)
    }
}

// MARK: — Vista previa de lo que ve el psicólogo

struct ClinicalPreviewCard: View {
    let sharesMood: Bool
    let sharesQuestionnaires: Bool
    let sharesTopics: Bool
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Vista previa · lo que ve Dra. Rivera", systemImage: "eye")
                    .font(.caption.bold()).foregroundStyle(Theme.secondaryText)
                Spacer()
            }

            if !sharesMood && !sharesQuestionnaires && !sharesTopics {
                HStack(spacing: 10) {
                    Image(systemName: "eye.slash").foregroundStyle(Theme.secondaryText)
                    Text("El psicólogo no ve nada actualmente.")
                        .font(.subheadline).foregroundStyle(Theme.secondaryText)
                }
            } else {
                VStack(spacing: 10) {
                    if sharesMood {
                        PreviewPill(icon: "chart.line.uptrend.xyaxis",
                                    text: "Tendencia: ↑ 6.2 promedio esta semana",
                                    color: Theme.moodBlue)
                        .transition(.scale.combined(with: .opacity))
                    }
                    if sharesQuestionnaires {
                        PreviewPill(icon: "list.clipboard",
                                    text: "PHQ-9: 8 · GAD-7: 11",
                                    color: Theme.moodGreen)
                        .transition(.scale.combined(with: .opacity))
                    }
                    if sharesTopics {
                        PreviewPill(icon: "tag",
                                    text: "Temas: Sueño · Relaciones · Estudios",
                                    color: Theme.moodPurple)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.springy, value: sharesMood)
                .animation(.springy, value: sharesQuestionnaires)
                .animation(.springy, value: sharesTopics)
            }
        }
        .cardStyle()
    }
}

struct PreviewPill: View {
    let icon: String; let text: String; let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text).font(.caption.bold()).foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: — Historial de snapshots

struct SnapshotHistoryCard: View {
    let snapshots: [(date: String, content: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Historial compartido").font(.headline)
            ForEach(Array(snapshots.enumerated()), id: \.offset) { i, snap in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: "paperplane.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snap.date).font(.caption.bold()).foregroundStyle(Theme.textPrimary)
                        Text(snap.content).font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    HStack(spacing: 3) {
                        ForEach(0..<snap.count, id: \.self) { _ in
                            Circle().fill(Theme.moodGreen).frame(width: 6, height: 6)
                        }
                    }
                }
                .staggered(i, base: 0.05)
                if i < snapshots.count - 1 {
                    Divider()
                }
            }
        }
        .cardStyle()
    }
}
