import SwiftUI
import Charts

struct WellnessView: View {
    @StateObject private var health = HealthKitService.shared
    @State private var selectedSnap: BiometricSnapshot? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientBackground

                if !health.isAuthorized {
                    WellnessPermissionView { Task { await health.requestAuthorization() } }
                } else if health.isLoading && health.todaySnapshot == nil {
                    ProgressView("Analizando tus datos…")
                        .tint(Theme.accent)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {

                            if let score = health.wellnessScore {
                                WellnessScoreHero(score: score)
                                    .staggered(0, base: 0)

                                ScoreBreakdownCard(score: score)
                                    .staggered(1, base: 0)
                            }

                            if let snap = health.todaySnapshot {
                                CardiovascularCard(snap: snap)
                                    .staggered(2, base: 0)

                                ActivityCard(snap: snap)
                                    .staggered(3, base: 0)

                                BodyMetricsCard(snap: snap)
                                    .staggered(4, base: 0)

                                MindEnvironmentCard(snap: snap)
                                    .staggered(5, base: 0)
                            }

                            if !health.weekSnapshots.isEmpty {
                                WeeklyActivityChart(snapshots: health.weekSnapshots,
                                                    selected: $selectedSnap)
                                    .staggered(6, base: 0)
                            }

                            if let sleep = health.lastNightSleep {
                                SleepSummaryTile(summary: sleep)
                                    .staggered(7, base: 0)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Bienestar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { Task { await health.fetchAll() } } label: {
                        Image(systemName: "arrow.clockwise").font(.subheadline)
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

// MARK: — Wellness score hero

struct WellnessScoreHero: View {
    let score: WellnessScore
    @State private var ring: Double = 0
    @State private var appeared = false

    private var color: Color { themeColor(score.color) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [color.opacity(0.55), color.opacity(0.25)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                Circle().fill(.white.opacity(0.05)).frame(width: 140).offset(x: 90, y: -20)
                Circle().fill(.white.opacity(0.04)).frame(width: 100).offset(x: -100, y: 10)

                HStack(spacing: 24) {
                    // Ring
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 12)
                            .frame(width: 100, height: 100)
                        Circle()
                            .trim(from: 0, to: ring)
                            .stroke(.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(duration: 1.4, bounce: 0.1), value: ring)
                        VStack(spacing: 1) {
                            Text("\(score.total)")
                                .font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                            Text("/ 100").font(.caption2).foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .scaleEffect(appeared ? 1 : 0.4)
                    .animation(.bouncy.delay(0.1), value: appeared)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Índice de bienestar").font(.caption).foregroundStyle(.white.opacity(0.8))
                        Text(score.label).font(.title2.bold()).foregroundStyle(.white)
                        Text("Hoy · basado en \nApple Health").font(.caption)
                            .foregroundStyle(.white.opacity(0.75)).lineSpacing(2)
                    }
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 10)
                    .animation(.springy.delay(0.15), value: appeared)

                    Spacer()
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }

            // Insight
            HStack(spacing: 12) {
                Image(systemName: "sparkles").foregroundStyle(color).symbolEffect(.pulse)
                Text(score.insight).font(.caption).foregroundStyle(Theme.textPrimary)
                    .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            }
            .padding(14).background(color.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14)).padding(.top, 10)
        }
        .onAppear {
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { ring = Double(score.total) / 100 }
        }
    }
}

// MARK: — Score breakdown

struct ScoreBreakdownCard: View {
    let score: WellnessScore

    private struct ScoreItem {
        let name: String; let icon: String; let value: Int; let color: Color
    }

    private var items: [ScoreItem] { [
        .init(name: "Sueño",          icon: "moon.stars.fill",       value: score.sleepScore,         color: Theme.moodBlue),
        .init(name: "Actividad",      icon: "figure.run",             value: score.activityScore,      color: Theme.moodGreen),
        .init(name: "Cardiovascular", icon: "heart.fill",             value: score.cardiovascularScore, color: .red),
        .init(name: "Recuperación",   icon: "waveform.path.ecg.text", value: score.recoveryScore,      color: Theme.moodPurple),
    ] }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Desglose").font(.headline)
            VStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    ScoreRow(name: item.name, icon: item.icon,
                             value: item.value, maxValue: 25, color: item.color)
                        .staggered(i, base: 0.05)
                }
            }
        }
        .cardStyle()
    }
}

