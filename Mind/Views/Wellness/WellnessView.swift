import SwiftUI
import Charts

struct WellnessView: View {
    @State private var health = HealthKitService.shared
    @State private var selectedSnap: BiometricSnapshot? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // Título de Sección Zen
                    ToriiHeader(title: "Tu Vitalidad", subtitle: "Equilibrio entre cuerpo y mente", kanji: "康")
                        .padding(.top, 20)

                    if !health.isAuthorized {
                        WellnessPermissionView { Task { await health.requestAuthorization() } }
                    } else if health.isLoading && health.todaySnapshot == nil {
                        VStack(spacing: 20) {
                            EnsoCircle(color: Theme.ai, lineWidth: 2)
                                .frame(width: 60, height: 60)
                            Text("Sintonizando con tu energía…")
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Theme.sumiSoft)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        VStack(spacing: 24) {

                            if let score = health.wellnessScore {
                                WellnessScoreHeroZen(score: score)
                                    .staggered(0)

                                ScoreBreakdownZen(score: score)
                                    .staggered(1)
                            }

                            if let snap = health.todaySnapshot {
                                CardiovascularZenCard(snap: snap)
                                    .staggered(2)

                                ActivityZenCard(snap: snap)
                                    .staggered(3)
                            }

                            if !health.weekSnapshots.isEmpty {
                                WeeklyActivityZenChart(snapshots: health.weekSnapshots)
                                    .staggered(4)
                            }

                            Spacer(minLength: 120)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .screenBackground()
            .navigationTitle("Salud · 康")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { Task { await health.fetchAll() } } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(.subheadline, design: .serif).bold())
                            .foregroundStyle(Theme.sumiSoft)
                    }
                }
            }
            .task {
                if !health.isAuthorized { await health.requestAuthorization() }
                else if health.todaySnapshot == nil { await health.fetchAll() }
            }
        }
    }
}

// MARK: — Wellness score hero Zen

struct WellnessScoreHeroZen: View {
    let score: WellnessScore
    @State private var ring: Double = 0
    @State private var appeared = false

    private var color: Color { themeColor(score.color) }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // El Círculo Enso como indicador de salud
                EnsoCircle(color: color, lineWidth: 6)
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .opacity(ring) // Sutil aparición
                
                VStack(spacing: 4) {
                    Text("\(score.total)")
                        .font(.system(size: 52, weight: .black, design: .serif))
                        .foregroundStyle(Theme.sumi)
                    Text("PUNTOS ZEN")
                        .font(.system(.caption2, design: .serif).weight(.bold))
                        .foregroundStyle(Theme.sumiSoft)
                        .tracking(2)
                }
            }
            .padding(.top, 10)

            VStack(spacing: 8) {
                Text(score.label)
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundStyle(color)
                
                Text(score.insight)
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(Theme.sumiSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 10)
            }
            .padding(16)
            .background(Theme.kinari.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .cardStyle()
        .onAppear {
            withAnimation(.spring(duration: 1.5)) { ring = 1.0 }
        }
    }
}

// MARK: — Score breakdown Zen

struct ScoreBreakdownZen: View {
    let score: WellnessScore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Equilibrio de los Elementos").font(.system(.headline, design: .serif))
                Spacer()
                PagodaIcon().frame(width: 24, height: 24)
            }
            
            VStack(spacing: 16) {
                ScoreRowZen(label: "Descanso", kanji: "憩", value: score.sleepScore, color: Theme.ai)
                ScoreRowZen(label: "Energía", kanji: "動", value: score.activityScore, color: Theme.matchaDeep)
                ScoreRowZen(label: "Corazón", kanji: "心", value: score.cardiovascularScore, color: Theme.aka)
                ScoreRowZen(label: "Calma", kanji: "静", value: score.recoveryScore, color: Theme.moodPurple)
            }
        }
        .cardStyle()
    }
}

struct ScoreRowZen: View {
    let label: String; let kanji: String; let value: Int; let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Text(kanji)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(label).font(.system(.subheadline, design: .serif))
                    Spacer()
                    Text("\(value)/25").font(.system(.caption, design: .serif).bold()).foregroundStyle(Theme.sumiSoft)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.inkLine.opacity(0.3)).frame(height: 4)
                        Capsule().fill(color)
                            .frame(width: geo.size.width * (Double(value)/25.0), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}

// MARK: — Cardiovascular Zen

struct CardiovascularZenCard: View {
    let snap: BiometricSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Pulso y Vitalidad", systemImage: "waveform.path.ecg")
                    .font(.system(.headline, design: .serif))
                Spacer()
                HankoStamp(kanji: "脈", color: Theme.aka.opacity(0.7), size: 24)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                MetricZenTile(title: "Ritmo", value: snap.heartRate.map { "\(Int($0))" } ?? "–", unit: "bpm", color: Theme.aka)
                MetricZenTile(title: "HRV (Calma)", value: snap.hrv.map { String(format: "%.0f", $0) } ?? "–", unit: "ms", color: Theme.moodPurple)
                MetricZenTile(title: "Oxígeno", value: snap.oxygenSaturation.map { String(format: "%.0f%%", $0) } ?? "–", unit: "", color: Theme.asagi)
                MetricZenTile(title: "Respiro", value: snap.respiratoryRate.map { String(format: "%.0f", $0) } ?? "–", unit: "rpm", color: Theme.ai)
            }
            
            if let hrv = snap.hrv {
                HRVZenInsight(hrv: hrv)
            }
        }
        .cardStyle()
    }
}

