import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    @AppStorage("sharesMood")           private var sharesMood = true
    @AppStorage("sharesQuestionnaires") private var sharesQuestionnaires = true
    @AppStorage("sharesTopics")         private var sharesTopics = true

    private let slides: [OnboardingData] = [
        .init(emoji: "📓", colors: [Color(hex: "#0a1a3a"), Color(hex: "#2D7DD2")],
              title: "Tu diario,\nsolo tuyo",
              body: "Lo que escribes vive únicamente en tu iPhone. Nadie más lo lee — ni nosotros."),
        .init(emoji: "🧠", colors: [Color(hex: "#2a0a4a"), Color(hex: "#7B2FBE")],
              title: "IA en tu iPhone,\nno en la nube",
              body: "El modelo de lenguaje que resume tu semana corre aquí dentro. Sin servidores. Sin riesgos."),
        .init(emoji: "🔗", colors: [Color(hex: "#0a3a1a"), Color(hex: "#2DC653")],
              title: "Tu psicólogo\nllega preparado",
              body: "Ve tendencias y temas — nunca el texto original. Tú decides qué compartir, cuando quieras."),
    ]

    private var currentColors: [Color] {
        currentPage < slides.count ? slides[currentPage].colors : [Color(hex: "#0a1a3a"), Theme.accent]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fondo animado
                LinearGradient(colors: currentColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.55), value: currentPage)

                // Círculos decorativos con parallax
                Circle()
                    .fill(.white.opacity(0.055))
                    .frame(width: 300)
                    .offset(x: 120 - dragOffset * 0.1, y: -180)
                    .animation(.smooth, value: dragOffset)

                Circle()
                    .fill(.white.opacity(0.04))
                    .frame(width: 200)
                    .offset(x: -130 + dragOffset * 0.06, y: 80)
                    .animation(.smooth, value: dragOffset)

                VStack(spacing: 0) {
                    // Skip
                    HStack {
                        Spacer()
                        if currentPage < slides.count {
                            Button("Omitir") {
                                Haptics.impact(.light)
                                withAnimation(.smooth) { hasCompletedOnboarding = true }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.trailing, 24)
                        }
                    }
                    .frame(height: 52)

                    // Contenido
                    TabView(selection: $currentPage) {
                        ForEach(Array(slides.enumerated()), id: \.offset) { i, data in
                            OnboardingSlide(data: data, isActive: currentPage == i)
                                .tag(i)
                        }
                        ConsentSlide(
                            sharesMood: $sharesMood,
                            sharesQuestionnaires: $sharesQuestionnaires,
                            sharesTopics: $sharesTopics,
                            tag: slides.count
                        )
                        .tag(slides.count)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.springy, value: currentPage)

                    // Dots + CTA
                    VStack(spacing: 22) {
                        // Dots
                        HStack(spacing: 8) {
                            ForEach(0...slides.count, id: \.self) { i in
                                Capsule()
                                    .fill(.white.opacity(i == currentPage ? 1 : 0.35))
                                    .frame(width: i == currentPage ? 28 : 8, height: 8)
                                    .animation(.springy, value: currentPage)
                            }
                        }

                        // CTA
                        Button {
                            Haptics.impact(.medium)
                            if currentPage < slides.count {
                                withAnimation(.springy) { currentPage += 1 }
                            } else {
                                withAnimation(.smooth) { hasCompletedOnboarding = true }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(currentPage < slides.count ? "Siguiente" : "Empezar")
                                    .font(.headline)
                                if currentPage == slides.count {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.headline)
                                }
                            }
                            .foregroundStyle(currentColors.last ?? Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                        }
                        .pressEffect()
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 48)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct OnboardingData {
    let emoji: String
    let colors: [Color]
    let title: String
    let body: String
}

struct OnboardingSlide: View {
    let data: OnboardingData
    let isActive: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text(data.emoji)
                .font(.system(size: 88))
                .shadow(radius: 10)
                .scaleEffect(appeared ? 1 : 0.3)
                .rotationEffect(.degrees(appeared ? 0 : -15))
                .animation(.bouncy.delay(0.05), value: appeared)

            VStack(spacing: 16) {
                Text(data.title)
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.springy.delay(0.15), value: appeared)

                Text(data.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.springy.delay(0.22), value: appeared)
            }

            Spacer()
        }
        .onAppear {
            appeared = false
            withAnimation { appeared = isActive }
        }
        .onChange(of: isActive) { _, active in
            if active {
                appeared = false
                withAnimation(.springy.delay(0.05)) { appeared = true }
            }
        }
    }
}

struct ConsentSlide: View {
    @Binding var sharesMood: Bool
    @Binding var sharesQuestionnaires: Bool
    @Binding var sharesTopics: Bool
    let tag: Int
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 8)

                VStack(spacing: 12) {
                    Text("🔐")
                        .font(.system(size: 64))
                        .scaleEffect(appeared ? 1 : 0.3)
                        .animation(.bouncy.delay(0.05), value: appeared)

                    Text("¿Qué comparte tu\npsicólogo?")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)
                        .animation(.springy.delay(0.12), value: appeared)

                    Text("Cambia esto cuando quieras.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .opacity(appeared ? 1 : 0)
                        .animation(.springy.delay(0.18), value: appeared)
                }

                // Toggles
                VStack(spacing: 0) {
                    WhiteConsentRow(icon: "chart.line.uptrend.xyaxis",
                                    title: "Tendencia de ánimo",
                                    subtitle: "Gráfica numérica",
                                    isOn: $sharesMood)
                    .staggered(0, base: 0.25)
                    Divider().background(.white.opacity(0.2))
                    WhiteConsentRow(icon: "list.clipboard",
                                    title: "Cuestionarios",
                                    subtitle: "PHQ-9 / GAD-7",
                                    isOn: $sharesQuestionnaires)
                    .staggered(1, base: 0.25)
                    Divider().background(.white.opacity(0.2))
                    WhiteConsentRow(icon: "tag",
                                    title: "Temas del diario",
                                    subtitle: "Anonimizados, sin texto",
                                    isOn: $sharesTopics)
                    .staggered(2, base: 0.25)
                }
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

                // QR
                Button {
                    Haptics.impact(.light)
                } label: {
                    Label("Escanear código QR del psicólogo", systemImage: "qrcode.viewfinder")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .pressEffect()
                .padding(.horizontal, 24)
                .staggered(3, base: 0.25)

                Spacer(minLength: 20)
            }
        }
        .tag(tag)
        .onAppear { withAnimation { appeared = true } }
    }
}

struct WhiteConsentRow: View {
    let icon: String; let title: String; let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(.white).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold()).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color.white.opacity(0.9))
                .labelsHidden()
                .onChange(of: isOn) { _, _ in Haptics.selection() }
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
    }
}

// Kept for backward compatibility with ClinicianView
struct ConsentToggleRow: View {
    let icon: String; let title: String; let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).foregroundStyle(Theme.accent).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Toggle("", isOn: $isOn).tint(Theme.accent).labelsHidden()
                .onChange(of: isOn) { _, _ in Haptics.selection() }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}
