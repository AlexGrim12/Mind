import SwiftUI

// MARK: — 和 Tema japonés · Pergamino washi, sakura, matcha, tinta sumi

enum Theme {
    // MARK: — Paleta tradicional (nombres japoneses)
    /// Washi · 和紙 · papel de arroz crudo (fondo base)
    static let washi         = Color(hex: "#F5EDDC")
    /// Kinari · 生成り · beige natural
    static let kinari        = Color(hex: "#EFE4CE")
    /// Kohaku · 琥珀 · ámbar tenue (sombras en papel)
    static let kohaku        = Color(hex: "#E3D3B3")
    /// Pergamino base · papel envejecido
    static let scrollPaper   = Color(hex: "#F2E6CE")
    /// Madera de jiku · terminales del pergamino
    static let scrollWood    = Color(hex: "#3D2B1F")
    /// Sumi · 墨 · tinta china (texto principal)
    static let sumi          = Color(hex: "#4A3F35")
    /// Sumi suave · gris tinta aguada
    static let sumiSoft      = Color(hex: "#6D5F55")
    /// Sakura · 桜 · rosa flor de cerezo
    static let sakura        = Color(hex: "#F4C2C7")
    /// Sakura intensa · benikakehana
    static let sakuraDeep    = Color(hex: "#D98A92")
    /// Matcha · 抹茶 · verde té
    static let matcha        = Color(hex: "#89A97A")
    /// Matcha profundo · ocha
    static let matchaDeep    = Color(hex: "#5E7C54")
    /// Asagi · 浅葱 · azul celeste tradicional
    static let asagi         = Color(hex: "#6E9BB0")
    /// Ai · 藍 · índigo japonés
    static let ai            = Color(hex: "#2E4A5F")
    /// Tamago · 卵色 · amarillo yema
    static let tamago        = Color(hex: "#E8C474")
    /// Sango · 珊瑚色 · coral
    static let sango         = Color(hex: "#E07B5B")
    /// Aka · 赤 · rojo lacado (emergencia)
    static let aka           = Color(hex: "#D25454")
    /// Kincha · 金茶 · oro-té (detalles)
    static let kincha        = Color(hex: "#C9A25B")

    // MARK: — Roles semánticos (compat con vistas existentes)
    static let accent        = ai                 // acción primaria · índigo profundo
    static let accentSoft    = asagi
    static let secondary     = matcha
    static let background    = washi
    static let textPrimary   = sumi
    static let crisisRed     = aka
    static let accentPurple  = Color(hex: "#5A506A") // koki-purpur · púrpura oscuro
    static let accentPink    = sango              // coral tierra en lugar de rosa
    static let accentMint    = matcha

    // MARK: — Mood spectrum (reinterpretado con paleta japonesa)
    static let moodPurple    = Color(hex: "#8E6E99") // fuji · glicina (muy bajo)
    static let moodBlue      = asagi                  // asagi (bajo)
    static let moodGreen     = matcha                 // matcha (neutro)
    static let moodYellow    = tamago                 // tamago (bien)
    static let moodOrange    = sango                  // sango (excelente)

    // MARK: — Neutrales de superficie
    static let cardBackground = Color(hex: "#FBF5E8")    // papel más claro
    static let secondaryText  = sumiSoft
    static let surface        = Color(hex: "#EADFC7")    // washi sombreado
    static let borderSoft     = sumi.opacity(0.08)
    static let inkLine        = sumi.opacity(0.22)

    // MARK: — Geometría (más orgánica, inspirada en madera y papel)
    static let cardRadius:   CGFloat = 28
    static let buttonRadius: CGFloat = 24
    static let pillRadius:   CGFloat = 100

