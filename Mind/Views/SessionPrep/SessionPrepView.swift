import SwiftUI
import SwiftData

struct SessionPrepView: View {
    let appointment: Appointment
    @Environment(\.modelContext) private var context
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]
    @AppStorage("sharesTopics") private var sharesTopics = true
    @State private var health = HealthKitService.shared
    @State private var showSessionRating = false
    @State private var activeCard: Int? = nil

    private var recentAvg: Double {
        let r = moodEntries.prefix(7)
        guard !r.isEmpty else { return 5 }
        return Double(r.map(\.score).reduce(0, +)) / Double(r.count)
    }

    private let topics = ["Presión de exámenes", "Relación con compañeros", "Calidad del sueño"]
    private let tips = [
        "Empieza contando cómo fue tu semana en una frase.",
        "Si algo te preocupa mucho, dilo pronto — no al final.",
        "Está bien decir 'no sé cómo explicarlo'.",
        "Puedes pedir que repita o explique algo."
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header con gradiente
                PrepHeroHeader(appointment: appointment)
                    .staggered(0, base: 0)

                // Card 1 — ánimo
                PrepCard(
                    index: 1, activeCard: $activeCard,
                    accentColor: Theme.moodBlue,
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Lo que sentiste esta semana"
                ) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Int(recentAvg).moodGradient)
                                .frame(width: 64, height: 64)
                                .shadow(color: Int(recentAvg).moodColor.opacity(0.35), radius: 8, y: 3)
                            VStack(spacing: 1) {
                                Text(String(format: "%.1f", recentAvg))
                                    .font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                                Text("/ 10").font(.caption2).foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Int(recentAvg).moodLabel)
                                .font(.headline).foregroundStyle(Theme.textPrimary)
                            Text("Promedio últimos 7 días")
                                .font(.caption).foregroundStyle(Theme.secondaryText)
                            HStack(spacing: 6) {
                                ForEach(moodEntries.prefix(7).reversed(), id: \.id) { e in
                                    Circle()
                                        .fill(e.score.moodColor)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .staggered(1, base: 0)

                // Card 2 — temas
                PrepCard(
                    index: 2, activeCard: $activeCard,
                    accentColor: Theme.moodGreen,
                    icon: "tag.fill",
                    title: "Temas que podrías mencionar"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(topics.enumerated()), id: \.offset) { i, topic in
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.moodGreen.opacity(0.12))
                                        .frame(width: 28, height: 28)
                                    Text("\(i + 1)")
                                        .font(.caption.bold())
                                        .foregroundStyle(Theme.moodGreen)
                                }
                                Text(topic).font(.subheadline).foregroundStyle(Theme.textPrimary)
                                Spacer()
                            }
                        }
                        Divider()
                        Toggle(isOn: $sharesTopics) {
                            Label("Compartir con mi psicólogo", systemImage: "paperplane")
                                .font(.caption.bold())
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .tint(Theme.moodGreen)
                        .onChange(of: sharesTopics) { _, _ in Haptics.selection() }
                    }
                }
                .staggered(2, base: 0)

                // Card 3 — tips
                PrepCard(
                    index: 3, activeCard: $activeCard,
                    accentColor: Theme.moodYellow,
                    icon: "lightbulb.fill",
                    title: "Cómo aprovechar los \(appointment.duration.minutes) minutos"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(tips.enumerated()), id: \.offset) { i, tip in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.moodYellow)
                                    .font(.body)
                                Text(tip).font(.subheadline).foregroundStyle(Theme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .staggered(i, base: 0.3)
                        }
                    }
                }
                .staggered(3, base: 0)

                // Card 4 — Biométricos para la sesión
                if health.todaySnapshot != nil || health.lastNightSleep != nil {
                    PrepCard(
                        index: 4, activeCard: $activeCard,
                        accentColor: .red,
                        icon: "heart.text.clipboard",
                        title: "Tu estado físico hoy"
                    ) {
                        SessionBiometricsContent(snap: health.todaySnapshot,
                                                 sleep: health.lastNightSleep)
                    }
                    .staggered(4, base: 0)
                }

                // SRS post-sesión
                if appointment.isPast {
                    Button {
                        Haptics.impact(.medium)
                        showSessionRating = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "star.bubble.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Valorar la sesión")
                                    .font(.headline).foregroundStyle(.white)
                                Text("30 segundos · 4 preguntas")
                                    .font(.caption).foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(18)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                    }
                    .pressEffect()
                    .staggered(4, base: 0)
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20).padding(.top, 0)
        }
        .screenBackground()
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .task { if health.todaySnapshot == nil { await health.fetchAll() } }
        .sheet(isPresented: $showSessionRating) {
            SessionRatingView(appointment: appointment)
        }
    }
}

