import SwiftUI

struct WatchBreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phase: BreathPhase = .inhale
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.5
    @State private var cycleCount = 0
    @State private var timer: Timer?

    enum BreathPhase: String {
        case inhale = "Inhala"
        case hold   = "Sostén"
        case exhale = "Exhala"
    }

    var body: some View {
        ZStack {
            WatchTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    // Círculos de respiración tipo aura
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(WatchTheme.matcha.opacity(0.12 - Double(i) * 0.03))
                            .scaleEffect(scale + CGFloat(i) * 0.2)
                            .animation(
                                .easeInOut(duration: phaseDuration).delay(Double(i) * 0.1),
                                value: scale
                            )
                    }
                    
                    // Sakura central
                    WatchSakuraBlossom(tint: WatchTheme.matcha, core: WatchTheme.matchaDeep, size: 40)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(scale * 360))
                        .animation(.easeInOut(duration: phaseDuration), value: scale)
                }
                .frame(width: 100, height: 100)

                VStack(spacing: 4) {
                    Text(phase.rawValue)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(WatchTheme.washi)
                        .animation(.smooth, value: phase)

                    Text("\(4 - cycleCount) respiraciones")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            VStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Finalizar")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(.darkGray).opacity(0.4))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 2)
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
            withAnimation(.easeInOut(duration: 4)) { scale = 1.2; opacity = 1.0 }
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
            withAnimation(.easeInOut(duration: 4)) { scale = 0.6; opacity = 0.5 }
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
