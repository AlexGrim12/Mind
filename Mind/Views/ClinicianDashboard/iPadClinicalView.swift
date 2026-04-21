import SwiftUI
import Charts

// MARK: - Models

/// Modelo de datos para un paciente.
struct ClinicalPatient: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let matricula: String
    let moodTrend: [ClinicalMoodEntry]
    let tags: [String]
    let summary: String
    
    static let mockSofia = ClinicalPatient(
        name: "Sofía M.",
        matricula: "31920442",
        moodTrend: [
            ClinicalMoodEntry(day: "Lun", value: 7),
            ClinicalMoodEntry(day: "Mar", value: 6),
            ClinicalMoodEntry(day: "Mie", value: 8),
            ClinicalMoodEntry(day: "Jue", value: 5),
            ClinicalMoodEntry(day: "Vie", value: 4),
            ClinicalMoodEntry(day: "Sab", value: 3),
            ClinicalMoodEntry(day: "Dom", value: 2)
        ],
        tags: ["Ansiedad", "Insomnio", "Exámenes", "Aislamiento"],
        summary: "Se observa una tendencia de ánimo a la baja coincidiendo con el periodo de exámenes finales. Las notas del diario sugieren falta de sueño y aumento de estrés social."
    )
    
    static let allMocks = [
        mockSofia,
        ClinicalPatient(name: "Carlos T.", matricula: "31850221", moodTrend: [], tags: ["Progreso", "Social"], summary: "Buen progreso en las últimas sesiones."),
        ClinicalPatient(name: "Ana P.", matricula: "31910553", moodTrend: [], tags: ["Autoestima"], summary: "Trabajando en validación interna.")
    ]
}

/// Entrada de estado de ánimo para el gráfico.
struct ClinicalMoodEntry: Identifiable, Hashable {
    let id = UUID()
    let day: String
    let value: Int
}

struct ClinicalCalendarSession: Identifiable {
    let id = UUID()
    let patientName: String
    let avatarLetter: String
    let time: String
    let type: SessionType
    let status: SessionStatus

    enum SessionType: String {
        case followUp  = "Seguimiento"
        case evaluation = "Evaluación"
        case crisis    = "Crisis"
        case firstVisit = "Inicial"

        var color: Color {
            switch self {
            case .followUp:   return Theme.ai
            case .evaluation: return Theme.asagi
            case .crisis:     return Theme.crisisRed
            case .firstVisit: return Theme.matchaDeep
            }
        }
        var icon: String {
            switch self {
            case .followUp:   return "arrow.triangle.2.circlepath"
            case .evaluation: return "checkmark.circle.fill"
            case .crisis:     return "exclamationmark.triangle.fill"
            case .firstVisit: return "person.badge.plus.fill"
            }
        }
    }

    enum SessionStatus: String {
        case upcoming  = "Próxima"
        case completed = "Completada"
        case cancelled = "Cancelada"

        var color: Color {
            switch self {
            case .upcoming:  return Theme.ai
            case .completed: return Theme.matchaDeep
            case .cancelled: return Theme.sumiSoft
            }
        }
    }
}

// MARK: - Navigation Enums

enum ClinicalSidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case patients = "Pacientes"
    case calendar = "Calendario"
    case settings = "Configuración"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .patients: return "person.2.fill"
        case .calendar: return "calendar"
        case .settings: return "gearshape.fill"
        }
    }

    var kanji: String {
        switch self {
        case .dashboard: return "師"
        case .patients: return "徒"
        case .calendar: return "契"
        case .settings: return "設"
        }
    }
}

// MARK: - Main View

