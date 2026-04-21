import SwiftUI
import SwiftData
import Foundation

// MARK: — 🏮 HomeView · Estética Japonesa Zen Inmersiva

struct HomeView: View {
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @Environment(WatchConnectivityService.self) private var watchService
    @State private var healthKit = HealthKitService.shared

    @State private var showCheckin = false
    @State private var showJournal = false
    @State private var showQuestionnaire = false
    @State private var showSafetyPlan = false
    @State private var showSettings = false

    private var todayEntry: MoodEntry? {
        moodEntries.first { Calendar.current.isDateInToday($0.date) }
    }
    private var nextAppointment: Appointment? { appointments.first { $0.isUpcoming } }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) { // Mayor 'Ma' (espacio) entre secciones
                    ZenTopProfileHeader(onSettings: { showSettings = true })
                        .padding(.top, 20)
                        .staggered(0)

                    HeroHeader(entry: todayEntry, appeared: true)
                        .staggered(1)

                    if todayEntry == nil {
                        CheckinBanner(action: { showCheckin = true })
                            .staggered(2)
                    } else {
                        TodayMoodCard(entry: todayEntry!, onCheckin: { showCheckin = true })
                            .staggered(2)
                    }

                    ZenGardenStatusCard(moodEntries: Array(moodEntries.prefix(7)))
                        .staggered(3)

                    VStack(spacing: 24) {
                        zenSectionHeader(title: "Tu Camino", subtitle: "Prácticas de bienestar")
                        
                        JournalCard(action: { showJournal = true })
                        
                        if let appt = nextAppointment {
                            AppointmentBanner(appointment: appt)
                        }
                        
                        QuestionnaireCard(action: { showQuestionnaire = true })
                    }
                    .staggered(4)

                    VStack(spacing: 24) {
                        zenSectionHeader(title: "Vitalidad", subtitle: "Sincronía con tu cuerpo")
                        
                        if let sleep = healthKit.lastNightSleep {
                            HomeSleepCard(summary: sleep)
                        }
                        
                        WatchBridgeHubCard(service: watchService)
                        
                        StreakCard(count: moodEntries.count)
                    }
                    .staggered(5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 140)
            }
            .screenBackground() // Fondo inmersivo zen
        }
        .sheet(isPresented: $showCheckin) { MoodCheckinView() }
        .sheet(isPresented: $showJournal) { JournalView() }
        .sheet(isPresented: $showQuestionnaire) { QuestionnaireView() }
        .sheet(isPresented: $showSafetyPlan) { SafetyPlanView() }
        .sheet(isPresented: $showSettings) { PatientSettingsView() }
        .onAppear { pushContextToWatch() }
        .task {
            await healthKit.requestAuthorization()
        }
    }

    private func pushContextToWatch() {
        watchService.pushContext(moodEntries: moodEntries, appointments: appointments)
    }
}

// MARK: — 🏖️ Zen Garden Status Card (Visualización de la semana)

struct ZenGardenStatusCard: View {
    let moodEntries: [MoodEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu Jardín Zen")
                        .font(.zenHeadline)
                    Text("Reflejo de tu semana")
                        .font(.zenCaption)
                        .foregroundStyle(Theme.sumiSoft)
                }
                Spacer()
                PagodaIcon()
                    .frame(width: 32, height: 32)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.kinari.opacity(0.3))
                    .frame(height: 140)
                
                RakedSandPattern()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(0..<7) { i in
                        let entry = i < moodEntries.count ? moodEntries[i] : nil
                        VStack(spacing: 8) {
                            if let entry = entry {
                                Circle()
                                    .fill(entry.score.moodGradient)
                                    .frame(width: 24, height: 24)
                                    .shadow(color: entry.score.moodColor.opacity(0.3), radius: 4)
                                    .overlay(Text(entry.score.moodKanji).font(.system(size: 10, weight: .bold)).foregroundStyle(.white))
                            } else {
                                Circle()
                                    .stroke(Theme.sumi.opacity(0.1), lineWidth: 1)
                                    .frame(width: 24, height: 24)
                            }
                            
                            Text(dayInitial(for: i))
                                .font(.zenCaption)
                                .foregroundStyle(Theme.sumiSoft)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .cardStyle()
    }
    
    private func dayInitial(for i: Int) -> String {
        let days = ["L", "M", "M", "J", "V", "S", "D"]
        return days[i % 7]
    }
}

// MARK: — Private Components

