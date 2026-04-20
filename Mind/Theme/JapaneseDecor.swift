import SwiftUI

// MARK: — 🌸 Flor de sakura (vectorial)

/// Pétalo estilizado de flor de cerezo.
struct SakuraPetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h))
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: -w * 0.15, y: h * 0.65),
            control2: CGPoint(x: w * 0.1, y: h * 0.1)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w * 0.9, y: h * 0.1),
            control2: CGPoint(x: w * 1.15, y: h * 0.65)
        )
        // muesca superior del pétalo
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addQuadCurve(to: CGPoint(x: w * 0.42, y: h * 0.08), control: CGPoint(x: w * 0.45, y: h * 0.02))
        p.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.08), control: CGPoint(x: w * 0.5, y: h * 0.18))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: w * 0.55, y: h * 0.02))
        return p
    }
}

/// Flor completa de sakura (5 pétalos).
struct SakuraBlossom: View {
    var tint: Color = Theme.sakura
    var core: Color = Theme.sakuraDeep
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            ForEach(0..<5) { i in
                SakuraPetalShape()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.95), tint.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        SakuraPetalShape()
                            .stroke(core.opacity(0.35), lineWidth: 0.8)
                    )
                    .frame(width: size * 0.46, height: size)
                    .offset(y: -size * 0.28)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle()
                .fill(core.opacity(0.9))
                .frame(width: size * 0.24, height: size * 0.24)
            // estambres sutiles
            ForEach(0..<6) { i in
                Circle()
                    .fill(core.opacity(0.7))
                    .frame(width: size * 0.06, height: size * 0.06)
                    .offset(y: -size * 0.1)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: — 🌸 Lluvia de pétalos animada

struct SakuraRain: View {
    var petalCount: Int = 18
    @State private var animate = false

    private struct Petal: Identifiable {
        let id: Int
        let xStart: CGFloat     // 0..1
        let xEnd: CGFloat
        let delay: Double
        let duration: Double
        let size: CGFloat
        let rotation: Double
        let opacity: Double
    }

    private var petals: [Petal] {
        (0..<petalCount).map { i in
            let seed = Double(i) * 1.6180339887
            let xStart = CGFloat((seed.truncatingRemainder(dividingBy: 1.0)))
            let xEnd = CGFloat((seed * 0.73).truncatingRemainder(dividingBy: 1.0))
            return Petal(
                id: i,
                xStart: xStart,
                xEnd: xEnd,
                delay: Double(i) * 0.35,
                duration: 7 + Double(i % 4),
                size: 10 + CGFloat(i % 5) * 2.2,
                rotation: Double(i * 47 % 360),
                opacity: 0.55 + Double(i % 4) * 0.1
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(petals) { petal in
                    SakuraPetalShape()
                        .fill(Theme.sakura.opacity(petal.opacity))
                        .overlay(
                            SakuraPetalShape()
                                .stroke(Theme.sakuraDeep.opacity(0.3), lineWidth: 0.4)
                        )
                        .frame(width: petal.size * 0.55, height: petal.size)
                        .rotationEffect(.degrees(animate ? petal.rotation + 280 : petal.rotation))
                        .position(
                            x: animate ? petal.xEnd * geo.size.width : petal.xStart * geo.size.width,
                            y: animate ? geo.size.height + 40 : -40
                        )
                        .animation(
                            .linear(duration: petal.duration)
                                .repeatForever(autoreverses: false)
                                .delay(petal.delay),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
        }
        .allowsHitTesting(false)
    }
}

// MARK: — 🌊 Seigaiha (ondas tradicionales)

/// Patrón tradicional japonés de ondas concéntricas «青海波».
struct SeigaihaPattern: View {
    var color: Color = Theme.asagi
    var opacity: Double = 0.25
    var scale: CGFloat = 34

    var body: some View {
        Canvas { ctx, size in
            let radius = scale
            let stepX = radius
            let stepY = radius * 0.58
            var row = 0
            var y: CGFloat = -radius
            while y < size.height + radius {
                let offsetX: CGFloat = row.isMultiple(of: 2) ? 0 : stepX / 2
                var x: CGFloat = -radius + offsetX
                while x < size.width + radius {
                    for k in 0..<4 {
                        let r = radius - CGFloat(k) * (radius * 0.2)
                        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                        ctx.stroke(
                            Path { p in
                                p.addArc(
                                    center: CGPoint(x: x, y: y),
                                    radius: r,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(180),
                                    clockwise: true
                                )
                            },
                            with: .color(color.opacity(opacity * (1 - Double(k) * 0.2))),
                            lineWidth: 0.8
                        )
                        _ = rect
                    }
                    x += stepX
                }
                y += stepY
                row += 1
            }
        }
    }
}

// MARK: — Asanoha (patrón de hojas de cáñamo)

/// Patrón de triángulos entrelazados (麻の葉).
struct AsanohaPattern: View {
    var color: Color = Theme.matcha
    var opacity: Double = 0.18
    var scale: CGFloat = 28

    var body: some View {
        Canvas { ctx, size in
            let s = scale
            let h = s * 0.866
            var row = 0
            var y: CGFloat = -h
            while y < size.height + h {
                let offsetX = row.isMultiple(of: 2) ? 0 : s / 2
                var x: CGFloat = -s + offsetX
                while x < size.width + s {
                    let center = CGPoint(x: x, y: y)
                    var path = Path()
                    for i in 0..<6 {
                        let angle = Double(i) * .pi / 3
                        let p = CGPoint(
                            x: center.x + CGFloat(cos(angle)) * s / 2,
                            y: center.y + CGFloat(sin(angle)) * s / 2
                        )
                        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                    path.closeSubpath()
                    // rayos internos
                    for i in 0..<6 {
                        let angle = Double(i) * .pi / 3
                        let p = CGPoint(
                            x: center.x + CGFloat(cos(angle)) * s / 2,
                            y: center.y + CGFloat(sin(angle)) * s / 2
                        )
                        path.move(to: center)
                        path.addLine(to: p)
                    }
                    ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: 0.5)
                    x += s
                }
                y += h
                row += 1
            }
        }
    }
}

// MARK: — 🖌️ Divisor de pincel (sumi-e)

struct InkBrushDivider: View {
    var color: Color = Theme.sumi
    var body: some View {
        Canvas { ctx, size in
            let midY = size.height / 2
            var p = Path()
            p.move(to: CGPoint(x: 0, y: midY))
            p.addCurve(
                to: CGPoint(x: size.width, y: midY),
                control1: CGPoint(x: size.width * 0.3, y: midY - 2),
                control2: CGPoint(x: size.width * 0.7, y: midY + 2)
            )
            ctx.stroke(p, with: .color(color.opacity(0.35)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            // puntos de fin de pincel
            ctx.fill(Path(ellipseIn: CGRect(x: -2, y: midY - 2, width: 5, height: 5)), with: .color(color.opacity(0.4)))
            ctx.fill(Path(ellipseIn: CGRect(x: size.width - 3, y: midY - 2, width: 5, height: 5)), with: .color(color.opacity(0.4)))
        }
        .frame(height: 10)
    }
}

// MARK: — 🔴 Sello hanko (印鑑)

struct HankoStamp: View {
    var kanji: String
    var color: Color = Theme.aka
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(color, lineWidth: 2.5)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.06))
                )
            Text(kanji)
                .font(.system(size: size * 0.58, weight: .black, design: .serif))
                .foregroundStyle(color)
                .rotationEffect(.degrees(-2))
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(-4))
        .shadow(color: color.opacity(0.2), radius: 2, y: 1)
    }
}

// MARK: — ⛩️ Luna / Sol ornamental (círculo sumi-e)

struct EnsoCircle: View {
    var color: Color = Theme.sumi
    var lineWidth: CGFloat = 3

    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(x: lineWidth, y: lineWidth, width: size.width - lineWidth * 2, height: size.height - lineWidth * 2)
            var path = Path()
            // Arco casi cerrado (estilo enso · zen)
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.midY),
                radius: rect.width / 2,
                startAngle: .degrees(-80),
                endAngle: .degrees(270),
                clockwise: false
            )
            ctx.stroke(
                path,
                with: .color(color.opacity(0.85)),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
        }
    }
}

