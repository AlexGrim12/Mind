import SwiftUI

/// A simple animated gradient background that reacts to a mood score (0...10).
/// Lower scores skew toward cool/blue, higher scores toward warm/orange.
public struct AnimatedGradientBackground: View {
    public let score: Int
    @State private var animate = false

    public init(score: Int) {
        self.score = score
    }

    public var body: some View {
        let clamped = max(0, min(10, score))
        let t = Double(clamped) / 10.0
        // Interpolate between two color palettes
        let start = Color(hue: 0.58 - 0.18 * t, saturation: 0.65 + 0.15 * t, brightness: 0.95)
        let end   = Color(hue: 0.62 - 0.42 * t, saturation: 0.55 + 0.30 * t, brightness: 0.85)

        // Subtle motion using angular gradient rotation
        ZStack {
            AngularGradient(gradient: Gradient(colors: [start, end, start]), center: .center)
                .hueRotation(.degrees(animate ? 10 : -10))
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animate)
                .overlay(
                    RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.10), Color.clear]), center: .center, startRadius: 0, endRadius: 600)
                )
        }
        .onAppear { animate = true }
        .onChange(of: score) { _, _ in
            // Smooth transition when score changes
            withAnimation(.easeInOut(duration: 0.5)) { /* color recompute driven by state */ }
        }
    }
}

#Preview("AnimatedGradientBackground") {
    VStack(spacing: 20) {
        AnimatedGradientBackground(score: 3)
            .ignoresSafeArea()
            .overlay(Text("Score 3").font(.headline).foregroundStyle(.white))
    }
}