private struct ZenTopProfileHeader: View {
    let onSettings: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.sakura.opacity(0.35)).frame(width: 44, height: 44)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.sumi)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Zenith")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            Button(action: { Haptics.selection(); onSettings() }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.sumiSoft)
                    .padding(10)
                    .background(Theme.kinari.opacity(0.55), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

struct HeroHeader: View {
    let entry: MoodEntry?
    let appeared: Bool

    private var score: Int { entry?.score ?? 5 }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "おはよう · Buenos días" }
        if h < 19 { return "こんにちは · Buenas tardes" }
        return "こんばんは · Buenas noches"
    }

    private var statusText: String {
        entry == nil ? "Check-in pendiente" : "Check-in completado"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fondo: gradiente de niebla zen
            ZenSkyBackground(score: score)
                .frame(height: 310)

            // Seigaiha muy sutil detrás
            SeigaihaPattern(color: .white, opacity: 0.12, scale: 40)
                .frame(height: 310)
                .allowsHitTesting(false)

            // Montaña Fuji estilizada al fondo
            FujiSilhouette()
                .fill(
                    LinearGradient(
                        colors: [Theme.ai.opacity(0.15), Theme.ai.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 140)
                .offset(y: 55)
                .allowsHitTesting(false)

            // Contenido
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(greeting)
                            .font(.system(.caption, design: .serif))
                            .foregroundStyle(.white.opacity(0.9))

                        Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(.system(.caption2, design: .serif).weight(.medium))
                            .foregroundStyle(.white.opacity(0.78))

                        Text(entry != nil ? entry!.moodLabel : "¿Cómo estás?")
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .shadow(color: Theme.sumi.opacity(0.25), radius: 2, y: 1)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(entry == nil ? Theme.tamago : Theme.matcha)
                                .frame(width: 6, height: 6)
                            Text(statusText)
                                .font(.system(.caption, design: .serif).weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.18), in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.28), lineWidth: 0.8))
                    }
                    Spacer()

                    // Sello hanko + kanji del estado
                    VStack(spacing: 6) {
                        Text(score.moodKanji)
                            .font(.system(size: 56, weight: .black, design: .serif))
                            .foregroundStyle(.white)
                            .shadow(color: Theme.sumi.opacity(0.3), radius: 3, y: 2)

                        HankoStamp(kanji: "心", color: .white, size: 28)
                            .opacity(0.9)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
            .frame(height: 310)

            // Transición hacia el fondo washi
            LinearGradient(
                colors: [.clear, Theme.washi.opacity(0.95), Theme.washi],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 70)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
    }
}

struct ZenSkyBackground: View {
    let score: Int

    private var colors: [Color] {
        switch score {
        case 0...2: return [Color(hex: "#1F2933"), Color(hex: "#3E4C59"), Color(hex: "#52606D")]
        case 3...4: return [Color(hex: "#323F4B"), Color(hex: "#3E617A"), Color(hex: "#8BAEC5")]
        case 5...6: return [Color(hex: "#E5E9F0"), Color(hex: "#B8C1CC"), Color(hex: "#9EABB3")]
        case 7...8: return [Color(hex: "#CBD5E0"), Color(hex: "#A0AEC0"), Color(hex: "#718096")]
        default:    return [Color(hex: "#6E9BB0"), Color(hex: "#81E6D9"), Color(hex: "#BEE3F8")]
        }
    }

    var body: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(
                Circle()
                    .fill(.white.opacity(0.35))
                    .frame(width: 120, height: 120)
                    .blur(radius: 12)
                    .offset(x: -80, y: -60)
            )
    }
}

struct FujiSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: w * 0.15, y: h))
        p.addCurve(to: CGPoint(x: w * 0.42, y: h * 0.35), control1: CGPoint(x: w * 0.28, y: h * 0.7), control2: CGPoint(x: w * 0.37, y: h * 0.5))
        p.addLine(to: CGPoint(x: w * 0.46, y: h * 0.25))
        p.addQuadCurve(to: CGPoint(x: w * 0.54, y: h * 0.25), control: CGPoint(x: w * 0.50, y: h * 0.18))
        p.addLine(to: CGPoint(x: w * 0.58, y: h * 0.35))
        p.addCurve(to: CGPoint(x: w * 0.85, y: h), control1: CGPoint(x: w * 0.63, y: h * 0.5), control2: CGPoint(x: w * 0.72, y: h * 0.7))
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }
}

