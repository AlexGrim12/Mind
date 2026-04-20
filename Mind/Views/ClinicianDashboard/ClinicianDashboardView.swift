import SwiftUI
import Charts

struct ClinicianDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    private let students = StudentMock.all

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

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
        .background(Theme.background)
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.inline)
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

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let w = proposal.width ?? .infinity
        var h: CGFloat = 0; var rowW: CGFloat = 0; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if rowW + s.width > w { h += rowH + spacing; rowW = 0; rowH = 0 }
            rowW += s.width + spacing; rowH = max(rowH, s.height)
        }
        return CGSize(width: w, height: h + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
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

    static let all: [StudentMock] = [
        StudentMock(name: "Sofía M.", initials: "SM", status: .warning, lastSeen: "Ayer",
                    moodHistory: [6,7,5,4,6,5,7,6,5,4,5,6,7,6,5,4,5,6,5,4,5,6,7,6,5,4,5,6,5,4],
                    phq9: 8, gad7: 11, topics: ["Presión académica", "Insomnio", "Relaciones", "Exámenes"]),
        StudentMock(name: "Mateo R.", initials: "MR", status: .crisis, lastSeen: "Hoy",
                    moodHistory: [5,4,3,2,3,2,3,4,3,2,1,2,3,2,1,2,3,4,3,2,1,2,3,2,1,2,3,2,1,2],
                    phq9: 18, gad7: 14, topics: ["Conflictos familiares", "Bullying", "Aislamiento"]),
        StudentMock(name: "Valentina C.", initials: "VC", status: .good, lastSeen: "Hace 3 días",
                    moodHistory: [7,8,7,8,9,8,7,8,7,8,7,8,9,8,7,8,7,8,7,8,7,8,9,8,7,8,7,8,7,8],
                    phq9: 3, gad7: 4, topics: ["Adaptación universitaria", "Relaciones"]),
    ]
}
