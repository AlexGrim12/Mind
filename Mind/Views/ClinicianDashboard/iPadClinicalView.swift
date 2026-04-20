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
            case .followUp:   return .indigo
            case .evaluation: return .teal
            case .crisis:     return .red
            case .firstVisit: return .orange
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
            case .upcoming:  return .blue
            case .completed: return .green
            case .cancelled: return .secondary
            }
        }
    }
}

// MARK: - Navigation Enums

/// Representa las opciones de navegación del portal clínico para iPad.
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
}

// MARK: - Main View

struct iPadClinicalView: View {
    @State private var selectedItem: ClinicalSidebarItem? = .dashboard
    @State private var selectedPatient: ClinicalPatient?
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(ClinicalSidebarItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                }
            }
            .navigationTitle("MIND-LINK")
            .listStyle(.sidebar)
        } detail: {
            NavigationStack {
                Group {
                    if let selectedItem {
                        switch selectedItem {
                        case .dashboard:
                            iPadClinicianDashboardView(onReviewPatient: {
                                selectedPatient = ClinicalPatient.mockSofia
                            })
                            .navigationTitle("Dashboard")
                        case .patients:
                            iPadPatientListView(selectedPatient: $selectedPatient)
                                .navigationTitle("Pacientes")
                        case .calendar:
                            iPadClinicalCalendarView()
                                .navigationTitle("Calendario")
                        default:
                            iPadClinicalDetailView(item: selectedItem)
                        }
                    } else {
                        ContentUnavailableView("Selecciona una opción", systemImage: "sidebar.left")
                    }
                }
                .navigationDestination(item: $selectedPatient) { patient in
                    iPadPatientDetailView(patient: patient)
                }
            }
        }
    }
}

// MARK: - Subviews

struct iPadPatientListView: View {
    @Binding var selectedPatient: ClinicalPatient?
    
