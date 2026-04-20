import SwiftUI

struct WatchMoodCheckinView: View {
    @EnvironmentObject private var store: WatchStore
    @Environment(\.dismiss) private var dismiss

    @State private var score = 5
    @State private var phase: Phase = .pick
    @State private var confirmed = false

    enum Phase { case pick, confirm, done }

    private var scoreColor: Color {
        switch score {
        case 0...3: return .purple
        case 4...5: return .blue
        case 6...7: return .green
        case 8...9: return .yellow
        default:    return .orange
        }
    }

    private var emoji: String {
        switch score {
        case 0...2: return "😔"
        case 3...4: return "😐"
        case 5...6: return "🙂"
        case 7...8: return "😊"
        default:    return "🤩"
        }
    }

    var body: some View {
        switch phase {
        case .pick:   pickView
        case .confirm: confirmView
        case .done:   doneView
        }
    }

    // MARK: Pick

    private var pickView: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 40))
                .animation(.bouncy, value: score)

            Text("\(score)")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(scoreColor)
                .contentTransition(.numericText())
                .animation(.smooth, value: score)

            Text("de 10")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            // Scroll picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0...10, id: \.self) { i in
                        Button {
                            WKInterfaceDevice.current().play(.click)
                            withAnimation(.springy) { score = i }
                        } label: {
                            Text("\(i)")
                                .font(.system(size: 14, weight: score == i ? .bold : .regular))
                                .frame(width: 32, height: 32)
                                .background(score == i ? scoreColor : Color(.darkGray))
                                .foregroundStyle(score == i ? .white : .secondary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }

            Button("Guardar") {
                WKInterfaceDevice.current().play(.success)
                withAnimation(.springy) { phase = .confirm }
            }
            .buttonStyle(.borderedProminent)
            .tint(scoreColor)
        }
    }

    // MARK: Confirm

    private var confirmView: some View {
        VStack(spacing: 12) {
            Text(emoji).font(.system(size: 44))
            Text("¿Confirmar \(score)/10?")
                .font(.system(size: 13, weight: .semibold))
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Button("Cambiar") {
                    withAnimation { phase = .pick }
                } .buttonStyle(.bordered)

                Button("Sí") {
                    WKInterfaceDevice.current().play(.success)
                    store.sendMood(score: score)
                    withAnimation(.springy) { phase = .done }
                }
                .buttonStyle(.borderedProminent)
                .tint(scoreColor)
            }
        }
    }

    // MARK: Done

    private var doneView: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
                .scaleEffect(confirmed ? 1 : 0.3)
                .animation(.bouncy.delay(0.05), value: confirmed)

            Text("¡Registrado!")
                .font(.system(size: 15, weight: .bold))

            Text("Tu iPhone lo recibió")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            withAnimation { confirmed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
        }
    }
}

// Reuse Animation extensions on Watch side
extension Animation {
    static var springy: Animation { .spring(duration: 0.45, bounce: 0.3) }
    static var bouncy: Animation { .spring(duration: 0.5, bounce: 0.45) }
}