struct ScoreRow: View {
    let name: String; let icon: String
    let value: Int; let maxValue: Int; let color: Color
    @State private var progress: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 20)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name).font(.subheadline.bold())
                    Spacer()
                    Text("\(value)/\(maxValue)").font(.caption.bold()).foregroundStyle(color)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surface).frame(height: 6)
                        Capsule().fill(color)
                            .frame(width: geo.size.width * progress, height: 6)
                            .animation(.spring(duration: 0.9, bounce: 0.1).delay(0.1), value: progress)
                    }
                }
                .frame(height: 6)
            }
        }
        .onAppear { progress = Double(value) / Double(maxValue) }
    }
}

// MARK: — Cardiovascular card

struct CardiovascularCard: View {
    let snap: BiometricSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Cardiovascular", icon: "heart.fill", color: .red)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(icon: "heart.fill", color: .red,
                           title: "FC actual",
                           value: snap.heartRate.map { "\(Int($0))" } ?? "–", unit: "bpm")
                MetricTile(icon: "heart.circle", color: Color(red: 0.8, green: 0.2, blue: 0.2),
                           title: "FC reposo",
                           value: snap.restingHeartRate.map { "\(Int($0))" } ?? "–", unit: "bpm")
                MetricTile(icon: "waveform.path.ecg", color: Theme.moodPurple,
                           title: "HRV",
                           value: snap.hrv.map { String(format: "%.0f", $0) } ?? "–", unit: "ms")
                MetricTile(icon: "lungs.fill", color: Theme.moodBlue,
                           title: "SpO₂",
                           value: snap.oxygenSaturation.map { String(format: "%.0f%%", $0) } ?? "–", unit: "")
                MetricTile(icon: "wind", color: .cyan,
                           title: "Respiración",
                           value: snap.respiratoryRate.map { String(format: "%.0f", $0) } ?? "–", unit: "rpm")
                MetricTile(icon: "figure.walk.motion", color: Theme.moodGreen,
                           title: "FC al caminar",
                           value: snap.walkingHeartRate.map { "\(Int($0))" } ?? "–", unit: "bpm")
            }

            if let vo2 = snap.vo2Max {
                Divider()
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis.ascending").foregroundStyle(Theme.moodGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VO₂ Máx").font(.subheadline.bold())
                        Text("Capacidad aeróbica").font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    Text(String(format: "%.1f", vo2))
                        .font(.title3.bold()).foregroundStyle(Theme.moodGreen)
                    Text("ml/kg·min").font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }

            if let hrv = snap.hrv {
                HRVInsightBanner(hrv: hrv)
            }
        }
        .cardStyle()
    }
}

