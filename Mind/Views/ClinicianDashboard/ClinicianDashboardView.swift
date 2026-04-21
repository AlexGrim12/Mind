import SwiftUI
import SwiftData
import Charts

struct ClinicianDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    private let students = StudentMock.all

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // Encabezado Zen
                    ToriiHeader(title: "Panel de Guía", subtitle: "Dra. Laura Rivera", kanji: "師")
                        .padding(.top, 20)

                    // Stats summary
                    HStack(spacing: 12) {
                        ClinicalSummaryZenCard(title: "Activos", value: "\(students.count)", kanji: "徒", color: Theme.ai)
                        ClinicalSummaryZenCard(title: "Alertas", value: "\(students.filter { $0.status == .crisis }.count)", kanji: "急", color: Theme.aka)
                        ClinicalSummaryZenCard(title: "Estables", value: "\(students.filter { $0.status == .good }.count)", kanji: "静", color: Theme.matchaDeep)
                    }
                    .padding(.horizontal, 20)

                    // Student list
                    VStack(alignment: .leading, spacing: 16) {
                        zenSectionHeader(title: "Alumnos a Cargo", subtitle: "Sincronía en el camino")
                        
                        ForEach(students) { student in
                            NavigationLink {
                                StudentDetailZenView(student: student)
                            } label: {
                                StudentZenCard(student: student)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 120)
                }
            }
            .screenBackground()
            .navigationTitle("Portal Clínico · 師")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.sumiSoft)
                }
            }
        }
    }
}

struct StudentZenCard: View {
    let student: StudentMock

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                EnsoCircle(color: student.status.color, lineWidth: 1.5)
                    .frame(width: 52, height: 52)
                Text(student.initials)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Theme.sumi)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(student.name)
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    // Mini trend Zen
                    MiniZenSparkline(values: Array(student.moodHistory.suffix(7)), color: student.status.color)
                        .frame(width: 50, height: 20)
                }
                HStack(spacing: 8) {
                    HankoLabelZen(status: student.status)
                    Text("· \(student.lastSeen)")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(Theme.sumiSoft)
                }
            }
        }
        .cardStyle()
    }
}

struct MiniZenSparkline: View {
    let values: [Int]
    let color: Color

    var body: some View {
        Chart {
            ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                LineMark(x: .value("i", i), y: .value("v", v))
                    .foregroundStyle(color.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...10)
    }
}

struct HankoLabelZen: View {
    let status: StudentStatus

    var body: some View {
        Text(status.label)
            .font(.system(size: 9, weight: .bold, design: .serif))
            .foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(status.color.opacity(0.9), in: RoundedRectangle(cornerRadius: 3))
    }
}

struct StudentDetailZenView: View {
    let student: StudentMock

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Perfil del Alumno
                VStack(spacing: 16) {
                    ZStack {
                        EnsoCircle(color: student.status.color, lineWidth: 2)
                            .frame(width: 100, height: 100)
                        Text(student.initials)
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundStyle(Theme.sumi)
                    }
                    
                    VStack(spacing: 4) {
                        Text(student.name)
                            .font(.system(.title2, design: .serif).bold())
                        HankoLabelZen(status: student.status)
                    }
                }
                .padding(.top, 20)