struct HRVZenInsight: View {
    let hrv: Double
    var body: some View {
        HStack(spacing: 12) {
            EnsoCircle(color: hrv > 50 ? Theme.matcha : Theme.moodPurple, lineWidth: 1.5)
                .frame(width: 20, height: 20)
            Text(hrv > 50 ? "Tu sistema está en armonía absoluta." : "Tu cuerpo pide un momento de quietud.")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(Theme.sumiSoft)
        }
        .padding(12)
        .background(Theme.kinari.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: — Activity Zen

struct ActivityZenCard: View {
    let snap: BiometricSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Movimiento", systemImage: "figure.walk")
                    .font(.system(.headline, design: .serif))
                Spacer()
                HankoStamp(kanji: "歩", color: Theme.matchaDeep.opacity(0.7), size: 24)
            }

            HStack(spacing: 20) {
                ActivityZenRing(kanji: "動", value: snap.activeCalories, goal: 500, color: Theme.aka)
                ActivityZenRing(kanji: "修", value: Double(snap.exerciseMinutes), goal: 30, color: Theme.matchaDeep)
                ActivityZenRing(kanji: "立", value: Double(snap.standMinutes / 60), goal: 12, color: Theme.asagi)
            }
            .frame(maxWidth: .infinity)

            Divider().background(Theme.inkLine)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(snap.steps.formatted()) pasos")
                        .font(.system(.headline, design: .serif))
                    Text("Caminata del día").font(.system(.caption, design: .serif)).foregroundStyle(Theme.sumiSoft)
                }
                Spacer()
                Text(snap.activityLevel.rawValue)
                    .font(.system(.caption, design: .serif).weight(.bold))
                    .foregroundStyle(Theme.ai)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.ai.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .cardStyle()
    }
}

struct ActivityZenRing: View {
    let kanji: String; let value: Double; let goal: Double; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(color.opacity(0.1), lineWidth: 4).frame(width: 50, height: 50)
                Circle().trim(from: 0, to: min(value/goal, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50).rotationEffect(.degrees(-90))
                Text(kanji).font(.system(size: 14, design: .serif)).foregroundStyle(color)
            }
            Text("\(Int(value))").font(.system(.caption2, design: .serif).weight(.bold)).foregroundStyle(Theme.sumi)
        }
    }
}

// MARK: — Shared Zen Helpers

struct MetricZenTile: View {
    let title: String; let value: String; let unit: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(.caption, design: .serif)).foregroundStyle(Theme.sumiSoft)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.system(.title3, design: .serif).weight(.bold)).foregroundStyle(Theme.sumi)
                Text(unit).font(.system(.caption2, design: .serif)).foregroundStyle(Theme.sumiSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.1), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct WeeklyActivityZenChart: View {
    let snapshots: [BiometricSnapshot]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ritmo Semanal").font(.system(.headline, design: .serif))
            Chart {
                ForEach(snapshots) { s in
                    BarMark(x: .value("Día", s.weekdayLabel),
                            y: .value("Pasos", s.steps))
                        .foregroundStyle(Theme.ai.gradient)
                        .cornerRadius(4)
                }
            }
            .frame(height: 120)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in AxisValueLabel().font(.system(.caption2, design: .serif)) }
            }
        }
        .cardStyle()
    }
}

struct WellnessPermissionView: View {
    let onAllow: () -> Void
    var body: some View {
        VStack(spacing: 32) {
            EnsoCircle(color: Theme.ai, lineWidth: 3).frame(width: 100, height: 100)
            
            VStack(spacing: 12) {
                Text("Análisis de los Elementos")
                    .font(.system(.title2, design: .serif).weight(.bold))
                Text("Mind solicita permiso para leer tu energía vital a través de Apple Health. Tus datos son sagrados y nunca abandonan este dispositivo.")
                    .font(.system(.subheadline, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.sumiSoft)
                    .lineSpacing(6)
            }
            
            Button(action: onAllow) { 
                Text("Conceder Permiso")
            }
            .primaryButton()
            .padding(.horizontal, 20)
        }
        .padding(32)
    }
}

private func themeColor(_ name: String) -> Color {
    switch name {
    case "moodGreen":  return Theme.moodGreen
    case "moodBlue":   return Theme.moodBlue
    case "moodYellow": return Theme.moodYellow
    case "moodPurple": return Theme.moodPurple
    default:           return Theme.ai
    }
}
