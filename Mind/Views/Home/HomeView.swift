import SwiftUI
import SwiftData
import Foundation

// MARK: — 🏮 HomeView · estética japonesa zen

struct HomeView: View {
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @EnvironmentObject private var watchService: WatchConnectivityService
    @StateObject private var healthKit = HealthKitService.shared

    @State private var showCheckin = false
    @State private var showJournal = false
    @State private var showQuestionnaire = false
    @State private var showSafetyPlan = false
    @State private var showSettings = false

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
            ScrollWrapper {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ZenTopProfileHeader(onSettings: { showSettings = true })
                            .padding(.top, 20)
                            .staggered(0)

                    ZenSakuraHeroCard(entry: todayEntry)
                        .staggered(1)

                    ZenDaySectionHeader(service: watchService)
                        .staggered(2)

                    ZenMoodSnapshotCard(entry: todayEntry, onCheckin: { showCheckin = true })
                        .staggered(3)

                    ZenJournalCTA(action: { showJournal = true })
                        .staggered(4)

                    ZenMindfulPauseCard(action: { showSafetyPlan = true })
                        .staggered(5)

                    if let appt = nextAppointment {
                        AppointmentBanner(appointment: appt)
                            .staggered(6)
                    }

                    QuestionnaireCard(action: { showQuestionnaire = true })
                        .staggered(7)

                    if let sleep = healthKit.lastNightSleep {
                        HomeSleepCard(summary: sleep)
                            .staggered(8)
                    }

                    WatchBridgeHubCard(service: watchService)
                        .staggered(9)

                    StreakCard(count: moodEntries.count)
                        .staggered(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
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
        .onChange(of: watchContextSignature) { _, _ in
            pushContextToWatch()
        }
    }
}

    private func pushContextToWatch() {
        watchService.pushContext(moodEntries: moodEntries, appointments: appointments)
    }
}

// MARK: — 新 Home sections inspired by the provided mock

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

private struct ZenSakuraHeroCard: View {
    let entry: MoodEntry?
    @State private var breathe = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Buenos días" }
        if hour < 19 { return "Buenas tardes" }
        return "Buenas noches"
    }

    private var mood: String { entry?.moodLabel ?? "Pendiente" }

    private var heroURL: URL? {
        URL(string: "https://source.unsplash.com/1600x900/?japan,cherry-blossom,mountains,mist")
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Theme.kinari.opacity(0.45))

            AsyncImage(url: heroURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Theme.heroGradient
                case .empty:
                    Theme.heroGradient
                        .overlay(ProgressView().tint(.white))
                @unknown default:
                    Theme.heroGradient
                }
            }
            .overlay(
                LinearGradient(
                    colors: [.clear, Theme.washi.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text("TU ENERGÍA HOY ✨")
                    .font(.system(.caption2, design: .serif).weight(.bold))
                    .foregroundStyle(Theme.ai)
                    .tracking(2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                Text(greeting)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.sumi)

                HStack {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Theme.sumiSoft)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("MOOD STATUS")
                            .font(.system(.caption2, design: .serif).weight(.bold))
                            .tracking(1)
                            .foregroundStyle(Theme.sumiSoft.opacity(0.7))
                        Text(mood)
                            .font(.system(.title2, design: .serif).weight(.bold))
                            .foregroundStyle(Theme.sumi)
                    }
                }
            }
            .padding(24)

            HStack {
                Spacer()
                EnsoCircle(color: Theme.ai, lineWidth: 2)
                    .frame(width: 32, height: 32)
                    .padding(24)
            }
            .allowsHitTesting(false)
        }
        .frame(height: 290)
        .scaleEffect(breathe ? 1.015 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: Theme.sumi.opacity(0.08), radius: 20, x: 0, y: 10)
    }
}

private struct ZenDaySectionHeader: View {
    @ObservedObject var service: WatchConnectivityService

    private var watchText: String {
        if service.isReachable { return "Apple Watch Conectado" }
        if service.isPaired { return "Watch enlazado" }
        return "Watch no enlazado"
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tu día")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                Text("Resumen de tu bienestar actual")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            HStack(spacing: 7) {
                Image(systemName: "applewatch")
                Text(watchText)
            }
            .font(.system(.caption, design: .serif).weight(.semibold))
            .foregroundStyle(Theme.sumi)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.kinari.opacity(0.68), in: Capsule())
        }
    }
}

