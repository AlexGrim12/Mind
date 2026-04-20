import SwiftUI
import SwiftData
import Foundation

struct HomeView: View {
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @EnvironmentObject private var watchService: WatchConnectivityService
    @StateObject private var healthKit = HealthKitService.shared

    @State private var showCheckin = false
    @State private var showJournal = false
    @State private var showQuestionnaire = false
    @State private var headerAppeared = false

    private var todayEntry: MoodEntry? {
        moodEntries.first { Calendar.current.isDateInToday($0.date) }
    }
    private var nextAppointment: Appointment? { appointments.first { $0.isUpcoming } }
    private var watchContextSignature: String {
        let todayMood = todayEntry?.score ?? -1
        let nextApptTime = nextAppointment?.date.timeIntervalSince1970 ?? -1
        return "\(moodEntries.count)-\(appointments.count)-\(todayMood)-\(nextApptTime)"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HeroHeader(entry: todayEntry, appeared: headerAppeared)

                    VStack(spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Tu día")
                                    .font(.title3.bold())
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Registra, reflexiona y prepárate")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            Spacer()
                        }
                        .staggered(0)

                        if let entry = todayEntry {
                            TodayMoodCard(entry: entry, onCheckin: { showCheckin = true })
                                .staggered(1)
                        } else {
                            CheckinBanner(action: { showCheckin = true })
                                .staggered(1)
                        }

                        JournalCard(action: { showJournal = true })
                            .staggered(2)

                        WatchBridgeHubCard(service: watchService)
                            .staggered(3)

                        if let sleep = healthKit.lastNightSleep {
                            HomeSleepCard(summary: sleep)
                                .staggered(4)
                        }

                        if let appt = nextAppointment {
                            AppointmentBanner(appointment: appt)
                                .staggered(4)
                        }

                        QuestionnaireCard(action: { showQuestionnaire = true })
                            .staggered(5)

                        StreakCard(count: moodEntries.count)
                            .staggered(6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
            }
            .ignoresSafeArea(edges: .top)
            .screenBackground()
        }
        .sheet(isPresented: $showCheckin) { MoodCheckinView() }
        .sheet(isPresented: $showJournal) { JournalView() }
        .sheet(isPresented: $showQuestionnaire) { QuestionnaireView() }
        .onAppear {
            withAnimation(.slowFade.delay(0.1)) { headerAppeared = true }
            pushContextToWatch()
        }
        .task {
            await healthKit.requestAuthorization()
        }
        .onChange(of: watchContextSignature) { _, _ in
            pushContextToWatch()
        }
    }

    private func pushContextToWatch() {
        watchService.pushContext(moodEntries: moodEntries, appointments: appointments)
    }
}

// MARK: — Hero header animado

struct HeroHeader: View {
    let entry: MoodEntry?
    let appeared: Bool
    @State private var gradientAngle: Double = 0

    private var score: Int { entry?.score ?? 5 }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Buenos días" }
        if h < 19 { return "Buenas tardes" }
        return "Buenas noches"
    }

    private var statusText: String {
        entry == nil ? "Check-in pendiente" : "Check-in completado"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradiente animado en loop
            AnimatedGradientBackground(score: score)
                .frame(height: 290)

            // Círculos flotantes
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 220)
                .offset(x: 100, y: -60)
                .scaleEffect(appeared ? 1 : 0.6)
                .animation(.bouncy.delay(0.3), value: appeared)

            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 160)
                .offset(x: -110, y: 20)
                .scaleEffect(appeared ? 1 : 0.6)
                .animation(.bouncy.delay(0.45), value: appeared)

            // Texto + emoji
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(greeting)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .opacity(appeared ? 1 : 0)
                            .animation(.smooth.delay(0.2), value: appeared)

                        Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)
                            .animation(.smooth.delay(0.22), value: appeared)

                        Text(entry != nil ? entry!.moodLabel : "¿Cómo estás?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.springy.delay(0.25), value: appeared)

                        Text(statusText)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.16), in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)
                            .animation(.smooth.delay(0.28), value: appeared)
                    }
                    Spacer()

                    Text(score.moodEmoji)
                        .font(.system(size: 68))
                        .shadow(radius: 6)
                        .scaleEffect(appeared ? 1 : 0.3)
                        .rotationEffect(.degrees(appeared ? 0 : -20))
                        .animation(.bouncy.delay(0.35), value: appeared)
                        .contentTransition(.numericText())
                        .animation(.springy, value: score)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .frame(height: 290)

            LinearGradient(
                colors: [.clear, Theme.background.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 84)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .animation(.easeInOut(duration: 0.6), value: score)
    }
}

struct AnimatedGradientBackground: View {
    let score: Int
    @State private var phase: Double = 0