struct iPadClinicalView: View {
    @State private var selectedItem: ClinicalSidebarItem? = .dashboard
    @State private var selectedPatient: ClinicalPatient?
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ZStack {
                Theme.kinari.opacity(0.3).ignoresSafeArea()
                List(ClinicalSidebarItem.allCases, selection: $selectedItem) { item in
                    NavigationLink(value: item) {
                        HStack {
                            Label(item.rawValue, systemImage: item.icon)
                            Spacer()
                            Text(item.kanji).font(.system(size: 14, design: .serif)).foregroundStyle(Theme.sumiSoft)
                        }
                    }
                }
                .navigationTitle("MIND-LINK")
                .listStyle(.sidebar)
            }
        } detail: {
            NavigationStack {
                ZStack {
                    Theme.ambientBackground.ignoresSafeArea()
                    
                    Group {
                        if let selectedItem {
                            switch selectedItem {
                            case .dashboard:
                                iPadClinicianDashboardZenView(onReviewPatient: {
                                    selectedPatient = ClinicalPatient.mockSofia
                                })
                            case .patients:
                                iPadPatientListZenView(selectedPatient: $selectedPatient)
                            case .calendar:
                                iPadClinicalCalendarZenView()
                            default:
                                Text("En desarrollo").font(.zenHeadline)
                            }
                        } else {
                            VStack(spacing: 20) {
                                EnsoCircle(color: Theme.sumiSoft, lineWidth: 1).frame(width: 80, height: 80)
                                Text("Selecciona una opción del pergamino").font(.zenHeadline).foregroundStyle(Theme.sumiSoft)
                            }
                        }
                    }
                    .navigationDestination(item: $selectedPatient) { patient in
                        iPadPatientDetailZenView(patient: patient)
                    }
                }
            }
        }
    }
}

// MARK: - Subviews Zen

struct iPadPatientListZenView: View {
    @Binding var selectedPatient: ClinicalPatient?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ToriiHeader(title: "Alumnos", subtitle: "Lista de acompañamiento", kanji: "徒")
                    .padding(.top, 24)

                LazyVStack(spacing: 12) {
                    ForEach(ClinicalPatient.allMocks) { patient in
                        Button {
                            selectedPatient = patient
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    EnsoCircle(color: Theme.ai, lineWidth: 1).frame(width: 44, height: 44)
                                    Text(patient.name.prefix(1)).font(.system(.headline, design: .serif)).foregroundStyle(Theme.sumi)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(patient.name).font(.zenHeadline).foregroundStyle(Theme.textPrimary)
                                    Text(patient.matricula).font(.zenCaption).foregroundStyle(Theme.sumiSoft)
                                }
                                
                                Spacer()
                                
                                if patient.name == "Sofía M." {
                                    HankoStamp(kanji: "急", color: Theme.aka, size: 24)
                                }
                                
                                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Theme.sumiSoft)
                            }
                            .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

struct iPadClinicianDashboardZenView: View {
    var onReviewPatient: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bienvenida,")
                            .font(.zenHeadline)
                            .foregroundStyle(Theme.sumiSoft)
                        Text("Dra. Laura Rivera")
                            .font(.system(size: 48, weight: .black, design: .serif))
                            .foregroundStyle(Theme.sumi)
                        
                        InkBrushDivider().frame(width: 200).padding(.top, 4)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.zenCaption).bold()
                        Label("IA Activa · Local", systemImage: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.matchaDeep)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Theme.matcha.opacity(0.1), in: Capsule())
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
                    ClinicalSummaryZenCard(title: "Alumnos Activos", value: "24", kanji: "徒", color: Theme.ai)
                    ClinicalSummaryZenCard(title: "Sesiones Hoy", value: "6", kanji: "会", color: Theme.matchaDeep)
                    ClinicalSummaryZenCard(title: "Alertas", value: "3", kanji: "急", color: Theme.aka)
                }
                .padding(.horizontal, 40)
                
                VStack(alignment: .leading, spacing: 20) {
                    zenSectionHeader(title: "Atención Prioritaria", subtitle: "Alumnos que requieren sincronía inmediata")
                    
                    ClinicalPriorityAlertZenCard(
                        name: "Sofía M.",
                        matricula: "31920442",
                        description: "Tendencia de ánimo en descenso significativo los últimos 3 días.",
                        tags: ["Ansiedad", "Insomnio", "Exámenes"],
                        time: "5 min",
                        action: onReviewPatient
                    )
                }
                .padding(.horizontal, 40)
                
                VStack(alignment: .leading, spacing: 20) {
                    zenSectionHeader(title: "Sesiones de la Mañana", subtitle: "Sincronía agendada")
                    
                    VStack(spacing: 12) {
                        ClinicalSessionZenRow(name: "Carlos T.", time: "09:00", detail: "Seguimiento post-crisis", color: Theme.ai)
                        ClinicalSessionZenRow(name: "Ana P.", time: "10:30", detail: "Evaluación de progreso", color: Theme.matchaDeep)
                    }
                }
                .padding(.horizontal, 40)

                Spacer(minLength: 80)
            }
        }
    }
}

