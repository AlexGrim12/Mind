import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Query(sort: \MoodEntry.date) private var entries: [MoodEntry]
    @StateObject private var health = HealthKitService.shared
    @State private var selectedRange: TrendRange = .week
    @State private var chartProgress: Double = 0

    private var filtered: [MoodEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedRange.days, to: Date())!
        return entries.filter { $0.date >= cutoff }
    }

    private var average: Double {
        guard !filtered.isEmpty else { return 0 }
        return Double(filtered.map(\.score).reduce(0, +)) / Double(filtered.count)
    }

    private var topics: [String] { ["Sueño", "Relaciones", "Estudios"] }

    private var insight: String {
        guard filtered.count >= 3 else { return "Sigue registrando para ver patrones en tu ánimo." }
        if average >= 7 { return "Tu ánimo ha estado consistentemente alto. ¡Sigue así!" }
        if average <= 3 { return "Ha sido una semana difícil. Considera hablar con alguien." }
        return "Tu ánimo varía. Los patrones se vuelven más claros con más registros."
    }

    var body: some View {
        NavigationStack {
            ScrollWrapper {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Picker("Rango", selection: $selectedRange) {
                            ForEach(TrendRange.allCases) { r in Text(r.label).tag(r) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20).padding(.top, 24)
                        .onChange(of: selectedRange) { _, _ in
                            chartProgress = 0
                            withAnimation(.spring(duration: 1.0, bounce: 0.1).delay(0.1)) { chartProgress = 1 }
                        }

                        AnimatedAverageCard(average: average, count: filtered.count)
                            .padding(.horizontal, 20)
                            .staggered(0)

                        MoodChartCard(entries: filtered, progress: chartProgress)
                            .padding(.horizontal, 20)
                            .staggered(1)

                        // Insight
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Theme.tamago)
                                .font(.title3)
                            Text(insight)
                                .font(.zenBody).foregroundStyle(Theme.sumi)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .cardStyle()
                        .padding(.horizontal, 20)
                        .staggered(2)

                        // Biométricos correlacionados
                        if let snap = health.todaySnapshot {
                            BiometricCorrelationCard(snap: snap, avgMood: average)
                                .padding(.horizontal, 20)
                                .staggered(3)
                        }

                        // Sleep en tendencia
                        if let sleep = health.lastNightSleep {
                            TrendSleepCard(summary: sleep)
                                .padding(.horizontal, 20)
                                .staggered(4)
                        }

                        // Temas on-device
                        VStack(alignment: .leading, spacing: 14) {
                            zenSectionHeader(title: "Temas emergentes", subtitle: "Identificados por tu IA en local")
                            
                            HStack(spacing: 10) {
                                ForEach(Array(topics.enumerated()), id: \.offset) { i, topic in
                                    Text(topic)
                                        .font(.zenCaption.bold())
                                        .padding(.horizontal, 16).padding(.vertical, 9)
                                        .background(Theme.accent.opacity(0.12))
                                        .foregroundStyle(Theme.accent)
                                        .clipShape(Capsule())
                                        .staggered(i, base: 0.4)
                                }
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 20)
                        .staggered(5)

                        Spacer(minLength: 120)
                    }
                }
            }
            .navigationTitle("Tendencias")
        }
        .task { if health.todaySnapshot == nil { await health.fetchAll() } }
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.1).delay(0.3)) { chartProgress = 1 }
        }
    }
}

// MARK: — Biometric correlation card

struct BiometricCorrelationCard: View {
    let snap: BiometricSnapshot
    let avgMood: Double

    private var moodColor: Color { Int(avgMood).moodColor }

    private var correlation: String {
        guard let hrv = snap.hrv else {
            return "Registra más datos para ver correlaciones entre tu ánimo y biométricos."
        }
        let hrvStatus = hrv > 50 ? "bajo" : hrv > 30 ? "moderado" : "alto"
        let moodStatus = avgMood >= 7 ? "alto" : avgMood >= 5 ? "medio" : "bajo"
        if moodStatus == "alto" && hrvStatus == "bajo" {
            return "Tu ánimo alto coincide con buen HRV. El descanso y manejo del estrés están funcionando."
        } else if moodStatus == "bajo" && hrvStatus == "alto" {
            return "Estrés elevado pese al buen ánimo aparente. Considera una sesión de mindfulness."
        } else if moodStatus == "bajo" && hrvStatus == "bajo" {
            return "Ánimo bajo y estrés elevado simultáneamente. Habla con tu psicólogo esta semana."
        }
        return "Indicadores equilibrados. Sigue con tu rutina de sueño y actividad."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Ánimo + biométricos", systemImage: "waveform.and.magnifyingglass")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", avgMood))
                        .font(.title.bold()).foregroundStyle(moodColor)
                    Text("Ánimo promedio").font(.caption).foregroundStyle(Theme.secondaryText)
                }
                Divider().frame(height: 44)

                if let hrv = snap.hrv {
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f ms", hrv))
                            .font(.title.bold()).foregroundStyle(Theme.moodPurple)
                        Text("HRV").font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                    Divider().frame(height: 44)
                }

                if let o2 = snap.oxygenSaturation {
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f%%", o2))
                            .font(.title.bold()).foregroundStyle(Theme.moodBlue)
                        Text("SpO₂").font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                }
            }

            Text(correlation)
                .font(.caption).foregroundStyle(Theme.secondaryText).lineSpacing(3)
                .padding(10).background(Theme.surface).clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .cardStyle()
    }
}