struct HRVInsightBanner: View {
    let hrv: Double
    private var hrvInfo: (label: String, color: Color, text: String) {
        switch hrv {
        case 50...: return ("HRV alto — sistema nervioso equilibrado", Theme.moodGreen,
                            "Tu sistema nervioso autónomo está bien regulado. Buen día para actividad intensa.")
        case 30..<50: return ("HRV moderado — leve tensión", Theme.moodYellow,
                              "Algo de estrés o fatiga acumulada. Considera ejercicio ligero hoy.")
        default:    return ("HRV bajo — alta carga de estrés", Theme.moodPurple,
                            "Tu cuerpo está en modo de recuperación. Prioriza descanso y respiración.")
        }
    }
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(hrvInfo.color).frame(width: 8, height: 8).padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(hrvInfo.label).font(.caption.bold()).foregroundStyle(hrvInfo.color)
                Text(hrvInfo.text).font(.caption).foregroundStyle(Theme.secondaryText).lineSpacing(2)
            }
        }
        .padding(10).background(hrvInfo.color.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: — Activity card

struct ActivityCard: View {
    let snap: BiometricSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Actividad física", icon: "figure.run", color: Theme.moodGreen)

            // Activity rings inspired
            HStack(spacing: 20) {
                ActivityRingMini(label: "Mover", value: snap.activeCalories,
                                 goal: 500, unit: "kcal", color: .red)
                ActivityRingMini(label: "Ejercicio", value: Double(snap.exerciseMinutes),
                                 goal: 30, unit: "min", color: Theme.moodGreen)
                ActivityRingMini(label: "De pie", value: Double(snap.standMinutes / 60),
                                 goal: 12, unit: "h", color: .cyan)
            }
            .frame(maxWidth: .infinity)

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(icon: "shoeprints.fill", color: Theme.moodGreen,
                           title: "Pasos", value: snap.steps.formatted(), unit: "")
                MetricTile(icon: "figure.walk", color: Theme.moodBlue,
                           title: "Distancia",
                           value: String(format: "%.1f", snap.distanceKm), unit: "km")
                MetricTile(icon: "flame.fill", color: .orange,
                           title: "Calorías activas",
                           value: "\(Int(snap.activeCalories))", unit: "kcal")
                MetricTile(icon: "arrow.up.right", color: Theme.moodPurple,
                           title: "Pisos",
                           value: "\(snap.flightsClimbed)", unit: "pisos")
            }

            // Level badge
            HStack(spacing: 8) {
                Text(snap.activityLevel.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(themeColor(snap.activityLevel.color))
                Spacer()
                Text("Meta: 10,000 pasos")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
            }
            .padding(10)
            .background(themeColor(snap.activityLevel.color).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .cardStyle()
    }
}

struct ActivityRingMini: View {
    let label: String; let value: Double; let goal: Double; let unit: String; let color: Color
    @State private var progress: Double = 0

    private var fraction: Double { min(value / goal, 1.0) }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(color.opacity(0.15), lineWidth: 8).frame(width: 60, height: 60)
                Circle().trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60).rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1, bounce: 0.15), value: progress)
                VStack(spacing: 0) {
                    Text(String(format: value >= 100 ? "%.0f" : "%.0f", value))
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(color)
                    if !unit.isEmpty {
                        Text(unit).font(.system(size: 8)).foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            Text(label).font(.caption2).foregroundStyle(Theme.secondaryText)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { progress = fraction }
        }
    }
}

// MARK: — Body metrics card

struct BodyMetricsCard: View {
    let snap: BiometricSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Temperatura corporal", icon: "thermometer.medium", color: .orange)

            HStack(spacing: 16) {
                if let wrist = snap.wristTemperature {
                    TemperatureTile(title: "Muñeca (sueño)", value: wrist, icon: "applewatch")
                }
                if let body = snap.bodyTemperature {
                    TemperatureTile(title: "Corporal", value: body, icon: "thermometer.medium")
                }
                if snap.wristTemperature == nil && snap.bodyTemperature == nil {
                    HStack(spacing: 10) {
                        Image(systemName: "thermometer.medium").foregroundStyle(.orange)
                        Text("Sin datos de temperatura.\nRequiere Apple Watch Series 8+.")
                            .font(.caption).foregroundStyle(Theme.secondaryText).lineSpacing(3)
                    }
                }
            }