private struct ZenMoodSnapshotCard: View {
    let entry: MoodEntry?
    let onCheckin: () -> Void
    @State private var breathe = false

    private var scoreText: String {
        guard let entry else { return "?" }
        return "\(entry.score)"
    }

    private var contextText: String { entry?.context.rawValue ?? "Sin dato" }
    private var companyText: String { entry?.company.rawValue ?? "Sin dato" }
    private var energy: Double { entry?.energy ?? 0.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.sumi, lineWidth: 2)
                        .frame(width: 66, height: 66)
                    Text(scoreText)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.sumi)
                }

                Spacer()

                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.asagi)
            }

            if entry == nil {
                Text("Aún no registras tu estado de hoy. Haz tu check-in en menos de 10 segundos.")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Theme.secondaryText)
            }

            HStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONTEXTO")
                        .font(.system(.caption2, design: .serif).weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.sumiSoft)
                    Text(contextText)
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(Theme.sumi)
                }

                Rectangle()
                    .fill(Theme.sumi.opacity(0.12))
                    .frame(width: 1, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text("COMPAÑÍA")
                        .font(.system(.caption2, design: .serif).weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.sumiSoft)
                    Text(companyText)
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(Theme.sumi)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("ENERGÍA")
                        .font(.system(.caption2, design: .serif).weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.sumi)
                    Spacer()
                    Text("\(Int(energy * 100))%")
                        .font(.system(.caption, design: .serif).weight(.bold))
                        .foregroundStyle(Theme.sumi)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.kohaku.opacity(0.45)).frame(height: 8)
                        Capsule()
                            .fill(Theme.ai)
                            .frame(width: geo.size.width * energy, height: 8)
                    }
                }
                .frame(height: 8)
            }

            if entry == nil {
                Button(action: { Haptics.impact(.medium); onCheckin() }) {
                    Text("Registrar check-in")
                        .font(.system(.subheadline, design: .serif).weight(.bold))
                        .tracking(1.6)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.ai, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .pressEffect()
            }
        }
        .padding(22)
        .scaleEffect(breathe ? 1.012 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.borderSoft, lineWidth: 1))
        )
    }
}

private struct ZenJournalCTA: View {
    let action: () -> Void

    private var flowerURL: URL? {
        URL(string: "https://source.unsplash.com/600x600/?cherry-blossom,petals,japan")
    }

    var body: some View {
        Button(action: { Haptics.selection(); action() }) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.ai, Color(hex: "#122C49")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                AsyncImage(url: flowerURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(0.18)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    Text("Escribir en el diario")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(.white)

                    Text("Reflexiona sobre tu día. Nuestro sistema de IA resumirá tus pensamientos para encontrar patrones en tu bienestar emocional.")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.leading)
                }
                .padding(22)
            }
            .frame(minHeight: 210)
            .shadow(color: Theme.ai.opacity(0.28), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .pressEffect()
    }
}

private struct ZenMindfulPauseCard: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.mind.and.body")
                .font(.title2)
                .foregroundStyle(Theme.sumiSoft)
                .padding(10)
                .background(Theme.kinari.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Pausa consciente")
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundStyle(Theme.textPrimary)

            Text("Tómate un momento para respirar. Has estado activo durante 4 horas seguidas.")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button(action: { Haptics.impact(.light); action() }) {
                Text("INICIAR SESIÓN")
                    .font(.system(.subheadline, design: .serif).weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(Theme.sumi)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Theme.kinari, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .pressEffect()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.cardBackground.opacity(0.78))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.borderSoft, lineWidth: 1))
        )
    }
}

