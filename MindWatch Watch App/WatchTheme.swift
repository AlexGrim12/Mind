import SwiftUI

enum WatchTheme {
    // MARK: — Palette (aligned with iOS)
    static let washi         = Color(hex: "#F5EDDC")
    static let sumi          = Color(hex: "#4A3F35")
    static let sumiSoft      = Color(hex: "#6D5F55")
    static let sakura        = Color(hex: "#F4C2C7")
    static let sakuraDeep    = Color(hex: "#D98A92")
    static let matcha        = Color(hex: "#89A97A")
    static let matchaDeep    = Color(hex: "#5E7C54")
    static let asagi         = Color(hex: "#6E9BB0")
    static let ai            = Color(hex: "#2E4A5F")
    static let tamago        = Color(hex: "#E8C474")
    static let sango         = Color(hex: "#E07B5B")
    static let aka           = Color(hex: "#D25454")
    static let kincha        = Color(hex: "#C9A25B")

    // MARK: — Semantic Roles
    static let background    = Color.black
    static let cardBackground = sumi.opacity(0.18)
    static let accent        = sakuraDeep

    // MARK: — Geometry
    static let cardRadius:   CGFloat = 16
    static let buttonRadius: CGFloat = 14

    // MARK: — Gradientes
    static let sakuraGradient = LinearGradient(
        colors: [sakura.opacity(0.8), sakuraDeep.opacity(0.8)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static func moodColor(for score: Int) -> Color {
        switch score {
        case 0...2: return Color(hex: "#8E6E99") // fuji
        case 3...4: return asagi
        case 5...6: return matcha
        case 7...8: return tamago
        default:    return sango
        }
    }
}

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

extension View {
    func watchCardStyle(color: Color = WatchTheme.sumi.opacity(0.12)) -> some View {
        self
            .padding(10)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WatchTheme.cardRadius, style: .continuous)
                    .stroke(color.opacity(0.2), lineWidth: 0.5)
            )
    }
}

// MARK: — Animation Extensions

extension Animation {
    static var springy: Animation { .spring(duration: 0.45, bounce: 0.3) }
    static var bouncy: Animation { .spring(duration: 0.5, bounce: 0.45) }
    static var smooth: Animation { .easeInOut(duration: 0.35) }
}