    private var colors: [Color] {
        switch score {
        case 0...2: return [Color(hex: "#2a0a4a"), Color(hex: "#7B2FBE"), Color(hex: "#4A1080")]
        case 3...4: return [Color(hex: "#0a1a3a"), Color(hex: "#2D7DD2"), Color(hex: "#1a3a6c")]
        case 5...6: return [Color(hex: "#0a3a1a"), Color(hex: "#2DC653"), Color(hex: "#1a6c3a")]
        case 7...8: return [Color(hex: "#3a2a00"), Color(hex: "#F5C518"), Color(hex: "#8a7010")]
        default:    return [Color(hex: "#3a1a00"), Color(hex: "#F4845F"), Color(hex: "#8a4020")]
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { _ in
            MeshGradient(width: 3, height: 2, points: [
                [0,   0], [0.5 + Float(sin(phase) * 0.15), 0], [1, 0],
                [0,   1], [0.5 + Float(cos(phase) * 0.1),  1], [1, 1]
            ], colors: colors + [colors[0]])
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
        .animation(.easeInOut(duration: 0.7), value: score)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: — Check-in banner

struct CheckinBanner: View {
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: { Haptics.impact(.medium); action() }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Circle()
                        .stroke(Theme.accent.opacity(0.3), lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .scaleEffect(pulse ? 1.3 : 1)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulse)
                    Image(systemName: "face.smiling.inverse")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Check-in de ánimo")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("10 segundos · registra cómo estás ahora")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.secondaryText)
                    .font(.subheadline)
            }
        }
        .pressEffect()
        .cardStyle()
        .onAppear { pulse = true }
    }
}

// MARK: — Mood card (check-in hecho)

struct TodayMoodCard: View {
    let entry: MoodEntry
    let onCheckin: () -> Void
    @State private var energyProgress: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(entry.score.moodGradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: entry.score.moodColor.opacity(0.4), radius: 8, y: 3)
                    Text("\(entry.score)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(1)
                .animation(.bouncy, value: entry.score)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ánimo de hoy · \(entry.moodLabel)")
                        .font(.headline).foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 8) {
                        Label(entry.context.rawValue, systemImage: entry.context.icon)
                        Label(entry.company.rawValue, systemImage: entry.company.icon)
                    }
                    .font(.caption).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }

            // Energy bar animada
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Energía")
                        .font(.caption.bold()).foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text("\(Int(entry.energy * 100))%")
                        .font(.caption.bold()).foregroundStyle(entry.score.moodColor)
                        .contentTransition(.numericText())
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surface).frame(height: 8)
                        Capsule()
                            .fill(entry.score.moodGradient)
                            .frame(width: geo.size.width * energyProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }

            Button(action: { Haptics.selection(); onCheckin() }) {
                Label("Actualizar check-in", systemImage: "arrow.clockwise")
                    .font(.caption.bold()).foregroundStyle(Theme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .cardStyle()
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.2).delay(0.3)) {
                energyProgress = entry.energy
            }
        }
    }
}

// MARK: — Journal card

struct JournalCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: { Haptics.impact(.light); action() }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.moodPurple.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: "pencil.and.scribble")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.moodPurple)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Escribir en el diario")
                        .font(.headline).foregroundStyle(Theme.textPrimary)
                    Text("Exprésate · tu IA personal lo resume")
                        .font(.subheadline).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.secondaryText).font(.subheadline)
            }
        }
        .pressEffect()
        .cardStyle()
    }
}

// MARK: — Appointment banner

struct AppointmentBanner: View {
    let appointment: Appointment

    var body: some View {
        NavigationLink { SessionPrepView(appointment: appointment) } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22)).foregroundStyle(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.clinicianName)
                        .font(.headline).foregroundStyle(Theme.textPrimary)
                    Text(appointment.formattedDate)
                        .font(.subheadline).foregroundStyle(Theme.secondaryText)
                    Text("Preparar sesión →")
                        .font(.caption.bold()).foregroundStyle(Theme.accent)
                }
                Spacer()
                Text(appointment.duration == .express ? "15 min" : "50 min")
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.accent.opacity(0.12))
                    .foregroundStyle(Theme.accent)
                    .clipShape(Capsule())
            }
        }
        .pressEffect()
        .cardStyle()
    }
}

// MARK: — Home sleep card