struct iPadPatientDetailZenView: View {
    let patient: ClinicalPatient
    @State private var noteText = ""
    @State private var isSaved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Header Detalle
                HStack(spacing: 24) {
                    ZStack {
                        EnsoCircle(color: Theme.ai, lineWidth: 2.5).frame(width: 100, height: 100)
                        Text(patient.name.prefix(1)).font(.system(size: 44, weight: .bold, design: .serif))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(patient.name).font(.system(size: 40, weight: .bold, design: .serif))
                        Text("Matrícula · \(patient.matricula)").font(.zenHeadline).foregroundStyle(Theme.sumiSoft)
                        
                        let isCritical = patient.moodTrend.last?.value ?? 5 <= 4
                        HStack {
                            Circle().fill(isCritical ? Theme.aka : Theme.matcha).frame(width: 8, height: 8)
                            Text(isCritical ? "Atención Necesaria" : "Camino Estable").font(.zenCaption).bold()
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background((isCritical ? Theme.aka : Theme.matcha).opacity(0.1), in: Capsule())
                    }
                    Spacer()
                }
                .padding(.horizontal, 40).padding(.top, 24)
                
                // Gráfico Zen
                VStack(alignment: .leading, spacing: 16) {
                    zenSectionHeader(title: "Ritmo Emocional", subtitle: "Flujo de los últimos 7 días")
                    
                    if !patient.moodTrend.isEmpty {
                        Chart {
                            ForEach(patient.moodTrend) { entry in
                                AreaMark(x: .value("Día", entry.day), y: .value("Estado", entry.value))
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(LinearGradient(colors: [Theme.ai.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))

                                LineMark(x: .value("Día", entry.day), y: .value("Estado", entry.value))
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(Theme.ai)
                                    .lineStyle(StrokeStyle(lineWidth: 3))

                                PointMark(x: .value("Día", entry.day), y: .value("Estado", entry.value))
                                    .foregroundStyle(entry.value <= 4 ? Theme.aka : Theme.ai)
                                    .symbolSize(60)
                            }
                        }
                        .frame(height: 240)
                        .chartYScale(domain: 0...10)
                        .chartYAxis {
                            AxisMarks(values: [0, 5, 10]) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Theme.inkLine)
                                AxisValueLabel().font(.zenCaption)
                            }
                        }
                        .padding()
                        .cardStyle()
                    }
                }
                .padding(.horizontal, 40)
                
                // IA y Síntesis
                VStack(alignment: .leading, spacing: 20) {
                    zenSectionHeader(title: "Esencia de la IA", subtitle: "Síntesis on-device de patrones")

                    HStack(alignment: .top, spacing: 20) {
                        HankoStamp(kanji: "認", color: Theme.ai, size: 40)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(patient.summary)
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Theme.sumi)
                                .lineSpacing(6)
                            
                            FlowLayout(spacing: 10) {
                                ForEach(patient.tags, id: \.self) { tag in
                                    Text(tag).font(.zenCaption).bold()
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Theme.kinari)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Theme.inkLine, lineWidth: 0.5))
                                }
                            }
                        }
                    }
                    .padding(24)
                    .cardStyle()
                }
                .padding(.horizontal, 40)
                
                // Notas Zen
                VStack(alignment: .leading, spacing: 20) {
                    zenSectionHeader(title: "Bitácora del Guía", subtitle: "Observaciones privadas")

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 16).fill(Theme.cardBackground.opacity(0.8))
                        
                        TextEditor(text: $noteText)
                            .frame(minHeight: 200)
                            .padding(12)
                            .scrollContentBackground(.hidden)
                            .font(.system(.body, design: .serif))
                    }
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.inkLine, lineWidth: 0.5))

                    Button {
                        withAnimation { isSaved = true }
                        Haptics.success()
                    } label: {
                        HStack {
                            if isSaved { Image(systemName: "checkmark") }
                            Text(isSaved ? "Notas Grabadas" : "Grabar en el Pergamino")
                        }
                        .primaryButton(color: isSaved ? Theme.matchaDeep : Theme.ai)
                    }
                }
                .padding(.horizontal, 40)

                Spacer(minLength: 80)
            }
        }
    }
}

