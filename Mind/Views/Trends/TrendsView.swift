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
        guard filtered.count >= 3 else { return "Sigue registrando tu camino para ver la evolución de tu jardín interno." }
        if average >= 7 { return "Tu espíritu brilla con claridad. La constancia en tus prácticas está dando frutos." }
        if average <= 3 { return "La niebla es densa en este momento. Hablar con alguien puede ayudarte a encontrar el sol." }
        return "Como las estaciones, tu ánimo fluye. Observa los patrones con calma y paciencia."
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Selector de Rango (Estilo Zen)
                    Picker("Rango", selection: $selectedRange) {
                        ForEach(TrendRange.allCases) { r in Text(r.label).tag(r) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .onChange(of: selectedRange) { _, _ in
                        chartProgress = 0
                        withAnimation(.spring(duration: 1.0, bounce: 0.1).delay(0.1)) { chartProgress = 1 }
                    }

                    // Título de Sección
                    ToriiHeader(title: "Tu Evolución", subtitle: "El registro de tu camino emocional", kanji: "経")

                    AnimatedAverageCard(average: average, count: filtered.count)
                        .padding(.horizontal, 20)
                        .staggered(0)

                    MoodChartCard(entries: filtered, progress: chartProgress)
                        .padding(.horizontal, 20)
                        .staggered(1)

                    // Insight Zen
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            EnsoCircle(color: Theme.ai, lineWidth: 2)
                                .frame(width: 24, height: 24)
                            Text("Sabiduría del Momento")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Theme.sumi)
                        }
                        
                        Text(insight)
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(Theme.sumiSoft)
                            .lineSpacing(4)
                    }
                    .cardStyle()
                    .padding(.horizontal, 20)
                    .staggered(2)

                    // Temas on-device (Estilo Sello)
                    VStack(alignment: .leading, spacing: 16) {
                        zenSectionHeader(title: "Conceptos Recurrentes", subtitle: "Identificados por tu IA local")
                        
                        FlowLayout(spacing: 10) {
                            ForEach(Array(topics.enumerated()), id: \.offset) { i, topic in
                                Text(topic)
                                    .font(.system(.caption, design: .serif).weight(.bold))
                                    .foregroundStyle(Theme.ai)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Theme.kinari.opacity(0.6))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Theme.inkLine, lineWidth: 0.6))
                                    .staggered(i, base: 0.4)
                            }
                        }
                    }
                    .cardStyle()
                    .padding(.horizontal, 20)
                    .staggered(3)

                    Spacer(minLength: 140)
                }
            }
            .screenBackground()
            .navigationTitle("Tendencias · 経")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { if health.todaySnapshot == nil { await health.fetchAll() } }
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.1).delay(0.3)) { chartProgress = 1 }
        }
    }
}

// MARK: — Models

enum TrendRange: String, CaseIterable, Identifiable {
    case week = "7d"; case month = "30d"; case quarter = "90d"
    var id: String { rawValue }
    var label: String { rawValue }
    var days: Int { switch self { case .week: 7; case .month: 30; case .quarter: 90 } }
}

// MARK: — Average card con diseño Zen

struct AnimatedAverageCard: View {
    let average: Double
    let count: Int
    @State private var displayAverage: Double = 0
    @State private var ringProgress: Double = 0

    private var score: Int { Int(average.rounded()) }

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Theme.inkLine, lineWidth: 1)
                    .frame(width: 90, height: 90)
                
                Circle()
                    .trim(from: 0, to: ringProgress * (average / 10))
                    .stroke(score.moodGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text(score.moodKanji)
                        .font(.system(size: 24, weight: .black, design: .serif))
                        .foregroundStyle(Theme.sumi)
                    Text(String(format: "%.1f", displayAverage))
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundStyle(score.moodColor)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(count == 0 ? "Sin registros" : score.moodLabel)
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(count) huellas en el camino")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(Theme.sumiSoft)
            }
            Spacer()
        }
        .cardStyle()
        .onAppear {
            withAnimation(.spring(duration: 1.2, bounce: 0.1).delay(0.3)) {
                displayAverage = average
                ringProgress = 1
            }
        }
    }
}

// MARK: — Chart Zen

struct MoodChartCard: View {
    let entries: [MoodEntry]
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Flujo de Energía").font(.system(.headline, design: .serif))
                Spacer()
                Image(systemName: "water.waves").foregroundStyle(Theme.asagi)
            }

            if entries.isEmpty {
                VStack(spacing: 12) {
                    EnsoCircle(color: Theme.sumiSoft.opacity(0.2), lineWidth: 1)
                        .frame(width: 60, height: 60)
                    Text("Comienza tu viaje para ver el flujo")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(Theme.sumiSoft)
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
                            LinearGradient(colors: [e.score.moodColor.opacity(0.2), .clear],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Fecha", e.date),
                            y: .value("Score", Double(e.score) * progress)
                        )
                        .foregroundStyle(Theme.ai.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Fecha", e.date),
                            y: .value("Score", Double(e.score) * progress)
                        )
                        .foregroundStyle(e.score.moodColor)
                        .symbolSize(40)
                    }
                }
                .chartYScale(domain: 0...10)
                .chartYAxis {
                    AxisMarks(values: [0, 5, 10]) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Theme.inkLine)
                        AxisValueLabel().font(.system(.caption2, design: .serif))
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated)).font(.system(.caption2, design: .serif))
                    }
                }
                .frame(height: 180)
            }
        }
        .cardStyle()
    }
}