            if let wrist = snap.wristTemperature {
                let deviation = wrist - 36.5
                HStack(spacing: 8) {
                    Image(systemName: deviation > 0.5 ? "exclamationmark.triangle" : "checkmark.circle")
                        .foregroundStyle(abs(deviation) < 0.5 ? Theme.moodGreen : Theme.moodYellow)
                    Text(temperatureInsight(wrist))
                        .font(.caption).foregroundStyle(Theme.secondaryText).lineSpacing(2)
                }
                .padding(10).background(Color.orange.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .cardStyle()
    }

    private func temperatureInsight(_ temp: Double) -> String {
        let dev = temp - 36.5
        if abs(dev) < 0.3 { return "Temperatura normal. Sin señales de estrés térmico o enfermedad." }
        if dev > 0.5 { return "Temperatura ligeramente elevada. Puede indicar inicio de enfermedad, estrés o ciclo menstrual." }
        return "Temperatura algo baja. Asegúrate de mantenerte hidratado y abrigado."
    }
}

struct TemperatureTile: View {
    let title: String; let value: Double; let icon: String
    private var color: Color { abs(value - 36.5) < 0.5 ? Theme.moodGreen : .orange }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(String(format: "%.1f°C", value))
                .font(.title2.bold()).foregroundStyle(Theme.textPrimary)
            Text(title).font(.caption).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12).background(color.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: — Mind & Environment card

struct MindEnvironmentCard: View {
    let snap: BiometricSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Mente y entorno", icon: "brain.head.profile", color: Theme.moodPurple)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(icon: "brain", color: Theme.moodPurple,
                           title: "Mindfulness",
                           value: "\(snap.mindfulMinutes)", unit: "min")
                MetricTile(icon: "ear.fill", color: .orange,
                           title: "Ruido ambiente",
                           value: snap.noiseEnvironment.map { String(format: "%.0f", $0) } ?? "–", unit: "dBA")
                MetricTile(icon: "headphones", color: .pink,
                           title: "Auriculares",
                           value: snap.noiseHeadphones.map { String(format: "%.0f", $0) } ?? "–", unit: "dBA")
                MetricTile(icon: "flame.fill", color: .orange,
                           title: "Cal. basales",
                           value: "\(Int(snap.basalCalories))", unit: "kcal")
            }

            // Noise insight
            if let noise = snap.noiseEnvironment {
                let risky = noise > 85
                HStack(spacing: 8) {
                    Image(systemName: risky ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(risky ? .orange : Theme.moodGreen)
                    Text(risky
                         ? "Exposición a ruido elevado (\(Int(noise)) dBA). Puede contribuir al estrés y fatiga."
                         : "Niveles de ruido seguros. El entorno acústico es adecuado.")
                        .font(.caption).foregroundStyle(Theme.secondaryText).lineSpacing(2)
                }
                .padding(10).background((risky ? Color.orange : Theme.moodGreen).opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if snap.mindfulMinutes == 0 {
                HStack(spacing: 8) {
                    Image(systemName: "brain").foregroundStyle(Theme.moodPurple)
                    Text("Sin sesiones de mindfulness hoy. 5 minutos de respiración consciente pueden reducir el cortisol.")
                        .font(.caption).foregroundStyle(Theme.secondaryText).lineSpacing(2)
                }
                .padding(10).background(Theme.moodPurple.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .cardStyle()
    }
}

// MARK: — Weekly activity chart

struct WeeklyActivityChart: View {
    let snapshots: [BiometricSnapshot]
    @Binding var selected: BiometricSnapshot?
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Actividad semanal").font(.headline)

            Chart {
                RuleMark(y: .value("Meta", 10000))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .foregroundStyle(Theme.moodGreen.opacity(0.5))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("10k meta").font(.caption2).foregroundStyle(Theme.moodGreen)
                    }
                ForEach(snapshots) { s in
                    BarMark(x: .value("Día", s.weekdayLabel),
                            y: .value("Pasos", appeared ? s.steps : 0))
                        .foregroundStyle(themeColor(s.activityLevel.color).gradient)
                        .cornerRadius(6)
                }
            }
            .chartYScale(domain: 0...15000)
            .chartYAxis {
                AxisMarks(values: [0, 5000, 10000, 15000]) { v in
                    AxisValueLabel {
                        let val = v.as(Int.self) ?? 0
                        Text(val >= 1000 ? "\(val/1000)k" : "\(val)").font(.caption2)
                    }
                    AxisGridLine()
                }
            }
            .frame(height: 140)
            .animation(.spring(duration: 0.8, bounce: 0.1), value: appeared)

            // HRV trend
            if snapshots.compactMap(\.hrv).count > 1 {
                Divider()
                Text("HRV esta semana").font(.subheadline.bold())
                Chart {
                    ForEach(snapshots) { s in
                        if let hrv = s.hrv {
                            LineMark(x: .value("Día", s.weekdayLabel),
                                     y: .value("HRV", hrv))
                                .foregroundStyle(Theme.moodPurple)
                                .interpolationMethod(.catmullRom)
                            AreaMark(x: .value("Día", s.weekdayLabel),
                                     y: .value("HRV", hrv))
                                .foregroundStyle(Theme.moodPurple.opacity(0.1))
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Día", s.weekdayLabel),
                                      y: .value("HRV", hrv))
                                .foregroundStyle(Theme.moodPurple)
                                .symbolSize(30)
                        }
                    }
                }
                .frame(height: 100)
                .chartYAxis {
                    AxisMarks { v in
                        AxisValueLabel { Text("\(v.as(Int.self) ?? 0)ms").font(.caption2) }
                        AxisGridLine()
                    }
                }
            }
        }
        .cardStyle()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { appeared = true }
            }
        }
    }
}

