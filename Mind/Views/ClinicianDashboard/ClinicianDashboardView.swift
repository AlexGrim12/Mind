import SwiftUI
import Charts

struct ClinicianDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    private let students = StudentMock.all

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Stats summary
                        HStack(spacing: 12) {
                            StatPill(label: "Activos", value: "\(students.count)", color: Theme.moodGreen)
                            StatPill(label: "Alertas", value: "\(students.filter { $0.status == .crisis }.count)", color: Theme.crisisRed)
                            StatPill(label: "Estables", value: "\(students.filter { $0.status == .good }.count)", color: Theme.accent)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Student list
                        ForEach(students) { student in
                            NavigationLink {
                                StudentDetailView(student: student)
                            } label: {
                                StudentCard(student: student)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Portal · Dra. Rivera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle(padding: 0)
    }
}

struct StudentCard: View {
    let student: StudentMock

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(student.status.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Text(student.initials)
                    .font(.headline)
                    .foregroundStyle(student.status.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(student.name)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    // Mini trend
                    MiniSparkline(values: Array(student.moodHistory.suffix(7)), color: student.status.color)
                        .frame(width: 56, height: 24)
                }
                HStack(spacing: 8) {
                    StatusChip(status: student.status)
                    Text("· \(student.lastSeen)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .cardStyle()
    }
}

struct MiniSparkline: View {
    let values: [Int]
    let color: Color

    var body: some View {
        Chart {
            ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                LineMark(x: .value("i", i), y: .value("v", v))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...10)
    }
}

struct StatusChip: View {
    let status: StudentStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(status.color).frame(width: 7, height: 7)
            Text(status.label)
                .font(.caption.bold())
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(status.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct StudentDetailView: View {
    let student: StudentMock

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Crisis banner
                if student.status == .crisis {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Alerta de crisis activa")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Theme.crisisRed)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                }

                // Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tendencia 30 días")
                        .font(.headline)
                    Chart {
                        ForEach(Array(student.moodHistory.enumerated()), id: \.offset) { i, v in
                            AreaMark(x: .value("Día", i), yStart: .value("Min", 0), yEnd: .value("Score", v))
                                .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                                .interpolationMethod(.catmullRom)
                            LineMark(x: .value("Día", i), y: .value("Score", v))
                                .foregroundStyle(Theme.accent)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                                .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartYScale(domain: 0...10)
                    .chartXAxis(.hidden)
                    .frame(height: 140)
                }
                .cardStyle()
                .padding(.horizontal, 20)

                // Wellness score + biometrics
                if let ws = student.wellnessScore {
                    StudentWellnessCard(student: student, wellnessScore: ws)
                        .padding(.horizontal, 20)
                }

                // Scores
                HStack(spacing: 12) {
                    ScoreCard(label: "PHQ-9", score: student.phq9, max: 27, thresholds: (5, 10, 15))
                    ScoreCard(label: "GAD-7", score: student.gad7, max: 21, thresholds: (5, 10, 15))
                }
                .padding(.horizontal, 20)

                // Topics
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Temas desde la última sesión")
                            .font(.headline)
                        Spacer()
                        Label("Anonimizados", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    FlowLayout(spacing: 8) {
                        ForEach(student.topics, id: \.self) { t in
                            Text(t)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Theme.accent.opacity(0.1))
                                .foregroundStyle(Theme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
                .cardStyle()
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .screenBackground()
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: — Student wellness biometrics card (clinician view)

struct StudentWellnessCard: View {
    let student: StudentMock
    let wellnessScore: Int

    private var wsColor: Color {
        switch wellnessScore {
        case 75...: return Theme.moodGreen
        case 50..<75: return Theme.moodBlue
        case 30..<50: return Theme.moodYellow
        default: return Theme.crisisRed
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Bienestar Apple Health", systemImage: "heart.text.clipboard.fill")
                    .font(.headline)
                Spacer()
                Label("Consentido", systemImage: "lock.fill")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
            }

            // Wellness score ring
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(wsColor.opacity(0.15), lineWidth: 8)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: Double(wellnessScore) / 100)
                        .stroke(wsColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                    Text("\(wellnessScore)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(wsColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Índice de bienestar")
                        .font(.subheadline.bold())
                    Text(wellnessScore >= 75 ? "Estado óptimo"
                         : wellnessScore >= 50 ? "Estado moderado"
                         : wellnessScore >= 30 ? "Necesita atención"
                         : "Estado crítico — priorizar en sesión")
                        .font(.caption).foregroundStyle(wsColor)
                }
                Spacer()
            }

            Divider()

            // Biometric grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let sleep = student.sleepHours, let qual = student.sleepQuality {
                    ClinicalMetricTile(icon: "moon.fill", label: "Sueño",
                                      value: String(format: "%.1fh", sleep),
                                      subtitle: qual,
                                      color: sleep >= 7 ? Theme.moodGreen : sleep >= 5 ? Theme.moodYellow : Theme.crisisRed)
                }
                if let hrv = student.hrv {
                    ClinicalMetricTile(icon: "waveform.path.ecg", label: "HRV",
                                      value: String(format: "%.0f ms", hrv),
                                      subtitle: hrv > 50 ? "Bajo estrés" : hrv > 30 ? "Moderado" : "Alto estrés",
                                      color: hrv > 50 ? Theme.moodGreen : hrv > 30 ? Theme.moodYellow : Theme.crisisRed)
                }
                if let hr = student.restingHR {
                    ClinicalMetricTile(icon: "heart.fill", label: "FC reposo",
                                      value: "\(Int(hr)) bpm",
                                      subtitle: hr < 70 ? "Óptimo" : hr < 80 ? "Normal" : "Elevado",
                                      color: hr < 70 ? Theme.moodGreen : hr < 80 ? Theme.moodBlue : .orange)
                }
                if let o2 = student.o2 {
                    ClinicalMetricTile(icon: "lungs.fill", label: "SpO₂",
                                      value: String(format: "%.0f%%", o2),
                                      subtitle: o2 >= 98 ? "Normal" : o2 >= 95 ? "Aceptable" : "Bajo",
                                      color: o2 >= 98 ? Theme.moodGreen : o2 >= 95 ? Theme.moodYellow : .red)
                }
                if let steps = student.steps {
                    ClinicalMetricTile(icon: "shoeprints.fill", label: "Pasos",
                                      value: "\(steps)",
                                      subtitle: steps >= 8000 ? "Activo" : steps >= 4000 ? "Moderado" : "Sedentario",
                                      color: steps >= 8000 ? Theme.moodGreen : steps >= 4000 ? Theme.moodBlue : Theme.moodYellow)
                }
            }

            // Clinical interpretation
            if let hrv = student.hrv, let sleep = student.sleepHours {
                let isAtRisk = hrv < 25 || sleep < 5
                HStack(spacing: 8) {
                    Image(systemName: isAtRisk ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(isAtRisk ? .red : Theme.moodGreen)
                    Text(isAtRisk
                         ? "Indicadores de estrés fisiológico elevado. Considerar intervención esta semana."
                         : "Biométricos dentro de rangos aceptables. Mantener seguimiento habitual.")
                        .font(.caption).foregroundStyle(Theme.secondaryText).lineSpacing(2)
                }
                .padding(10)
                .background((isAtRisk ? Color.red : Theme.moodGreen).opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .cardStyle()
    }
}

struct ClinicalMetricTile: View {
    let icon: String; let label: String
    let value: String; let subtitle: String; let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon).font(.caption.bold()).foregroundStyle(color)
            Text(value).font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
            Text(label).font(.caption2).foregroundStyle(Theme.secondaryText)
            Text(subtitle).font(.caption2.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ScoreCard: View {
    let label: String
    let score: Int
    let max: Int
    let thresholds: (Int, Int, Int)

    private var color: Color {
        if score < thresholds.0 { return Theme.moodGreen }
        if score < thresholds.1 { return Theme.moodYellow }
        if score < thresholds.2 { return .orange }
        return Theme.crisisRed
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(Theme.secondaryText)
            Text("\(score)")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(color)
            Text("de \(max)")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
            ProgressView(value: Double(score), total: Double(max))
                .tint(color)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

enum StudentStatus: Equatable {
    case good, warning, crisis
    var color: Color {
        switch self { case .good: Theme.moodGreen; case .warning: Theme.moodYellow; case .crisis: Theme.crisisRed }
    }
    var label: String {
        switch self { case .good: "Estable"; case .warning: "Atención"; case .crisis: "Crisis" }
    }
}

struct StudentMock: Identifiable {
    let id = UUID()
    let name: String; let initials: String; let status: StudentStatus
    let lastSeen: String; let moodHistory: [Int]
    let phq9: Int; let gad7: Int; let topics: [String]
    // Biometrics (shared from Apple Health via consent)
    let sleepHours: Double?; let sleepQuality: String?
    let hrv: Double?; let restingHR: Double?; let o2: Double?
    let steps: Int?; let wellnessScore: Int?

    static let all: [StudentMock] = [
        StudentMock(name: "Sofía M.", initials: "SM", status: .warning, lastSeen: "Ayer",
                    moodHistory: [6,7,5,4,6,5,7,6,5,4,5,6,7,6,5,4,5,6,5,4,5,6,7,6,5,4,5,6,5,4],
                    phq9: 8, gad7: 11, topics: ["Presión académica", "Insomnio", "Relaciones", "Exámenes"],
                    sleepHours: 5.5, sleepQuality: "Regular", hrv: 28, restingHR: 74, o2: 97, steps: 4200, wellnessScore: 52),
        StudentMock(name: "Mateo R.", initials: "MR", status: .crisis, lastSeen: "Hoy",
                    moodHistory: [5,4,3,2,3,2,3,4,3,2,1,2,3,2,1,2,3,4,3,2,1,2,3,2,1,2,3,2,1,2],
                    phq9: 18, gad7: 14, topics: ["Conflictos familiares", "Bullying", "Aislamiento"],
                    sleepHours: 3.8, sleepQuality: "Insuficiente", hrv: 14, restingHR: 88, o2: 95, steps: 1100, wellnessScore: 21),
        StudentMock(name: "Valentina C.", initials: "VC", status: .good, lastSeen: "Hace 3 días",
                    moodHistory: [7,8,7,8,9,8,7,8,7,8,7,8,9,8,7,8,7,8,7,8,7,8,9,8,7,8,7,8,7,8],
                    phq9: 3, gad7: 4, topics: ["Adaptación universitaria", "Relaciones"],
                    sleepHours: 7.8, sleepQuality: "Bueno", hrv: 58, restingHR: 62, o2: 99, steps: 9800, wellnessScore: 84),
    ]
}
