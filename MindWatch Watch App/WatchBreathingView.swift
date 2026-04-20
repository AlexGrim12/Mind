import SwiftUI

struct WatchBreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phase: BreathPhase = .inhale
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.4
    @State private var cycleCount = 0
    @State private var timer: Timer?

    enum BreathPhase: String {
        case inhale = "Inhala"
        case hold   = "Sostén"
        case exhale = "Exhala"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.teal.opacity(0.15 - Double(i) * 0.04))
                            .scaleEffect(scale + CGFloat(i) * 0.15)
                            .animation(
                                .easeInOut(duration: phaseDuration).delay(Double(i) * 0.1),
                                value: scale
                            )
                    }
                    Circle()
                        .fill(Color.teal.opacity(0.7))
                        .frame(width: 50, height: 50)
                        .scaleEffect(scale)
                        .animation(.easeInOut(duration: phaseDuration), value: scale)
                }
                .frame(width: 80, height: 80)

                Text(phase.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .animation(.smooth, value: phase)

                Text("\(4 - cycleCount % 4) ciclos restantes")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            VStack {
                Spacer()
                Button("Listo") { dismiss() }
                    .buttonStyle(.bordered)
                    .padding(.bottom, 4)
            }
        }
        .onAppear { startCycle() }
        .onDisappear { timer?.invalidate() }
    }

    private var phaseDuration: Double {
        switch phase {
        case .inhale: return 4
        case .hold:   return 2
        case .exhale: return 4
        }
    }

    private func startCycle() {
        nextPhase()
    }

    private func nextPhase() {
        switch phase {
        case .inhale:
            withAnimation(.easeInOut(duration: 4)) { scale = 1.0; opacity = 0.8 }
            schedule(after: 4) {
                phase = .hold
                nextPhase()
            }
        case .hold:
            schedule(after: 2) {
                phase = .exhale
                nextPhase()
            }
        case .exhale:
            withAnimation(.easeInOut(duration: 4)) { scale = 0.5; opacity = 0.4 }
            schedule(after: 4) {
                cycleCount += 1
                phase = .inhale
                if cycleCount < 4 { nextPhase() }
                else { WKInterfaceDevice.current().play(.success); dismiss() }
            }
        }
    }

    private func schedule(after delay: Double, block: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            DispatchQueue.main.async { block() }
        }
    }
}
