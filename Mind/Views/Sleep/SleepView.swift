import SwiftUI
import Charts

struct SleepView: View {
    @State private var health = HealthKitService.shared
    @State private var selectedSummary: SleepSummary? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientBackground

                if !health.isAuthorized {
                    SleepPermissionView {
                        Task { await health.requestAuthorization() }
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {

                            // Last night hero
                            if let last = health.lastNightSleep {
                                LastNightHeroCard(summary: last)
                                    .staggered(0, base: 0)
                            } else if health.isLoading {
                                LoadingCard()
                                    .staggered(0, base: 0)
                            } else {
                                NoSleepDataCard()
                                    .staggered(0, base: 0)
                            }

                            // Weekly chart
                            if !health.weekSleepHistory.isEmpty {
                                WeeklySleepChart(history: health.weekSleepHistory,
                                                 selected: $selectedSummary)
                                    .staggered(1, base: 0)

                                // Detail when bar tapped
                                if let sel = selectedSummary {
                                    SleepDayDetail(summary: sel)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                        .staggered(0, base: 0)
                                }

                                // Stages breakdown
                                if let last = health.lastNightSleep {
                                    SleepStagesCard(summary: last)
                                        .staggered(2, base: 0)
                                }

                                // Mood correlation
                                SleepMoodTipCard(quality: health.lastNightSleep?.quality ?? .fair)
                                    .staggered(3, base: 0)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .animation(.springy, value: selectedSummary?.id)
                    }
                }
            }
            .navigationTitle("Sueño")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await health.fetchAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                    }
                }
            }
            .task {
                if !health.isAuthorized {
                    await health.requestAuthorization()
                } else {
                    await health.fetchAll()
                }
            }
        }
    }
}

// MARK: — Last night hero

struct LastNightHeroCard: View {
    let summary: SleepSummary
    @State private var appeared = false
    @State private var ringProgress: Double = 0

    private var qualityColor: Color {
        switch summary.quality {
        case .excellent: return Theme.moodGreen
        case .good:      return Theme.moodBlue
        case .fair:      return Theme.moodYellow
        case .poor:      return Theme.moodPurple
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header gradient
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [qualityColor.opacity(0.7), qualityColor.opacity(0.3)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Circle().fill(.white.opacity(0.06)).frame(width: 130).offset(x: 80, y: -20)
                Circle().fill(.white.opacity(0.04)).frame(width: 90).offset(x: -90, y: 10)

                HStack(alignment: .bottom, spacing: 20) {
                    // Ring
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 10)
                            .frame(width: 90, height: 90)
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(duration: 1.2, bounce: 0.15), value: ringProgress)
                        VStack(spacing: 1) {
                            Text(String(format: "%.1f", summary.totalHours))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            Text("horas").font(.caption2).foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .scaleEffect(appeared ? 1 : 0.5)
                    .animation(.bouncy.delay(0.1), value: appeared)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Anoche")
                            .font(.caption).foregroundStyle(.white.opacity(0.8))
                        Text(summary.quality.rawValue)
                            .font(.title2.bold()).foregroundStyle(.white)
                        if let bed = summary.bedtime, let wake = summary.wakeTime {
                            Text("\(bed.formatted(.dateTime.hour().minute())) – \(wake.formatted(.dateTime.hour().minute()))")
                                .font(.caption).foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.springy.delay(0.15), value: appeared)

                    Spacer()

                    Image(systemName: summary.quality.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.9))
                        .scaleEffect(appeared ? 1 : 0.3)
                        .animation(.bouncy.delay(0.2), value: appeared)
                }
                .padding(20)
            }

            // Insight
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(qualityColor)
                    .font(.subheadline)
                    .symbolEffect(.pulse)
                Text(summary.quality.insight)
                    .font(.caption)
                    .foregroundStyle(Theme.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(qualityColor.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.top, 10)
        }
        .onAppear {
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                ringProgress = min(summary.totalHours / 9.0, 1.0)
            }
        }
    }
}