// MARK: — 🌸 Hero header · atardecer sobre cerezos

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

            // Montaña Fuji estilizada al fondo (más prominente para balancear)
            FujiSilhouette()
                .fill(
                    LinearGradient(
                        colors: [Theme.ai.opacity(0.15), Theme.ai.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 140)
                .frame(maxWidth: .infinity)
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
                            .opacity(appeared ? 1 : 0)
                            .animation(.smooth.delay(0.2), value: appeared)

                        Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(.system(.caption2, design: .serif).weight(.medium))
                            .foregroundStyle(.white.opacity(0.78))
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)
                            .animation(.smooth.delay(0.22), value: appeared)

                        Text(entry != nil ? entry!.moodLabel : "¿Cómo estás?")
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .shadow(color: Theme.sumi.opacity(0.25), radius: 2, y: 1)
                            .contentTransition(.numericText())
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.springy.delay(0.25), value: appeared)

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
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .animation(.smooth.delay(0.28), value: appeared)
                    }
                    Spacer()

                    // Sello hanko + kanji del estado
                    VStack(spacing: 6) {
                        Text(score.moodKanji)
                            .font(.system(size: 56, weight: .black, design: .serif))
                            .foregroundStyle(.white)
                            .shadow(color: Theme.sumi.opacity(0.3), radius: 3, y: 2)
                            .scaleEffect(appeared ? 1 : 0.3)
                            .rotationEffect(.degrees(appeared ? 0 : -12))
                            .animation(.bouncy.delay(0.35), value: appeared)
                            .contentTransition(.numericText())
                            .animation(.springy, value: score)

                        HankoStamp(kanji: "心", color: .white, size: 28)
                            .opacity(appeared ? 0.9 : 0)
                            .animation(.smooth.delay(0.5), value: appeared)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .animation(.easeInOut(duration: 0.6), value: score)
    }
}

// MARK: — Cielo Zen degradado según mood (Estética Niebla y Montaña)

struct ZenSkyBackground: View {
    let score: Int

    private var colors: [Color] {
        switch score {
        case 0...2: return [Color(hex: "#1F2933"), Color(hex: "#3E4C59"), Color(hex: "#52606D")] // Noche profunda
        case 3...4: return [Color(hex: "#323F4B"), Color(hex: "#3E617A"), Color(hex: "#8BAEC5")] // Lluvia/Niebla
        case 5...6: return [Color(hex: "#E5E9F0"), Color(hex: "#B8C1CC"), Color(hex: "#9EABB3")] // Nublado Zen
        case 7...8: return [Color(hex: "#CBD5E0"), Color(hex: "#A0AEC0"), Color(hex: "#718096")] // Tarde despejada
        default:    return [Color(hex: "#6E9BB0"), Color(hex: "#81E6D9"), Color(hex: "#BEE3F8")] // Aire puro/Felicidad
        }
    }

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Sol/luna tenue
            Circle()
                .fill(.white.opacity(0.35))
                .frame(width: 120, height: 120)
                .blur(radius: 12)
                .offset(x: -80, y: -60)
        )
        .overlay(
            Circle()
                .stroke(.white.opacity(0.35), lineWidth: 1.5)
                .frame(width: 90, height: 90)
                .offset(x: -80, y: -60)
        )
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: — Silueta del Monte Fuji

struct FujiSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: w * 0.15, y: h))
        // ladera izquierda
        p.addCurve(
            to: CGPoint(x: w * 0.42, y: h * 0.35),
            control1: CGPoint(x: w * 0.28, y: h * 0.7),
            control2: CGPoint(x: w * 0.37, y: h * 0.5)
        )
        // cumbre con nieve (pequeña muesca)
        p.addLine(to: CGPoint(x: w * 0.46, y: h * 0.25))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.54, y: h * 0.25),
            control: CGPoint(x: w * 0.50, y: h * 0.18)
        )
        p.addLine(to: CGPoint(x: w * 0.58, y: h * 0.35))
        // ladera derecha
        p.addCurve(
            to: CGPoint(x: w * 0.85, y: h),
            control1: CGPoint(x: w * 0.63, y: h * 0.5),
            control2: CGPoint(x: w * 0.72, y: h * 0.7)
        )
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }
}

// MARK: — Check-in banner · sello hanko con pulso

