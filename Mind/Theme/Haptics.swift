import SwiftUI

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func selection()  { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: — Reusable animation presets

extension Animation {
    static let springy    = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let snappy     = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let bouncy     = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let smooth     = Animation.easeInOut(duration: 0.35)
    static let slowFade   = Animation.easeInOut(duration: 0.6)
}

// MARK: — Staggered appearance modifier

struct StaggeredAppear: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .onAppear {
                withAnimation(.springy.delay(baseDelay + Double(index) * 0.07)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggered(_ index: Int, base: Double = 0.1) -> some View {
        modifier(StaggeredAppear(index: index, baseDelay: base))
    }

    /// Subtle press scale feedback
    func pressEffect() -> some View {
        buttonStyle(PressButtonStyle())
    }
}

struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}

// MARK: — Shimmer effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width * 2)
                .offset(x: geo.size.width * phase)
            }
            .clipped()
        )
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}
