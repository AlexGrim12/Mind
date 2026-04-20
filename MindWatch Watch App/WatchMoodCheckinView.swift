import SwiftUI

struct WatchMoodCheckinView: View {
    @EnvironmentObject private var store: WatchStore
    @Environment(\.dismiss) private var dismiss

    @State private var score = 5
    @State private var phase: Phase = .pick
    @State private var confirmed = false

    enum Phase { case pick, confirm, done }

    private var scoreColor: Color {
        WatchTheme.moodColor(for: score)
    }

    private var emoji: String {
        switch score {
        case 0...2: return "🌧"
        case 3...4: return "☁️"
        case 5...6: return "🌸"
        case 7...8: return "🌼"
        default:    return "☀️"
        }
    }
    
    private var moodLabel: String {
        switch score {
        case 0...2: return "Muy bajo"
        case 3...4: return "Bajo"
        case 5...6: return "Neutral"
        case 7...8: return "Bien"
        default:    return "Excelente"
        }
    }

    var body: some View {
        ZStack {
            WatchTheme.background.ignoresSafeArea()
            
            switch phase {
            case .pick:   pickView
            case .confirm: confirmView
            case .done:   doneView
            }
        }
    }

    // MARK: Pick

    private var pickView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                Text(emoji)
                    .font(.system(size: 34))
            }
            .animation(.bouncy, value: score)

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                    .contentTransition(.numericText())
                Text(moodLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .animation(.smooth, value: score)

            // Scroll picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0...10, id: \.self) { i in
                        Button {
                            WKInterfaceDevice.current().play(.click)
                            withAnimation(.springy) { score = i }
                        } label: {
                            Text("\(i)")
                                .font(.system(size: 14, weight: score == i ? .bold : .medium))
                                .frame(width: 34, height: 34)
                                .background(score == i ? scoreColor : Color(.darkGray).opacity(0.5))
                                .foregroundStyle(score == i ? .white : .secondary)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(score == i ? .white.opacity(0.3) : .clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
            }

            Button {
                WKInterfaceDevice.current().play(.success)
                withAnimation(.springy) { phase = .confirm }
            } label: {
                Text("Siguiente")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(scoreColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
        }
    }

    // MARK: Confirm

    private var confirmView: some View {
        VStack(spacing: 14) {
            WatchSakuraBlossom(tint: scoreColor.opacity(0.8), core: scoreColor, size: 30)
            
            Text("¿Confirmar \(score)/10?")
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Button {
                    WKInterfaceDevice.current().play(.success)
                    store.sendMood(score: score)
                    withAnimation(.springy) { phase = .done }
                } label: {
                    Text("Sí, guardar")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(scoreColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button("Cambiar") {
                    withAnimation { phase = .pick }
                } 
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: Done

    private var doneView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(WatchTheme.matcha)
                .scaleEffect(confirmed ? 1 : 0.3)
                .animation(.bouncy.delay(0.05), value: confirmed)

            Text("¡Hecho!")
                .font(.system(size: 16, weight: .bold))

            Text("Sincronizado con iPhone")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            withAnimation { confirmed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
        }
    }
}