// MARK: — Weekly chart

struct WeeklySleepChart: View {
    let history: [SleepSummary]
    @Binding var selected: SleepSummary?
    @State private var appeared = false

    private var avgHours: Double {
        guard !history.isEmpty else { return 0 }
        return history.map(\.totalHours).reduce(0, +) / Double(history.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Esta semana").font(.headline)
                    Text("Promedio: \(String(format: "%.1f", avgHours))h por noche")
                        .font(.caption).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Theme.moodBlue)
            }

            Chart {
                // Recommended line at 8h
                RuleMark(y: .value("Recomendado", 8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .foregroundStyle(Theme.moodGreen.opacity(0.5))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("8h recomendadas")
                            .font(.caption2)
                            .foregroundStyle(Theme.moodGreen)
                    }

                ForEach(history) { s in
                    BarMark(
                        x: .value("Día", s.weekdayLabel),
                        y: .value("Horas", appeared ? s.totalHours : 0)
                    )
                    .foregroundStyle(barColor(s).gradient)
                    .cornerRadius(6)
                }

                if let sel = selected {
                    RuleMark(x: .value("Día", sel.weekdayLabel))
                        .foregroundStyle(Theme.accent.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartYScale(domain: 0...10)
            .chartYAxis {
                AxisMarks(values: [0, 4, 6, 8]) { v in
                    AxisValueLabel {
                        Text("\(v.as(Int.self) ?? 0)h")
                            .font(.caption2)
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks { v in
                    AxisValueLabel {
                        Text(v.as(String.self) ?? "")
                            .font(.caption2)
                    }
                }
            }
            .frame(height: 160)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let x = val.location.x - geo[proxy.plotFrame!].origin.x
                                if let day: String = proxy.value(atX: x),
                                   let match = history.first(where: { $0.weekdayLabel == day }) {
                                    withAnimation(.smooth) { selected = match }
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation { selected = nil }
                                }
                            }
                        )
                }
            }
            .animation(.spring(duration: 0.8, bounce: 0.1), value: appeared)
        }
        .cardStyle()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { appeared = true }
            }
        }
    }

    private func barColor(_ s: SleepSummary) -> Color {
        switch s.quality {
        case .excellent: return Theme.moodGreen
        case .good:      return Theme.moodBlue
        case .fair:      return Theme.moodYellow
        case .poor:      return Theme.moodPurple
        }
    }
}

// MARK: — Day detail (appears on chart tap)

struct SleepDayDetail: View {
    let summary: SleepSummary

    private var qualityColor: Color {
        switch summary.quality {
        case .excellent: return Theme.moodGreen
        case .good:      return Theme.moodBlue
        case .fair:      return Theme.moodYellow
        case .poor:      return Theme.moodPurple
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(summary.shortDate).font(.caption.bold()).foregroundStyle(Theme.secondaryText)
                Text(summary.formattedTotal).font(.title3.bold()).foregroundStyle(qualityColor)
                Text(summary.quality.rawValue).font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            HStack(spacing: 12) {
                StagePill(label: "Prof", value: summary.formattedDeep, color: Theme.moodPurple)
                StagePill(label: "REM",  value: summary.formattedREM,  color: Theme.moodBlue)
            }
        }
        .cardStyle()
    }
}

// MARK: — Stages breakdown

struct SleepStagesCard: View {
    let summary: SleepSummary
    @State private var appeared = false