struct HomeSleepCard: View {
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
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(qualityColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: summary.quality.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(qualityColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Anoche · \(summary.formattedTotal)")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 8) {
                    Text(summary.quality.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(qualityColor)
                    Text("·")
                        .foregroundStyle(Theme.secondaryText)
                    Text("Prof: \(summary.formattedDeep)  REM: \(summary.formattedREM)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(Theme.secondaryText)
        }
        .cardStyle()
    }
}

// MARK: — Watch biometrics card (iPhone side)

struct WatchBiometricsCard: View {
    @ObservedObject var service: WatchConnectivityService

    private var stressColor: Color {
        switch service.latestStressLevel {
        case "Bajo":     return Theme.moodGreen
        case "Moderado": return Theme.moodYellow
        case "Alto":     return Color.red
        default:         return Theme.secondaryText
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Apple Watch · en vivo", systemImage: "applewatch")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Circle()
                    .fill(Theme.moodGreen)
                    .frame(width: 7, height: 7)
            }

            HStack(spacing: 12) {
                BiometricPill(icon: "heart.fill", color: .red,
                              value: service.latestHeartRate.map { "\(Int($0))" } ?? "–",
                              unit: "bpm")
                BiometricPill(icon: "waveform.path.ecg", color: Theme.moodPurple,
                              value: service.latestHRV.map { String(format: "%.0f", $0) } ?? "–",
                              unit: "ms HRV")
                BiometricPill(icon: "lungs.fill", color: Theme.moodBlue,
                              value: service.latestO2.map { String(format: "%.0f%%", $0) } ?? "–",
                              unit: "SpO₂")
            }

            HStack(spacing: 8) {
                Text("Estrés estimado:")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                Text(service.latestStressLevel)
                    .font(.caption.bold())
                    .foregroundStyle(stressColor)
                Spacer()
                Text("\(service.latestSteps) pasos hoy")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .cardStyle()
    }
}

struct WatchBridgeHubCard: View {
    @ObservedObject var service: WatchConnectivityService

    private var statusColor: Color {
        if !service.isWatchAppInstalled || !service.isPaired { return Theme.secondaryText }
        return service.isReachable ? Theme.moodGreen : Theme.moodYellow
    }

    private var statusText: String {
        if !service.isPaired { return "Apple Watch no enlazado" }
        if !service.isWatchAppInstalled { return "Instala Mind en Apple Watch" }
        return service.isReachable ? "Conectado en vivo" : "Sin conexión en vivo"
    }

    private var lastSyncText: String {
        guard let date = service.lastWatchSyncDate else { return "Sin datos recientes del Watch" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Actualizado " + formatter.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Centro Apple Watch", systemImage: "applewatch")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(statusColor).frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.caption.bold())
                        .foregroundStyle(statusColor)
                }
            }

            Text(lastSyncText)
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)

            HStack(spacing: 10) {
                BiometricPill(icon: "heart.fill", color: .red,
                              value: service.latestHeartRate.map { "\(Int($0))" } ?? "–",
                              unit: "bpm")
                BiometricPill(icon: "waveform.path.ecg", color: Theme.moodPurple,
                              value: service.latestHRV.map { String(format: "%.0f", $0) } ?? "–",
                              unit: "ms HRV")
                BiometricPill(icon: "figure.walk", color: Theme.moodGreen,
                              value: "\(service.latestSteps)",
                              unit: "pasos")
            }

            HStack(spacing: 10) {
                Button {
                    Haptics.selection()
                    service.requestWatchSyncNow()
                } label: {
                    HStack(spacing: 6) {
                        if service.isRequestingLiveSync {
                            ProgressView().tint(Theme.accent).scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(service.isRequestingLiveSync ? "Sincronizando..." : "Sincronizar")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.selection()
                    service.requestWatchMoodCheckin()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "face.smiling")
                        Text("Pedir check-in")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Theme.moodPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.moodPurple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text(service.watchActionMessage)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                if let battery = service.watchBatteryLevel {
                    Label("\(battery)%", systemImage: "battery.75")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .cardStyle()
    }
}

struct BiometricPill: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())
                .animation(.smooth, value: value)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: — Questionnaire card

struct QuestionnaireCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: { Haptics.impact(.light); action() }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.moodPurple.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.moodPurple)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("PHQ-9 · GAD-7")
                        .font(.headline).foregroundStyle(Theme.textPrimary)
                    Text("Cuestionarios semanales · 2 min")
                        .font(.caption).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.secondaryText)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .pressEffect()
    }
}

// MARK: — Streak card

struct StreakCard: View {
    let count: Int
    @State private var animatedCount = 0

    var body: some View {
        HStack(spacing: 16) {
            Text("🔥")
                .font(.system(size: 36))
                .scaleEffect(count > 0 ? 1 : 0.8)
                .animation(.bouncy.delay(0.5), value: count)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(animatedCount)")
                        .font(.title2.bold()).foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(countsDown: false))
                    Text("registros totales")
                        .font(.subheadline).foregroundStyle(Theme.textPrimary)
                }
                Text("Cada check-in cuenta · sigue así")
                    .font(.subheadline).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
        }
        .cardStyle()
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.1).delay(0.6)) {
                animatedCount = count
            }
        }
    }
}
