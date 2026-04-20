import SwiftUI

enum Theme {
    // MARK: — Brand colors
    static let accent       = Color("AccentBlue")       // #2D7DD2
    static let background   = Color("BackgroundPrimary") // #F5F7FA
    static let textPrimary  = Color("TextPrimary")       // #1A1A2E
    static let crisisRed    = Color("CrisisRed")         // #E63946

    // MARK: — Mood spectrum
    static let moodPurple = Color(hex: "#7B2FBE")
    static let moodBlue   = Color(hex: "#2D7DD2")
    static let moodGreen  = Color(hex: "#2DC653")
    static let moodYellow = Color(hex: "#F5C518")
    static let moodOrange = Color(hex: "#F4845F")

    // MARK: — Neutrals
    static let cardBackground = Color(.systemBackground)
    static let secondaryText  = Color(.secondaryLabel)
    static let surface        = Color(.secondarySystemBackground)
    static let borderSoft     = Color.black.opacity(0.06)

    // MARK: — Geometry
    static let cardRadius:   CGFloat = 20
    static let buttonRadius: CGFloat = 16
    static let pillRadius:   CGFloat = 100

    // MARK: — Gradients
    static let appBackground = LinearGradient(
        colors: [Color(hex: "#EAF1FA"), Color(hex: "#F8FAFD"), Color(hex: "#EEF3F9")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [Color(hex: "#1a3a5c"), Color(hex: "#2D7DD2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static func moodGradient(for score: Int) -> LinearGradient {
        let (c1, c2) = moodGradientColors(score)
        return LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    private static func moodGradientColors(_ score: Int) -> (Color, Color) {
        switch score {
        case 0...2: return (Color(hex: "#4A1080"), Color(hex: "#7B2FBE"))
        case 3...4: return (Color(hex: "#1a3a6c"), Color(hex: "#2D7DD2"))
        case 5...6: return (Color(hex: "#1a6c3a"), Color(hex: "#2DC653"))
        case 7...8: return (Color(hex: "#8a7010"), Color(hex: "#F5C518"))
        default:    return (Color(hex: "#8a4020"), Color(hex: "#F4845F"))
        }
    }
}

// MARK: — View modifiers

extension View {
    func cardStyle(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.borderSoft, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 8)
            .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
    }

    func primaryButton(color: Color = Theme.accent) -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.9), color],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.28), radius: 12, x: 0, y: 6)
    }

    func glassCard(opacity: Double = 0.15) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(.white.opacity(opacity), lineWidth: 1)
            )
    }

    func screenBackground() -> some View {
        self.background(Theme.appBackground.ignoresSafeArea())
    }
}

// MARK: — Mood helpers

extension Int {
    var moodColor: Color {
        switch self {
        case 0...2: return Theme.moodPurple
        case 3...4: return Theme.moodBlue
        case 5...6: return Theme.moodGreen
        case 7...8: return Theme.moodYellow
        default:    return Theme.moodOrange
        }
    }

    var moodLabel: String {
        switch self {
        case 0...2: return "Muy bajo"
        case 3...4: return "Bajo"
        case 5...6: return "Neutral"
        case 7...8: return "Bien"
        default:    return "Excelente"
        }
    }

    var moodEmoji: String {
        switch self {
        case 0...2: return "🌧"
        case 3...4: return "☁️"
        case 5...6: return "⛅️"
        case 7...8: return "🌤"
        default:    return "☀️"
        }
    }

    var moodGradient: LinearGradient { Theme.moodGradient(for: self) }
}

// MARK: — Color from hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
