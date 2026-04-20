import SwiftUI

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
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addQuadCurve(to: CGPoint(x: w * 0.42, y: h * 0.08), control: CGPoint(x: w * 0.45, y: h * 0.02))
        p.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.08), control: CGPoint(x: w * 0.5, y: h * 0.18))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: w * 0.55, y: h * 0.02))
        return p
    }
}

struct WatchSakuraBlossom: View {
    var tint: Color = WatchTheme.sakura
    var core: Color = WatchTheme.sakuraDeep
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            ForEach(0..<5) { i in
                SakuraPetalShape()
                    .fill(tint.opacity(0.9))
                    .frame(width: size * 0.46, height: size)
                    .offset(y: -size * 0.28)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle()
                .fill(core.opacity(0.9))
                .frame(width: size * 0.24, height: size * 0.24)
        }
        .frame(width: size, height: size)
    }
}