struct CheckinBanner: View {
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: { Haptics.impact(.medium); action() }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Theme.ai.opacity(0.1)).frame(width: 62, height: 62)
                    Circle().stroke(Theme.ai.opacity(0.3), lineWidth: 1.2).frame(width: 62, height: 62)
                        .scaleEffect(pulse ? 1.3 : 1).opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)
                    EnsoCircle(color: Theme.ai, lineWidth: 2).frame(width: 28, height: 28)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Check-in de ánimo").font(.zenHeadline).foregroundStyle(Theme.textPrimary)
                    Text("10 segundos · registra cómo estás").font(.zenCaption).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.sakuraDeep).font(.subheadline.bold())
            }
        }
        .pressEffect()
        .cardStyle()
        .onAppear { pulse = true }
    }
}

struct TodayMoodCard: View {
    let entry: MoodEntry
    let onCheckin: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(entry.score.moodGradient).frame(width: 62, height: 62)
                    Text(entry.score.moodKanji).font(.system(size: 26, weight: .black, design: .serif)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Ánimo").kanjiBadge()
                        Text(entry.moodLabel).font(.zenHeadline).foregroundStyle(Theme.textPrimary)
                    }
                    Text("\(entry.context.rawValue) · \(entry.company.rawValue)").font(.zenCaption).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Button(action: onCheckin) {
                    Image(systemName: "pencil.line").foregroundStyle(Theme.sumiSoft)
                }
            }
        }
        .cardStyle()
    }
}

struct JournalCard: View {
    let action: () -> Void
    var body: some View {
        Button(action: { Haptics.impact(.light); action() }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(Theme.matcha.opacity(0.1)).frame(width: 56, height: 56)
                    Image(systemName: "scroll").font(.title3).foregroundStyle(Theme.matchaDeep)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Diario Personal").font(.zenHeadline).foregroundStyle(Theme.textPrimary)
                    Text("Expresa tus pensamientos").font(.zenCaption).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.matchaDeep).font(.subheadline.bold())
            }
        }
        .pressEffect()
        .cardStyle()
    }
}

struct AppointmentBanner: View {
    let appointment: Appointment
    var body: some View {
        NavigationLink { SessionPrepView(appointment: appointment) } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Theme.asagi.opacity(0.1)).frame(width: 56, height: 56)
                    Image(systemName: "calendar").font(.title3).foregroundStyle(Theme.ai)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.clinicianName).font(.zenHeadline).foregroundStyle(Theme.textPrimary)
                    Text(appointment.formattedDate).font(.zenCaption).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.asagi).font(.subheadline.bold())
            }
        }
        .pressEffect()
        .cardStyle()
    }
}

struct HomeSleepCard: View {
    let summary: SleepSummary
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Theme.ai.opacity(0.1)).frame(width: 48, height: 48)
                Image(systemName: "moon.stars").foregroundStyle(Theme.ai)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Sueño").font(.zenHeadline).foregroundStyle(Theme.textPrimary)
                Text("\(summary.formattedTotal) · Calidad \(summary.quality.rawValue)").font(.zenCaption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
        }
        .cardStyle()
    }
}

struct WatchBridgeHubCard: View {
    var service: WatchConnectivityService
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Theme.sumi.opacity(0.05)).frame(width: 48, height: 48)
                Image(systemName: "applewatch").foregroundStyle(Theme.sumi)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Apple Watch").font(.zenHeadline).foregroundStyle(Theme.textPrimary)
                Text(service.isReachable ? "Conectado" : "Sincronizado").font(.zenCaption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
        }
        .cardStyle()
    }
}

struct QuestionnaireCard: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Theme.accentPurple.opacity(0.1)).frame(width: 48, height: 48)
                    Image(systemName: "doc.text.magnifyingglass").foregroundStyle(Theme.accentPurple)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Cuestionarios").font(.zenHeadline).foregroundStyle(Theme.textPrimary)
                    Text("PHQ-9 · GAD-7").font(.zenCaption).foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }
        }
        .cardStyle()
    }
}

struct StreakCard: View {
    let count: Int
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Theme.kincha.opacity(0.1)).frame(width: 52, height: 52)
                Text("継").font(.zenHeadline).foregroundStyle(Theme.kincha)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(count) días seguidos").font(.zenHeadline).foregroundStyle(Theme.textPrimary)
                Text("Cada pétalo cuenta").font(.zenCaption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
        }
        .cardStyle()
    }
}