// MARK: — 🌸 Fondo de sección (marco de sakura + washi)

struct WashiSection<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Theme.cardBackground)
                    AsanohaPattern(color: Theme.matcha, opacity: 0.08)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    WashiNoise()
                        .blendMode(.multiply)
                        .opacity(0.08)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .allowsHitTesting(false)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Theme.inkLine, lineWidth: 0.6)
            )
            .shadow(color: Theme.sumi.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

// MARK: — ⛩️ Marco Torii sutil (encabezado decorativo)

struct ToriiHeader: View {
    var title: String
    var subtitle: String? = nil
    var kanji: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            if let kanji {
                Text(kanji)
                    .font(.system(size: 44, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.sumi.opacity(0.9))
            }
            Text(title)
                .font(.system(.title2, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.sumi)
            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.sumiSoft)
            }
            InkBrushDivider()
                .frame(width: 120)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }
}

extension View {
    /// Etiqueta tipo pergamino / kanji decorativo
    func kanjiBadge() -> some View {
        self
            .font(.system(.caption2, design: .serif).weight(.bold))
            .foregroundStyle(Theme.sumi)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Theme.kinari)
                    .overlay(Capsule().stroke(Theme.inkLine, lineWidth: 0.6))
            )
    }
}

// MARK: — 📜 Pergamino (Emakimono)

struct ScrollWrapper<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Papel continuo
            Theme.scrollPaper
                .ignoresSafeArea()
            
            WashiNoise()
                .blendMode(.multiply)
                .opacity(0.12)
                .ignoresSafeArea()

            content
        }
    }
}

struct ScrollRod: View {
    let isTop: Bool
    
    var body: some View {
        ZStack {
            // El eje de madera
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Theme.scrollWood, Theme.scrollWood.opacity(0.8), Theme.scrollWood],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 12)
                .shadow(color: .black.opacity(0.3), radius: 3, y: isTop ? 2 : -2)
            
            // Los terminales decorativos
            HStack {
                RodEnd()
                Spacer()
                RodEnd()
            }
        }
        .padding(.horizontal, -10)
    }
}

struct RodEnd: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Theme.scrollWood)
            .frame(width: 14, height: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Theme.kincha.opacity(0.5), lineWidth: 0.5)
            )
    }
}

// MARK: — ✨ Sparkles (magia zen)

struct FloatingSparkles: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<12) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 10...20)))
                        .foregroundStyle(Theme.tamago.opacity(0.6))
                        .position(
                            x: .random(in: 0...geo.size.width),
                            y: .random(in: 0...geo.size.height)
                        )
                        .scaleEffect(animate ? 1.2 : 0.8)
                        .opacity(animate ? 0.8 : 0.2)
                        .animation(
                            .easeInOut(duration: .random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(.random(in: 0...2)),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
        }
        .allowsHitTesting(false)
    }
}