// MARK: - Calendar Zen

struct iPadClinicalCalendarZenView: View {
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    private let cal = Calendar.current
    private let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    private var monthDates: [Date?] {
        guard let range = cal.dateInterval(of: .month, for: displayedMonth),
              let weekday = cal.dateComponents([.weekday], from: range.start).weekday else { return [] }
        let offset = weekday - 1
        let count = cal.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        var dates: [Date?] = Array(repeating: nil, count: offset)
        for day in 1...count {
            var comps = cal.dateComponents([.year, .month], from: displayedMonth)
            comps.day = day
            dates.append(cal.date(from: comps))
        }
        while dates.count % 7 != 0 { dates.append(nil) }
        return dates
    }

    var body: some View {
        HStack(spacing: 0) {
            // Calendario
            ScrollView {
                VStack(spacing: 32) {
                    HStack {
                        Button { displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth)! } label: {
                            Image(systemName: "chevron.left").foregroundStyle(Theme.sumi)
                        }
                        Spacer()
                        VStack {
                            Text(displayedMonth.formatted(.dateTime.month(.wide))).font(.zenHeadline)
                            Text(displayedMonth.formatted(.dateTime.year())).font(.zenCaption)
                        }
                        Spacer()
                        Button { displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth)! } label: {
                            Image(systemName: "chevron.right").foregroundStyle(Theme.sumi)
                        }
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(weekdayLabels, id: \.self) { label in
                            Text(label).font(.zenCaption).bold().foregroundStyle(Theme.sumiSoft)
                        }
                        ForEach(Array(monthDates.enumerated()), id: \.offset) { _, date in
                            if let date {
                                CalendarDayZenCell(date: date, isSelected: cal.isDate(date, inSameDayAs: selectedDate))
                                    .onTapGesture { selectedDate = date }
                            } else {
                                Color.clear.frame(height: 40)
                            }
                        }
                    }
                    
                    Divider().background(Theme.inkLine)
                    
                    // Leyenda
                    HStack(spacing: 20) {
                        CalendarLegendZen(label: "Crisis", color: Theme.aka)
                        CalendarLegendZen(label: "Sincronía", color: Theme.ai)
                        CalendarLegendZen(label: "Cerrada", color: Theme.matchaDeep)
                    }
                }
                .padding(32)
            }
            .frame(maxWidth: .infinity)
            
            Divider().background(Theme.inkLine)
            
            // Lista de sesiones del día
            VStack(alignment: .leading, spacing: 24) {
                Text(selectedDate.formatted(.dateTime.day().month(.wide))).font(.zenTitle)
                Text("Encuentros Programados").font(.zenHeadline).foregroundStyle(Theme.sumiSoft)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ClinicalSessionZenRow(name: "Sofía M.", time: "09:00", detail: "Crisis", color: Theme.aka)
                        ClinicalSessionZenRow(name: "Carlos T.", time: "10:30", detail: "Seguimiento", color: Theme.ai)
                    }
                }
            }
            .padding(32)
            .frame(width: 400)
            .background(Theme.cardBackground.opacity(0.4))
        }
    }
}

struct CalendarDayZenCell: View {
    let date: Date
    let isSelected: Bool
    var body: some View {
        ZStack {
            if isSelected {
                EnsoCircle(color: Theme.ai, lineWidth: 1.5).frame(width: 40, height: 40)
            }
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(.body, design: .serif))
                .foregroundStyle(isSelected ? Theme.ai : Theme.sumi)
        }
        .frame(height: 40)
    }
}

struct CalendarLegendZen: View {
    let label: String; let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.zenCaption).foregroundStyle(Theme.sumiSoft)
        }
    }
}

#Preview {
    iPadClinicalView()
}