// MARK: — Hero header de sesión

struct PrepHeroHeader: View {
    let appointment: Appointment
    @State private var appeared = false

    private var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: appointment.date).day ?? 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fondo
            LinearGradient(
                colors: [Color(hex: "#1a3a5c"), Theme.accent],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            // Círculos decorativos
            Circle().fill(.white.opacity(0.06)).frame(width: 130).offset(x: 80, y: -30)
            Circle().fill(.white.opacity(0.04)).frame(width: 90).offset(x: -100, y: 20)

            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Sesión con")
                            .font(.caption).foregroundStyle(.white.opacity(0.8))
                        Text(appointment.clinicianName)
                            .font(.title2.bold()).foregroundStyle(.white)
                        Text(appointment.formattedDate)
                            .font(.subheadline).foregroundStyle(.white.opacity(0.75))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.springy.delay(0.1), value: appeared)

                    Spacer()

                    // Badge de countdown
                    VStack(spacing: 2) {
                        Text(daysUntil <= 0 ? "Hoy" : "\(daysUntil)")
                            .font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
                        if daysUntil > 0 {
                            Text("días").font(.caption).foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(14)
                    .background(.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .scaleEffect(appeared ? 1 : 0.5)
                    .animation(.bouncy.delay(0.2), value: appeared)
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: — PrepCard expandible

struct PrepCard<Content: View>: View {
    let index: Int
    @Binding var activeCard: Int?
    let accentColor: Color
    let icon: String
    let title: String
    @ViewBuilder let content: Content

    @State private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header tocable
            Button {
                Haptics.selection()
                withAnimation(.springy) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(accentColor.opacity(0.12)).frame(width: 36, height: 36)
                        Image(systemName: icon).foregroundStyle(accentColor).font(.subheadline.bold())
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Paso \(index)")
                            .font(.caption.bold()).foregroundStyle(accentColor)
                        Text(title)
                            .font(.headline).foregroundStyle(Theme.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.secondaryText)
                        .rotationEffect(.degrees(expanded ? 0 : -90))
                        .animation(.springy, value: expanded)
                }
                .padding(18)
            }
            .buttonStyle(.plain)

            if expanded {
                Divider().padding(.horizontal, 18)
                content
                    .padding(18)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 4)
    }
}

// MARK: — Session Rating (SRS)

struct SessionRatingView: View {
    let appointment: Appointment
    @Environment(\.dismiss) private var dismiss

    @State private var relationship: Double = 7
    @State private var goals: Double = 7
    @State private var approach: Double = 7
    @State private var overall: Double = 7
    @State private var saved = false

    var average: Double { (relationship + goals + approach + overall) / 4 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientBackground
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Average live
                        ZStack {
                            Circle()
                                .stroke(Int(average).moodColor.opacity(0.15), lineWidth: 10)
                                .frame(width: 100, height: 100)
                            Circle()
                                .trim(from: 0, to: average / 10)
                                .stroke(Int(average).moodGradient,
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.springy, value: average)
                            VStack(spacing: 0) {
                                Text(String(format: "%.1f", average))
                                    .font(.title2.bold())
                                    .foregroundStyle(Int(average).moodColor)
                                    .contentTransition(.numericText())
                                    .animation(.smooth, value: average)
                                Text("/ 10").font(.caption2).foregroundStyle(Theme.secondaryText)
                            }
                        }
                        .padding(.top, 16)

                        Text("¿Cómo fue la sesión?")
                            .font(.title2.bold())

                        VStack(spacing: 16) {
                            AnimatedSRSSlider(label: "Me sentí escuchado/a", value: $relationship)
                                .staggered(0)
                            AnimatedSRSSlider(label: "Hablamos de lo que quería", value: $goals)
                                .staggered(1)
                            AnimatedSRSSlider(label: "El enfoque fue bueno para mí", value: $approach)
                                .staggered(2)
                            AnimatedSRSSlider(label: "¿Cómo salgo en general?", value: $overall)
                                .staggered(3)
                        }
                        .padding(.horizontal, 20)

                        Button {
                            Haptics.success()
                            withAnimation(.springy) { saved = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                        } label: {
                            HStack(spacing: 8) {
                                if saved { Image(systemName: "checkmark") }
                                Text(saved ? "Guardado" : "Guardar valoración")
                            }
                            .primaryButton(color: saved ? Theme.moodGreen : Theme.accent)
                        }
                        .pressEffect()
                        .padding(.horizontal, 20)
                        .animation(.springy, value: saved)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Valoración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Omitir") { dismiss() }
                }
            }
        }
    }
}