    // MARK: — Gradientes estilo pergamino
    /// Fondo general: papel washi antiguo con viso rosado
    static let appBackground = LinearGradient(
        colors: [
            Color(hex: "#F7EFDC"),
            Color(hex: "#F5E5D5"),
            Color(hex: "#F6DCD9")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradiente hero por defecto: niebla sobre montañas (índigo y asagi)
    static let heroGradient = LinearGradient(
        colors: [
            Color(hex: "#4A5D6B"),
            Color(hex: "#6E9BB0"),
            Color(hex: "#A8C09A")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradiente principal (reemplaza al sakura)
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#3E5A72"), Color(hex: "#2E4A5F")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )


    /// Gradiente sakura (acción primaria)
    static let sakuraGradient = LinearGradient(
        colors: [Color(hex: "#F8D4D8"), Color(hex: "#D98A92")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradiente indigo (noche / sueño)
    static let yoruGradient = LinearGradient(
        colors: [Color(hex: "#3E5A72"), Color(hex: "#1F3145")],
        startPoint: .topLeading,
        endPoint: .bottom
    )

    // MARK: — Fondos ambientales
    static var ambientBackground: some View {
        ZStack {
            appBackground.ignoresSafeArea()
            
            // Elementos inmersivos zen
            ZStack {
                ZenCloud()
                    .offset(y: -250)
                ZenCloud()
                    .offset(x: 150, y: -180)
                
                VStack {
                    Spacer()
                    HStack {
                        BambooGrove()
                            .opacity(0.4)
                        Spacer()
                    }
                }
            }
            .allowsHitTesting(false)

            // Viñeta superior fría (niebla)
            RadialGradient(
                colors: [asagi.opacity(0.15), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 420
            )
            .ignoresSafeArea()
            // Toque tierra/ámbar en la esquina inferior
            RadialGradient(
                colors: [kohaku.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 420
            )
            .ignoresSafeArea()
            // Grano sutil de papel
            WashiNoise()
                .blendMode(.multiply)
                .opacity(0.08)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    // MARK: — Mood helpers
    static func moodGradient(for score: Int) -> LinearGradient {
        let (c1, c2) = moodGradientColors(score)
        return LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private static func moodGradientColors(_ score: Int) -> (Color, Color) {
        switch score {
        // Muy bajo · fuji · glicina profunda
        case 0...2: return (Color(hex: "#6C567B"), Color(hex: "#A389B1"))
        // Bajo · asagi · azul lluvia
        case 3...4: return (Color(hex: "#3E617A"), Color(hex: "#8BAEC5"))
        // Neutro · matcha
        case 5...6: return (Color(hex: "#5E7C54"), Color(hex: "#A8C09A"))
        // Bien · tamago · yema
        case 7...8: return (Color(hex: "#C89A45"), Color(hex: "#F1D894"))
        // Excelente · sango · coral
        default:    return (Color(hex: "#C25A3B"), Color(hex: "#F0A68B"))
        }
    }
}

// MARK: — 🌸 WashiNoise · textura sutil de papel de arroz

/// Genera un grano irregular tipo fibra de papel washi (determinístico).
struct WashiNoise: View {
    var body: some View {
        Canvas { ctx, size in
            var seed: UInt64 = 0x77617368 // "wash"
            func rnd() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double((seed >> 33) & 0xFFFFFFFF) / Double(0xFFFFFFFF)
            }
            let count = Int(size.width * size.height / 900)
            for _ in 0..<count {
                let x = rnd() * size.width
                let y = rnd() * size.height
                let r = 0.4 + rnd() * 0.9
                let alpha = 0.04 + rnd() * 0.12
                let shade = rnd() > 0.5 ? Color.black : Color(hex: "#5E4C3D")
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(shade.opacity(alpha))
                )
            }
        }
    }
}

// MARK: — View modifiers

extension View {
    /// Tarjeta con apariencia de papel washi: borde de tinta fino, sombra cálida y ligera textura.
    func cardStyle(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                        .fill(Theme.cardBackground.opacity(0.85))

                    // Textura fibrosa
                    WashiNoise()
                        .blendMode(.multiply)
                        .opacity(0.1)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                        .allowsHitTesting(false)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.inkLine, lineWidth: 0.8)
            )
            .shadow(color: Theme.sumi.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    /// Botón principal: sello japonés estilo hanko con gradiente sakura y sombra cálida.
    func primaryButton(color: Color = Theme.ai) -> some View {
        self
            .font(.system(.headline, design: .serif).weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                    .stroke(.white.opacity(0.35), lineWidth: 0.8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                    .stroke(color.opacity(0.35), lineWidth: 0.5)
                    .blur(radius: 0.5)
            )
            .shadow(color: color.opacity(0.35), radius: 14, x: 0, y: 8)
    }

    /// Tarjeta traslúcida estilo shoji (puerta de papel): se usa sobre imágenes/gradientes.
    func glassCard(opacity: Double = 0.4) -> some View {
        self
            .background(.ultraThinMaterial)
            .background(Theme.cardBackground.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 0.8)
            )
            .overlay(
                // Marco de tinta al estilo cajita shoji
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.inkLine, lineWidth: 0.5)
            )
    }

    /// Fondo global de la app (pergamino washi con viñeteo asagi y kohaku).
    func screenBackground() -> some View {
        self.background(Theme.ambientBackground)
    }

    /// Título de sección Zen con estilo uniforme
    func zenSectionHeader(title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.zenHeadline)
                .foregroundStyle(Theme.sumi)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.zenCaption)
                    .foregroundStyle(Theme.sumiSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    /// Etiqueta tipo 印 (hanko · sello rojo).
    func hankoLabel() -> some View {
        self
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.aka.opacity(0.92), in: RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
            )
    }
}

// MARK: — Reusable Components

struct ZenSkyView: View {
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
            .overlay(Circle().fill(.white.opacity(0.2)).frame(width: 100).blur(radius: 20).offset(x: -80, y: -60))
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

    /// Kanji simbólico del estado (muy bajo → excelente)
    var moodKanji: String {
        switch self {
        case 0...2: return "雨" // lluvia
        case 3...4: return "曇" // nublado
        case 5...6: return "風" // viento
        case 7...8: return "晴" // despejado
        default:    return "陽" // sol
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
        case 5...6: return "🌸"
        case 7...8: return "🌼"
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

// MARK: — Tipografía zen (helpers)

extension Font {
    /// Título grande caligráfico
    static var zenTitle: Font { .system(.largeTitle, design: .serif).weight(.semibold) }
    /// Subtítulo zen
    static var zenHeadline: Font { .system(.headline, design: .serif).weight(.semibold) }
    /// Cuerpo zen
    static var zenBody: Font { .system(.body, design: .serif) }
    /// Etiqueta pequeña
    static var zenCaption: Font { .system(.caption, design: .serif).weight(.medium) }
}