    var body: some View {
        List(ClinicalPatient.allMocks) { patient in
            Button {
                selectedPatient = patient
            } label: {
                HStack {
                    Circle()
                        .fill(.indigo.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(Text(patient.name.prefix(1)).fontWeight(.bold).foregroundStyle(.indigo))
                    
                    VStack(alignment: .leading) {
                        Text(patient.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(patient.matricula)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if patient.name == "Sofía M." {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}

struct iPadClinicianDashboardView: View {
    var onReviewPatient: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bienvenida de nuevo,")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Dra. Rivera")
                            .font(.system(size: 44, weight: .black))
                        Label("Portal Clínico · MIND-LINK", systemImage: "brain.filled.head.profile")
                            .font(.caption)
                            .foregroundStyle(.indigo.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Label("IA activa · On-Device", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ClinicalSummaryCard(title: "Pacientes Activos", value: "24", icon: "person.3.fill", color: .blue)
                    ClinicalSummaryCard(title: "Sesiones Hoy", value: "6", icon: "calendar.badge.clock", color: .green)
                    ClinicalSummaryCard(title: "Alertas Pendientes", value: "3", icon: "exclamationmark.triangle.fill", color: .orange)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Alertas Prioritarias")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ClinicalPriorityAlertCard(
                        name: "Sofía M.",
                        matricula: "31920442",
                        description: "Tendencia de ánimo en descenso significativo los últimos 3 días.",
                        tags: ["Ansiedad", "Insomnio", "Exámenes"],
                        time: "Hace 5 min",
                        action: onReviewPatient
                    )
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sesiones de la Mañana")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        ClinicalSessionRow(name: "Carlos T.", time: "09:00 AM", detail: "Seguimiento post-crisis")
                        ClinicalSessionRow(name: "Ana P.", time: "10:30 AM", detail: "Evaluación de progreso")
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct iPadPatientDetailView: View {
    let patient: ClinicalPatient

    @State private var noteText = ""
    @State private var isSaved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack(spacing: 20) {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(LinearGradient(colors: [.indigo.opacity(0.2), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 88, height: 88)
                            .overlay(
                                Text(patient.name.prefix(1))
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundStyle(.indigo)
                            )
                        let isCritical = patient.moodTrend.last?.value ?? 5 <= 4
                        if isCritical {
                            Circle()
                                .fill(.red)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: "exclamationmark")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundStyle(.white)
                                )
                                .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(patient.name)
                            .font(.system(size: 34, weight: .bold))
                        Text("Matrícula · \(patient.matricula)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        let isCritical = patient.moodTrend.last?.value ?? 5 <= 4
                        Label(isCritical ? "Requiere atención" : "Estado estable", systemImage: isCritical ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(isCritical ? .red : .green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background((isCritical ? Color.red : Color.green).opacity(0.10))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Label("Tendencia de Ánimo · 7 días", systemImage: "waveform.path.ecg.rectangle.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !patient.moodTrend.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Últimos 7 días", systemImage: "waveform.path.ecg")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                let last = patient.moodTrend.last?.value ?? 5
                                Label(last <= 4 ? "Tendencia crítica" : "Estable", systemImage: last <= 4 ? "arrow.down.circle.fill" : "checkmark.circle.fill")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(last <= 4 ? .red : .green)
                            }
                            .padding(.horizontal, 4)

                            Chart {
                                ForEach(patient.moodTrend) { entry in
                                    AreaMark(
                                        x: .value("Día", entry.day),
                                        y: .value("Estado", entry.value)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.indigo.opacity(0.25), Color.indigo.opacity(0.0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                    LineMark(
                                        x: .value("Día", entry.day),
                                        y: .value("Estado", entry.value)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(Color.indigo)
                                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                                    PointMark(
                                        x: .value("Día", entry.day),
                                        y: .value("Estado", entry.value)
                                    )
                                    .foregroundStyle(entry.value <= 4 ? Color.red : Color.indigo)
                                    .symbolSize(entry.value <= 4 ? 90 : 55)
                                    .annotation(position: .top, spacing: 4) {
                                        Text("\(entry.value)")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(entry.value <= 4 ? .red : .indigo)
                                    }
                                }

                                RuleMark(y: .value("Umbral", 4))
                                    .foregroundStyle(.red.opacity(0.6))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                    .annotation(position: .bottom, alignment: .trailing, spacing: 2) {
                                        Text("Umbral de alerta")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(.red.opacity(0.8))
                                    }
                            }
                            .frame(height: 220)
                            .chartLegend(.hidden)
                            .chartYScale(domain: 0...10)
                            .chartYAxis {
                                AxisMarks(values: [0, 2, 4, 6, 8, 10]) {
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                        .foregroundStyle(Color.secondary.opacity(0.2))
                                    AxisValueLabel()
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            .chartXAxis {
                                AxisMarks {
                                    AxisValueLabel()
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        ContentUnavailableView("Sin datos de tendencia", systemImage: "waveform.path.ecg")
                            .frame(height: 200)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Label("Síntesis de IA · On-Device", systemImage: "brain.head.profile")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.indigo)
                            .frame(width: 3)
                        Text(patient.summary)
                            .font(.body)
                            .foregroundStyle(.primary.opacity(0.85))
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(colors: [.indigo.opacity(0.06), .purple.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.indigo.opacity(0.12), lineWidth: 1))

                    Text("Etiquetas de Análisis")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    ClinicalFlowLayout(spacing: 10) {
                        ForEach(patient.tags, id: \.self) { tag in
                            ClinicalTagBadge(tag: tag)
                        }
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notas Privadas")
                        .font(.title2)
                        .fontWeight(.bold)

                    ZStack(alignment: .topLeading) {
                        if noteText.isEmpty {
                            Text("Escribe tus observaciones pre-sesión aquí...")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                        }
                        TextEditor(text: $noteText)
                            .frame(minHeight: 180)
                            .scrollContentBackground(.hidden)
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: noteText) { isSaved = false }

                    if isSaved {
                        Label("Notas guardadas", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSaved = true
                        }
                    } label: {
                        Label("Guardar Notas", systemImage: "square.and.arrow.down")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.indigo)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .sensoryFeedback(.success, trigger: isSaved)
                }
                .padding(.horizontal)

                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Views & Layouts

struct ClinicalSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                }
                Spacer()
            }
            Text(value)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: color.opacity(0.10), radius: 10, x: 0, y: 4)
    }
}

struct ClinicalPriorityAlertCard: View {
    let name: String
    let matricula: String
    let description: String
    let tags: [String]
    let time: String
    var action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.2))
                        .frame(width: 12, height: 12)
                        .scaleEffect(isPulsing ? 1.8 : 1.0)
                        .opacity(isPulsing ? 0 : 1)
                        .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: isPulsing)
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                }
                .onAppear { isPulsing = true }

                Text("ATENCIÓN REQUERIDA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
                    .tracking(0.5)
                Spacer()
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.red.opacity(0.2), .orange.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                    Text(name.prefix(1))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Matrícula: \(matricula)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            ClinicalFlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    ClinicalTagBadge(tag: tag)
                }
            }

            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .fontWeight(.semibold)
                    Text("Revisar Síntesis de IA")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.indigo)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.red.opacity(0.04), Color(UIColor.secondarySystemGroupedBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.red.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: .red.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

struct ClinicalSessionRow: View {
    let name: String
    let time: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Text(time)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Circle()
                    .fill(.indigo)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 70)
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct iPadClinicalDetailView: View {
    let item: ClinicalSidebarItem
    
    var body: some View {
        VStack {
            Text("Contenido de \(item.rawValue)")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .navigationTitle(item.rawValue)
    }
}

// MARK: - Calendar

struct iPadClinicalCalendarView: View {
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()

    private let cal = Calendar.current
    private let weekdayLabels = ["D", "L", "M", "X", "J", "V", "S"]

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
        VStack(spacing: 0) {
            calendarGrid
            Divider()
            sessionStrip
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: Top – calendar grid

    private var calendarGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 38, height: 38)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .clipShape(Circle())
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(displayedMonth.formatted(.dateTime.month(.wide)))
                            .font(.title2).fontWeight(.bold)
                        Text(displayedMonth.formatted(.dateTime.year()))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 38, height: 38)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                }

                HStack(spacing: 0) {
                    ForEach(weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                    ForEach(Array(monthDates.enumerated()), id: \.offset) { _, date in
                        if let date {
                            ClinicalCalendarDayCell(
                                date: date,
                                isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                                isToday: cal.isDateInToday(date),
                                sessions: sessionsFor(date)
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) { selectedDate = date }
                            }
                        } else {
                            Color.clear.frame(height: 58)
                        }
                    }
                }

                HStack(spacing: 16) {
                    ForEach([
                        ("Crisis", Color.red),
                        ("Seguimiento", Color.indigo),
                        ("Evaluación", Color.teal),
                        ("Inicial", Color.orange)
                    ], id: \.0) { item in
                        HStack(spacing: 5) {
                            Circle().fill(item.1).frame(width: 7, height: 7)
                            Text(item.0).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: Bottom – horizontal session strip

    private var sessionStrip: some View {
        let sessions = sessionsFor(selectedDate)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide)).capitalized)
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary).tracking(0.5)
                    Text(selectedDate.formatted(.dateTime.day().month(.wide)))
                        .font(.title3).fontWeight(.bold)
                }

                Spacer()

                if !sessions.isEmpty {
                    HStack(spacing: 8) {
                        ClinicalCalendarPill(value: "\(sessions.count)", label: "sesiones", color: .indigo)
                        if sessions.contains(where: { $0.type == .crisis }) {
                            ClinicalCalendarPill(value: "\(sessions.filter { $0.type == .crisis }.count)", label: "urgentes", color: .red)
                        }
                        if sessions.contains(where: { $0.status == .completed }) {
                            ClinicalCalendarPill(value: "\(sessions.filter { $0.status == .completed }.count)", label: "completadas", color: .green)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            if sessions.isEmpty {
                HStack {
                    Spacer()
                    Label("Sin sesiones para este día", systemImage: "calendar")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.bottom, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sessions) { session in
                            ClinicalCalendarSessionCard(session: session)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    private func sessionsFor(_ date: Date) -> [ClinicalCalendarSession] {
        let offset = cal.dateComponents([.day],
            from: cal.startOfDay(for: Date()),
            to: cal.startOfDay(for: date)).day ?? 0
        switch offset {
        case 0:  return [
            ClinicalCalendarSession(patientName: "Sofía M.",  avatarLetter: "S", time: "09:00", type: .crisis,     status: .upcoming),
            ClinicalCalendarSession(patientName: "Carlos T.", avatarLetter: "C", time: "10:30", type: .followUp,   status: .upcoming),
            ClinicalCalendarSession(patientName: "Ana P.",    avatarLetter: "A", time: "12:00", type: .evaluation, status: .upcoming),
        ]
        case -1: return [
            ClinicalCalendarSession(patientName: "Carlos T.", avatarLetter: "C", time: "09:00", type: .followUp,   status: .completed),
            ClinicalCalendarSession(patientName: "Martín R.", avatarLetter: "M", time: "11:00", type: .firstVisit, status: .completed),
        ]
        case -3: return [
            ClinicalCalendarSession(patientName: "Ana P.", avatarLetter: "A", time: "10:00", type: .evaluation, status: .completed),
        ]
        case -5: return [
            ClinicalCalendarSession(patientName: "Laura V.", avatarLetter: "L", time: "14:00", type: .firstVisit, status: .completed),
        ]
        case 1: return [
            ClinicalCalendarSession(patientName: "Sofía M.", avatarLetter: "S", time: "09:30", type: .followUp, status: .upcoming),
        ]
        case 3: return [
            ClinicalCalendarSession(patientName: "Laura V.", avatarLetter: "L", time: "11:00", type: .firstVisit, status: .upcoming),
            ClinicalCalendarSession(patientName: "Carlos T.", avatarLetter: "C", time: "14:00", type: .followUp,  status: .upcoming),
        ]
        case 7: return [
            ClinicalCalendarSession(patientName: "Ana P.",   avatarLetter: "A", time: "10:00", type: .evaluation, status: .upcoming),
            ClinicalCalendarSession(patientName: "Sofía M.", avatarLetter: "S", time: "12:30", type: .followUp,   status: .upcoming),
        ]
        default: return []
        }
    }
}

struct ClinicalCalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let sessions: [ClinicalCalendarSession]

    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Circle().fill(Color.indigo).frame(width: 38, height: 38)
                } else if isToday {
                    Circle().strokeBorder(Color.indigo, lineWidth: 2).frame(width: 38, height: 38)
                }
                Text("\(cal.component(.day, from: date))")
                    .font(.system(size: 16, weight: (isToday || isSelected) ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : isToday ? .indigo : .primary)
            }
            .frame(width: 38, height: 38)

            HStack(spacing: 3) {
                ForEach(Array(sessions.prefix(3).enumerated()), id: \.offset) { _, s in
                    Circle().fill(s.type.color).frame(width: 5, height: 5)
                }
            }
            .frame(height: 7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .contentShape(Rectangle())
    }
}

struct ClinicalCalendarSessionCard: View {
    let session: ClinicalCalendarSession

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            session.type.color
                .frame(height: 4)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(session.time)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                    Spacer()
                    Image(systemName: session.type.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(session.type.color)
                }

                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(session.type.color.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Text(session.avatarLetter)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(session.type.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.patientName)
                            .font(.subheadline).fontWeight(.semibold)
                            .lineLimit(1)
                        Text(session.type.rawValue)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(session.status.rawValue)
                    .font(.caption).fontWeight(.medium)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(session.status.color.opacity(0.12))
                    .foregroundStyle(session.status.color)
                    .clipShape(Capsule())
            }
            .padding(14)
        }
        .frame(width: 186, height: 166)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(session.type.color.opacity(0.15), lineWidth: 1))
    }
}

struct ClinicalCalendarPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ClinicalTagBadge: View {
    let tag: String

    private var color: Color {
        switch tag.lowercased() {
        case let t where t.contains("ansiedad") || t.contains("crisis"): return .red
        case let t where t.contains("insomnio") || t.contains("aislamiento"): return .orange
        case let t where t.contains("examen") || t.contains("estrés"): return .yellow
        case let t where t.contains("progreso") || t.contains("social"): return .green
        case let t where t.contains("autoestima"): return .teal
        default: return .indigo
        }
    }

    var body: some View {
        Text(tag)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct ClinicalFlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
            height = y + maxHeight
        }
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}

#Preview {
    iPadClinicalView()
}