struct AnimatedSRSSlider: View {
    let label: String
    @Binding var value: Double
    @State private var prevValue: Double = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label).font(.subheadline).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(String(format: "%.0f", value))
                    .font(.headline.bold())
                    .foregroundStyle(Int(value).moodColor)
                    .contentTransition(.numericText())
                    .animation(.smooth, value: value)
            }
            HStack(spacing: 8) {
                Text("😞").font(.caption)
                Slider(value: $value, in: 0...10, step: 1)
                    .tint(Int(value).moodColor)
                    .animation(.smooth, value: value)
                    .onChange(of: value) { _, _ in Haptics.selection() }
                Text("🤩").font(.caption)
            }
        }
        .padding(16)
        .cardStyle(padding: 0)
    }
}


// MARK: — Biometrics content inside PrepCard

struct SessionBiometricsContent: View {
    let snap: BiometricSnapshot?
    let sleep: SleepSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Stress level from HRV
            if let hrv = snap?.hrv {
                let (label, color): (String, Color) = hrv > 50
                    ? ("Sistema nervioso equilibrado — buena sesión hoy", Theme.moodGreen)
                    : hrv > 30
                    ? ("Algo de tensión — menciónalo al inicio", Theme.moodYellow)
                    : ("Estrés elevado — la sesión puede ayudar mucho", .red)
                HStack(spacing: 10) {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(color).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label).font(.subheadline.bold()).foregroundStyle(color)
                        Text(String(format: "HRV: %.0f ms", hrv))
                            .font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                }
                .padding(12).background(color.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Sleep quality
            if let s = sleep {
                let sleepColor: Color = s.quality == .excellent || s.quality == .good
                    ? Theme.moodGreen : Theme.moodYellow
                HStack(spacing: 10) {
                    Image(systemName: s.quality.icon).foregroundStyle(sleepColor).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dormiste \(s.formattedTotal) · \(s.quality.rawValue)")
                            .font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
                        Text(s.quality == .poor || s.quality == .fair
                             ? "El sueño insuficiente puede afectar cómo procesas la sesión."
                             : "Buen descanso. Estarás más receptivo/a hoy.")
                            .font(.caption).foregroundStyle(Theme.secondaryText).lineSpacing(2)
                    }
                }
                .padding(12).background(sleepColor.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Quick metrics row
            if let snap {
                HStack(spacing: 16) {
                    if let rhr = snap.restingHeartRate {
                        MiniMetric(label: "FC reposo", value: "\(Int(rhr)) bpm", color: .red)
                    }
                    if let o2 = snap.oxygenSaturation {
                        MiniMetric(label: "SpO₂", value: String(format: "%.0f%%", o2), color: Theme.moodBlue)
                    }
                    MiniMetric(label: "Pasos", value: "\(snap.steps)", color: Theme.moodGreen)
                }
            }

            if snap == nil && sleep == nil {
                Text("Abre Apple Health para ver tus datos biométricos de hoy.")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
            }
        }
    }
}

struct MiniMetric: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