// MARK: — Sleep summary tile (compact)

struct SleepSummaryTile: View {
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
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Sueño de anoche", icon: "moon.stars.fill", color: color)
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.formattedTotal).font(.title2.bold()).foregroundStyle(color)
                    Text(summary.quality.rawValue).font(.caption.bold()).foregroundStyle(color)
                }
                Divider().frame(height: 40)
                VStack(spacing: 8) {
                    HStack {
                        SleepStageChip(label: "Profundo", value: summary.formattedDeep, color: Theme.moodPurple)
                        SleepStageChip(label: "REM",      value: summary.formattedREM,  color: Theme.moodBlue)
                        SleepStageChip(label: "Ligero",   value: summary.formattedTotal, color: Theme.moodGreen)
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct SleepStageChip: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6).background(color.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: — Shared helpers

struct SectionHeader: View {
    let title: String; let icon: String; let color: Color
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color).font(.subheadline.bold())
            Text(title).font(.headline)
        }
    }
}

struct MetricTile: View {
    let icon: String; let color: Color
    let title: String; let value: String; let unit: String
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title3.bold()).foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText()).animation(.smooth, value: value)
                if !unit.isEmpty {
                    Text(unit).font(.caption2).foregroundStyle(Theme.secondaryText)
                }
            }
            Text(title).font(.caption).foregroundStyle(Theme.secondaryText).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12).background(color.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.88).opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.spring(duration: 0.5, bounce: 0.25).delay(0.1)) { appeared = true } }
    }
}

struct WellnessPermissionView: View {
    let onAllow: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.clipboard.fill")
                .font(.system(size: 64)).foregroundStyle(Theme.accent).symbolEffect(.pulse)
            VStack(spacing: 8) {
                Text("Análisis integral").font(.title2.bold())
                Text("Mind lee frecuencia cardíaca, HRV, oxígeno, temperatura, actividad, sueño y más de Apple Health para darte una imagen completa de tu bienestar.\n\nTus datos nunca salen del dispositivo.")
                    .font(.subheadline).multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText).lineSpacing(4)
            }
            Button(action: onAllow) { Text("Permitir acceso").primaryButton() }
                .pressEffect().padding(.horizontal, 40)
        }
        .padding(32)
    }
}

// Helper to resolve color name → Color
private func themeColor(_ name: String) -> Color {
    switch name {
    case "moodGreen":  return Theme.moodGreen
    case "moodBlue":   return Theme.moodBlue
    case "moodYellow": return Theme.moodYellow
    case "moodPurple": return Theme.moodPurple
    default:           return Theme.accent
    }
}