    private let stages: [(String, KeyPath<SleepSummary, Double>, Color, String)] = [
        ("Sueño profundo", \.deepHours,  Theme.moodPurple, "Restauración física y memoria"),
        ("Sueño REM",      \.remHours,   Theme.moodBlue,   "Procesamiento emocional y creatividad"),
        ("Sueño ligero",   \.coreHours,  Theme.moodGreen,  "Transición y descanso general"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fases de sueño").font(.headline)

            // Stacked bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(stages, id: \.0) { name, kp, color, _ in
                        let hours = summary[keyPath: kp]
                        let fraction = summary.totalHours > 0 ? hours / summary.totalHours : 0
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: appeared ? geo.size.width * fraction : 0)
                            .animation(.spring(duration: 0.9, bounce: 0.1).delay(0.1), value: appeared)
                    }
                }
                .frame(height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .frame(height: 14)

            VStack(spacing: 10) {
                ForEach(Array(stages.enumerated()), id: \.offset) { i, stage in
                    let (name, kp, color, desc) = stage
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: 12, height: 12)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(name).font(.subheadline.bold())
                            Text(desc).font(.caption).foregroundStyle(Theme.secondaryText)
                        }
                        Spacer()
                        Text(String(format: "%.0f%%", summary.totalHours > 0
                             ? summary[keyPath: kp] / summary.totalHours * 100 : 0))
                            .font(.subheadline.bold())
                            .foregroundStyle(color)
                    }
                    .staggered(i, base: 0.1)
                    if i < stages.count - 1 { Divider() }
                }
            }
        }
        .cardStyle()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { appeared = true }
            }
        }
    }
}

// MARK: — Sleep × Mood tip

struct SleepMoodTipCard: View {
    let quality: SleepQuality

    private var tip: (icon: String, title: String, body: String) {
        switch quality {
        case .excellent:
            return ("brain.head.profile", "Día ideal para aprender",
                    "El sueño profundo consolida la memoria. Aprovecha para estudiar o trabajar en algo importante.")
        case .good:
            return ("moon.zzz", "Mantén tu ritmo",
                    "Un horario consistente de sueño estabiliza tu ánimo y reduce la ansiedad.")
        case .fair:
            return ("cup.and.saucer", "Cuida la cafeína",
                    "Evita cafeína después de las 2 PM y pantallas 1 hora antes de dormir para mejorar tu sueño.")
        case .poor:
            return ("exclamationmark.triangle", "Sueño y ánimo van de la mano",
                    "Dormir menos de 5 horas amplifica emociones negativas. Una siesta de 20 min puede ayudar hoy.")
        }
    }

    private var color: Color {
        switch quality {
        case .excellent: return Theme.moodGreen
        case .good:      return Theme.moodBlue
        case .fair:      return Theme.moodYellow
        case .poor:      return Theme.moodPurple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: tip.icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .symbolEffect(.pulse)
                Text(tip.title)
                    .font(.headline)
            }
            Text(tip.body)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)
        }
        .cardStyle()
    }
}

// MARK: — Helper views

struct StagePill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(Theme.secondaryText)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SleepPermissionView: View {
    let onAllow: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.moodBlue)
                .symbolEffect(.pulse)

            VStack(spacing: 8) {
                Text("Conecta tu sueño").font(.title2.bold())
                Text("Mind lee tus datos de sueño de Apple Health para correlacionarlos con tu estado de ánimo.\n\nNunca salen de tu iPhone.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText)
                    .lineSpacing(4)
            }

            Button(action: onAllow) {
                Text("Permitir acceso")
                    .primaryButton()
            }
            .pressEffect()
            .padding(.horizontal, 40)
        }
        .padding(32)
    }
}

struct LoadingCard: View {
    var body: some View {
        HStack(spacing: 14) {
            ProgressView().tint(Theme.moodBlue)
            Text("Leyendo datos de Apple Health…")
                .font(.subheadline).foregroundStyle(Theme.secondaryText)
        }
        .cardStyle()
    }
}

struct NoSleepDataCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "moon.zzz").font(.title3).foregroundStyle(Theme.secondaryText)
            VStack(alignment: .leading, spacing: 3) {
                Text("Sin datos de sueño").font(.subheadline.bold())
                Text("Asegúrate de usar tu Apple Watch al dormir.")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
            }
        }
        .cardStyle()
    }
}