                // Crisis banner Zen
                if student.status == .crisis {
                    HStack(spacing: 12) {
                        HankoStamp(kanji: "急", color: .white, size: 24)
                        Text("Atención Prioritaria: Alerta de Crisis Detectada")
                            .font(.system(.subheadline, design: .serif).bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Theme.crisisRed)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }

                // Chart Zen
                VStack(alignment: .leading, spacing: 16) {
                    zenSectionHeader(title: "Ritmo Emocional", subtitle: "Tendencia de los últimos 30 días")
                    Chart {
                        ForEach(Array(student.moodHistory.enumerated()), id: \.offset) { i, v in
                            AreaMark(x: .value("Día", i), yStart: .value("Min", 0), yEnd: .value("Score", v))
                                .foregroundStyle(LinearGradient(colors: [student.status.color.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                                .interpolationMethod(.catmullRom)
                            LineMark(x: .value("Día", i), y: .value("Score", v))
                                .foregroundStyle(student.status.color)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                                .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartYScale(domain: 0...10)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(values: [0, 5, 10]) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Theme.inkLine)
                            AxisValueLabel().font(.system(.caption2, design: .serif))
                        }
                    }
                    .frame(height: 160)
                }
                .cardStyle()
                .padding(.horizontal, 20)

                // Wellness Zen
                if let ws = student.wellnessScore {
                    StudentWellnessZenCard(student: student, wellnessScore: ws)
                        .padding(.horizontal, 20)
                }

                // Scores Zen
                HStack(spacing: 12) {
                    ScoreZenCard(label: "PHQ-9", score: student.phq9, max: 27, thresholds: (5, 10, 15))
                    ScoreZenCard(label: "GAD-7", score: student.gad7, max: 21, thresholds: (5, 10, 15))
                }
                .padding(.horizontal, 20)

                // Topics Zen
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        zenSectionHeader(title: "Temas del Camino", subtitle: "Conceptos clave del diario")
                        Spacer()
                        HankoStamp(kanji: "題", color: Theme.ai, size: 24)
                    }
                    FlowLayout(spacing: 10) {
                        ForEach(student.topics, id: \.self) { t in
                            Text(t)
                                .font(.system(.caption, design: .serif).bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Theme.kinari.opacity(0.6))
                                .foregroundStyle(Theme.ai)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Theme.inkLine, lineWidth: 0.5))
                        }
                    }
                }
                .cardStyle()
                .padding(.horizontal, 20)

                Spacer(minLength: 80)
            }
        }
        .screenBackground()
        .navigationTitle("Detalle · 徒")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: — Student wellness Zen (clinician view)

struct StudentWellnessZenCard: View {
    let student: StudentMock
    let wellnessScore: Int

    private var wsColor: Color {
        if wellnessScore >= 75 { return Theme.matchaDeep }
        if wellnessScore >= 50 { return Theme.ai }
        if wellnessScore >= 30 { return Theme.tamago }
        return Theme.crisisRed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Vitalidad del Espíritu").font(.system(.headline, design: .serif))
                Spacer()
                HankoStamp(kanji: "康", color: wsColor, size: 24)
            }

            HStack(spacing: 24) {
                ZStack {
                    EnsoCircle(color: wsColor, lineWidth: 3)
                        .frame(width: 70, height: 70)
                    Text("\(wellnessScore)")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.sumi)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Puntos Zen").font(.system(.subheadline, design: .serif).bold())
                    Text(wellnessScore >= 75 ? "Armonía total" : "En equilibrio").font(.system(.caption, design: .serif)).foregroundStyle(Theme.sumiSoft)
                }
                Spacer()
            }

            Divider().background(Theme.inkLine)

            // Grid minimal
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricZenTile(title: "Sueño", value: String(format: "%.1fh", student.sleepHours ?? 0), unit: "", color: Theme.ai)
                MetricZenTile(title: "HRV", value: String(format: "%.0f", student.hrv ?? 0), unit: "ms", color: Theme.moodPurple)
                MetricZenTile(title: "FC Rep", value: "\(Int(student.restingHR ?? 0))", unit: "bpm", color: Theme.aka)
            }
        }
        .cardStyle()
    }
}

struct ScoreZenCard: View {
    let label: String
    let score: Int
    let max: Int
    let thresholds: (Int, Int, Int)

    private var color: Color {
        if score < thresholds.0 { return Theme.matchaDeep }
        if score < thresholds.1 { return Theme.ai }
        if score < thresholds.2 { return Theme.tamago }
        return Theme.crisisRed
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(label).font(.system(.caption, design: .serif).bold()).foregroundStyle(Theme.sumiSoft)
            ZStack {
                EnsoCircle(color: color.opacity(0.3), lineWidth: 1.5).frame(width: 60, height: 60)
                Text("\(score)").font(.system(size: 24, weight: .bold, design: .serif)).foregroundStyle(Theme.sumi)
            }
            Text("de \(max)").font(.system(.caption2, design: .serif)).foregroundStyle(Theme.sumiSoft)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

// MARK: — Models

enum StudentStatus: Equatable {
    case good, warning, crisis
    var color: Color {
        switch self { case .good: Theme.matcha; case .warning: Theme.tamago; case .crisis: Theme.crisisRed }
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
    // Biometría compartida (simulada)
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