struct CheckinBanner: View {
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: { Haptics.impact(.medium); action() }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.ai.opacity(0.1))
                        .frame(width: 62, height: 62)
                    Circle()
                        .stroke(Theme.ai.opacity(0.3), lineWidth: 1.2)
                        .frame(width: 62, height: 62)
                        .scaleEffect(pulse ? 1.3 : 1)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)
                    EnsoCircle(color: Theme.ai, lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Check-in de ánimo")
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("10 segundos · registra cómo estás ahora")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.sakuraDeep)
                    .font(.subheadline.bold())
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
                        .frame(width: 62, height: 62)
                        .shadow(color: entry.score.moodColor.opacity(0.4), radius: 10, y: 4)
                    Text(entry.score.moodKanji)
                        .font(.system(size: 26, weight: .black, design: .serif))
                        .foregroundStyle(.white)
                    Circle()
                        .stroke(.white.opacity(0.45), lineWidth: 0.8)
                        .frame(width: 62, height: 62)
                }
                .animation(.bouncy, value: entry.score)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Ánimo")
                            .kanjiBadge()
                        Text(entry.moodLabel)
                            .font(.system(.headline, design: .serif).weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    HStack(spacing: 10) {
                        Label(entry.context.rawValue, systemImage: entry.context.icon)
                        Label(entry.company.rawValue, systemImage: entry.company.icon)
                    }
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }

            InkBrushDivider().frame(height: 8)

            // Barra de energía estilizada
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Energía")
                        .font(.system(.caption, design: .serif).weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text("\(Int(entry.energy * 100))%")
                        .font(.system(.caption, design: .serif).weight(.bold))
                        .foregroundStyle(entry.score.moodColor)
                        .contentTransition(.numericText())
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.kohaku.opacity(0.6)).frame(height: 8)
                        Capsule()
                            .fill(entry.score.moodGradient)
                            .frame(width: geo.size.width * energyProgress, height: 8)
                            .overlay(
                                Capsule().stroke(.white.opacity(0.5), lineWidth: 0.5)
                            )
                    }
                }
                .frame(height: 8)
            }

            Button(action: { Haptics.selection(); onCheckin() }) {
                Label("Actualizar check-in", systemImage: "arrow.clockwise")
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.sakuraDeep)
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
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.matcha.opacity(0.18))
                        .frame(width: 56, height: 56)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.matchaDeep.opacity(0.25), lineWidth: 0.8)
                        .frame(width: 56, height: 56)
                    Image(systemName: "scroll")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.matchaDeep)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Diario")
                            .font(.system(.headline, design: .serif).weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("日記")
                            .font(.system(.caption2, design: .serif))
                            .foregroundStyle(Theme.matchaDeep)
                    }
                    Text("Exprésate · tu IA lo resume con delicadeza")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.matchaDeep).font(.subheadline.bold())
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
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.asagi.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.ai)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.clinicianName)
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(appointment.formattedDate)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.secondaryText)
                    Text("Preparar sesión →")
                        .font(.system(.caption, design: .serif).weight(.semibold))
                        .foregroundStyle(Theme.asagi)
                }
                Spacer()
                Text(appointment.duration == .express ? "15 分" : "50 分")
                    .font(.system(.caption, design: .serif).weight(.bold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.asagi.opacity(0.15))
                    .foregroundStyle(Theme.ai)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.asagi.opacity(0.3), lineWidth: 0.6))
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
        case .excellent: return Theme.matchaDeep
        case .good:      return Theme.asagi
        case .fair:      return Theme.tamago
        case .poor:      return Theme.accentPurple
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(qualityColor.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: summary.quality.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(qualityColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Anoche")
                        .kanjiBadge()
                    Text(summary.formattedTotal)
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                HStack(spacing: 8) {
                    Text(summary.quality.rawValue)
                        .font(.system(.caption, design: .serif).weight(.bold))
                        .foregroundStyle(qualityColor)
                    Text("·").foregroundStyle(Theme.secondaryText)
                    Text("Prof \(summary.formattedDeep) · REM \(summary.formattedREM)")
                        .font(.system(.caption, design: .serif))
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

// MARK: — Watch biometrics card

struct WatchBiometricsCard: View {
    @ObservedObject var service: WatchConnectivityService

    private var stressColor: Color {
        switch service.latestStressLevel {
        case "Bajo":     return Theme.matchaDeep
        case "Moderado": return Theme.tamago
        case "Alto":     return Theme.sango
        default:         return Theme.secondaryText
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Apple Watch · en vivo", systemImage: "applewatch")
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Circle()
                    .fill(Theme.matchaDeep)
                    .frame(width: 7, height: 7)
            }

            HStack(spacing: 12) {
                BiometricPill(icon: "heart.fill", color: Theme.sango,
                              value: service.latestHeartRate.map { "\(Int($0))" } ?? "–",
                              unit: "bpm")
                BiometricPill(icon: "waveform.path.ecg", color: Theme.accentPurple,
                              value: service.latestHRV.map { String(format: "%.0f", $0) } ?? "–",
                              unit: "ms HRV")
                BiometricPill(icon: "lungs.fill", color: Theme.asagi,
                              value: service.latestO2.map { String(format: "%.0f%%", $0) } ?? "–",
                              unit: "SpO₂")
            }

            HStack(spacing: 8) {
                Text("Estrés estimado:")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(Theme.secondaryText)
                Text(service.latestStressLevel)
                    .font(.system(.caption, design: .serif).weight(.bold))
                    .foregroundStyle(stressColor)
                Spacer()
                Text("\(service.latestSteps) pasos hoy")
                    .font(.system(.caption, design: .serif))
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
        return service.isReachable ? Theme.matchaDeep : Theme.tamago
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
                HStack(spacing: 8) {
                    Image(systemName: "applewatch")
                        .foregroundStyle(Theme.sumi)
                    Text("Centro Apple Watch")
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("腕時計")
                        .font(.system(.caption2, design: .serif))
                        .foregroundStyle(Theme.sumiSoft)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(statusColor).frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.system(.caption, design: .serif).weight(.semibold))
                        .foregroundStyle(statusColor)
                }
            }

            Text(lastSyncText)
                .font(.system(.caption, design: .serif))
                .foregroundStyle(Theme.secondaryText)

            HStack(spacing: 10) {
                BiometricPill(icon: "heart.fill", color: Theme.sango,
                              value: service.latestHeartRate.map { "\(Int($0))" } ?? "–",
                              unit: "bpm")
                BiometricPill(icon: "waveform.path.ecg", color: Theme.accentPurple,
                              value: service.latestHRV.map { String(format: "%.0f", $0) } ?? "–",
                              unit: "ms HRV")
                BiometricPill(icon: "figure.walk", color: Theme.matchaDeep,
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
                            ProgressView().tint(Theme.sakuraDeep).scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(service.isRequestingLiveSync ? "Sincronizando..." : "Sincronizar")
                    }
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.sakuraDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.sakura.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.sakuraDeep.opacity(0.25), lineWidth: 0.6)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.matchaDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.matcha.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.matchaDeep.opacity(0.25), lineWidth: 0.6)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text(service.watchActionMessage)
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                if let battery = service.watchBatteryLevel {
                    Label("\(battery)%", systemImage: "battery.75")
                        .font(.system(.caption, design: .serif).weight(.semibold))
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
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())
                .animation(.smooth, value: value)
            Text(unit)
                .font(.system(.caption2, design: .serif))
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.22), lineWidth: 0.6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: — Questionnaire card

struct QuestionnaireCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: { Haptics.impact(.light); action() }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.accentPurple.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.accentPurple)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("PHQ-9 · GAD-7")
                            .font(.system(.headline, design: .serif).weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("問診")
                            .font(.system(.caption2, design: .serif))
                            .foregroundStyle(Theme.accentPurple)
                    }
                    Text("Cuestionarios semanales · 2 min")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(Theme.secondaryText)
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

// MARK: — Streak card · estilo pergamino

struct StreakCard: View {
    let count: Int
    @State private var animatedCount = 0

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.kincha.opacity(0.18))
                    .frame(width: 52, height: 52)
                Circle()
                    .stroke(Theme.kincha.opacity(0.4), lineWidth: 0.8)
                    .frame(width: 52, height: 52)
                Text("継")  // "continuación"
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(Theme.kincha)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(animatedCount)")
                        .font(.system(.title2, design: .serif).weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(countsDown: false))
                    Text("registros totales")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                }
                Text("Cada pétalo cuenta · sigue así 🌸")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(Theme.secondaryText)
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