// MARK: — Sleep en tendencia

struct TrendSleepCard: View {
    let summary: SleepSummary

    private var color: Color {
        switch summary.quality {
        case .excellent: return Theme.moodGreen
        case .good:      return Theme.moodBlue
        case .fair:      return Theme.moodYellow
        case .poor:      return Theme.moodPurple
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: summary.quality.icon)
                .font(.title2).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 3) {
                Text("Sueño de anoche · \(summary.formattedTotal)")
                    .font(.subheadline.bold())
                Text("Profundo: \(summary.formattedDeep)  ·  REM: \(summary.formattedREM)")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Text(summary.quality.rawValue)
                .font(.caption.bold()).foregroundStyle(color)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(color.opacity(0.1)).clipShape(Capsule())
        }
        .cardStyle()
    }
}

enum TrendRange: String, CaseIterable, Identifiable {
    case week = "7d"; case month = "30d"; case quarter = "90d"
    var id: String { rawValue }
    var label: String { rawValue }
    var days: Int { switch self { case .week: 7; case .month: 30; case .quarter: 90 } }
}

// MARK: — Average card con número animado

struct AnimatedAverageCard: View {
    let average: Double
    let count: Int
    @State private var displayAverage: Double = 0
    @State private var ringProgress: Double = 0

    private var score: Int { Int(average.rounded()) }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                // Ring de fondo
                Circle()
                    .stroke(score.moodColor.opacity(0.15), lineWidth: 8)
                    .frame(width: 84, height: 84)
                // Ring animado
                Circle()
                    .trim(from: 0, to: ringProgress * average / 10)
                    .stroke(score.moodGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 84, height: 84)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1.2, bounce: 0.2).delay(0.2), value: ringProgress)
                // Número
                VStack(spacing: 0) {
                    Text(String(format: "%.1f", displayAverage))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(score.moodColor)
                        .contentTransition(.numericText(countsDown: false))
                    Text("/ 10")
                        .font(.caption2).foregroundStyle(Theme.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(count == 0 ? "Sin registros" : score.moodLabel)
                    .font(.title3.bold()).foregroundStyle(Theme.textPrimary)
                Text("\(count) check-ins registrados")
                    .font(.subheadline).foregroundStyle(Theme.secondaryText)
                HStack(spacing: 4) {
                    Text(score.moodEmoji)
                    Text(moodDescription).font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }
            Spacer()
        }
        .cardStyle()
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.1).delay(0.3)) {
                displayAverage = average
                ringProgress = 1
            }
        }
        .onChange(of: average) { _, new in
            withAnimation(.springy) { displayAverage = new }
        }
    }

    private var moodDescription: String {
        switch score {
        case 0...2: "Semana muy difícil"
        case 3...4: "Semana complicada"
        case 5...6: "Semana estable"
        case 7...8: "Buena semana"
        default:    "Excelente semana"
        }
    }
}

// MARK: — Chart con animación de draw-in

struct MoodChartCard: View {
    let entries: [MoodEntry]
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ánimo en el tiempo").font(.headline)

            if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.secondaryText.opacity(0.35))
                        .symbolEffect(.pulse)
                    Text("Haz tu primer check-in para ver la gráfica")
                        .font(.subheadline).foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 160).frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(entries) { e in
                        AreaMark(
                            x: .value("Fecha", e.date),
                            yStart: .value("Min", 0),
                            yEnd: .value("Score", Double(e.score) * progress)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [Theme.accent.opacity(0.25), .clear],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Fecha", e.date),
                            y: .value("Score", Double(e.score) * progress)
                        )
                        .foregroundStyle(Theme.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Fecha", e.date),
                            y: .value("Score", Double(e.score) * progress)
                        )
                        .foregroundStyle(e.score.moodColor)
                        .symbolSize(CGFloat(40) * CGFloat(progress))
                    }
                }
                .chartYScale(domain: 0...10)
                .chartYAxis {
                    AxisMarks(values: [0, 5, 10]) { _ in
                        AxisGridLine().foregroundStyle(Color(.systemGray5))
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, entries.count / 5))) { _ in
                        AxisGridLine().foregroundStyle(Color(.systemGray6))
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 180)
            }
        }
        .cardStyle()
    }
}
