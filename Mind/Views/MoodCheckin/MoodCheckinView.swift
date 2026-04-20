import SwiftUI
import SwiftData

struct MoodCheckinView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var score: Int = 5
    @State private var energy: Double = 0.5
    @State private var selectedContext: MoodContext = .home
    @State private var selectedCompany: MoodCompany = .alone
    @State private var selectedActivity: MoodActivity = .resting
    @State private var step = 0
    @State private var savedSuccessfully = false

    var body: some View {
        ZStack {
            AnimatedGradientBackground(score: score)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: score)

            VStack(spacing: 0) {
                // Handle + header
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.4))
                        .frame(width: 36, height: 4)
                        .padding(.top, 12)

                    HStack {
                        Button("Cancelar") { dismiss() }
                            .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text("Check-in")
                            .font(.headline.bold()).foregroundStyle(.white)
                        Spacer()
                        Text("Cancelar").font(.subheadline).opacity(0)
                    }
                    .padding(.horizontal, 24)
                }

                // Progress dots animados
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(.white.opacity(i <= step ? 1.0 : 0.3))
                            .frame(width: i == step ? 28 : 8, height: 8)
                            .animation(.springy, value: step)
                    }
                }
                .padding(.top, 16)

                // Contenido por step
                ZStack {
                    if step == 0 {
                        ScoreStep(score: $score)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                    removal: .move(edge: .leading).combined(with: .opacity)))
                    } else if step == 1 {
                        ContextStep(energy: $energy, selectedContext: $selectedContext,
                                    selectedCompany: $selectedCompany, selectedActivity: $selectedActivity)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                    removal: .move(edge: .leading).combined(with: .opacity)))
                    } else {
                        ConfirmStep(score: score, energy: energy, context: selectedContext,
                                    company: selectedCompany, activity: selectedActivity,
                                    saved: savedSuccessfully)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                    removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
                .animation(.springy, value: step)

                // Botones
                VStack(spacing: 12) {
                    Button {
                        if step < 2 {
                            Haptics.impact(.light)
                            withAnimation(.springy) { step += 1 }
                        } else {
                            save()
                        }
                    } label: {
                        Text(step == 0 ? "Siguiente" : step == 1 ? "Ver resumen" : "Guardar")
                            .primaryButton()
                    }
                    .pressEffect()
                    .padding(.horizontal, 24)

                    if step > 0 {
                        Button("Atrás") {
                            Haptics.impact(.light)
                            withAnimation(.springy) { step -= 1 }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .transition(.opacity)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func save() {
        Haptics.success()
        withAnimation(.springy) { savedSuccessfully = true }
        let entry = MoodEntry(score: score, energy: energy, context: selectedContext,
                              company: selectedCompany, activity: selectedActivity)
        context.insert(entry)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
    }
}

// MARK: — Step 1: Selector de score

struct ScoreStep: View {
    @Binding var score: Int
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Emoji + label
            VStack(spacing: 10) {
                Text(score.moodEmoji)
                    .font(.system(size: 80))
                    .shadow(radius: 8)
                    .scaleEffect(appeared ? 1 : 0.4)
                    .animation(.bouncy.delay(0.1), value: appeared)
                    .contentTransition(.numericText())
                    .animation(.springy, value: score)

                Text(score.moodLabel)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.smooth, value: score)

                Text("¿Cómo te sientes ahora mismo?")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .opacity(appeared ? 1 : 0)
                    .animation(.smooth.delay(0.2), value: appeared)
            }

            // Score bubbles con stagger
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ForEach(0...5, id: \.self) { i in
                        ScoreBubble(value: i, selected: score == i) {
                            Haptics.selection()
                            withAnimation(.springy) { score = i }
                        }
                        .staggered(i, base: 0.05)
                    }
                }
                HStack(spacing: 10) {
                    ForEach(6...10, id: \.self) { i in
                        ScoreBubble(value: i, selected: score == i) {
                            Haptics.selection()
                            withAnimation(.springy) { score = i }
                        }
                        .staggered(i - 6, base: 0.12)
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

struct ScoreBubble: View {
    let value: Int
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(selected ? .white : .white.opacity(0.18))
                    .frame(width: selected ? 54 : 44, height: selected ? 54 : 44)
                    .shadow(color: selected ? .black.opacity(0.15) : .clear, radius: 6, y: 3)

                if selected {
                    Circle()
                        .stroke(.white.opacity(0.6), lineWidth: 2)
                        .frame(width: 62, height: 62)
                        .scaleEffect(selected ? 1 : 0.8)
                        .opacity(selected ? 1 : 0)
                        .animation(.springy, value: selected)
                }

                Text("\(value)")
                    .font(.system(size: selected ? 20 : 15, weight: .bold))
                    .foregroundStyle(selected ? value.moodColor : .white)
            }
            .animation(.springy, value: selected)
        }
    }
}

// MARK: — Step 2: Energía y contexto

struct ContextStep: View {
    @Binding var energy: Double
    @Binding var selectedContext: MoodContext
    @Binding var selectedCompany: MoodCompany
    @Binding var selectedActivity: MoodActivity

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer(minLength: 8)
                Text("Un poco de contexto")
                    .font(.title2.bold()).foregroundStyle(.white)

                // Energy
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Energía").font(.headline).foregroundStyle(.white)
                        Spacer()
                        Text("\(Int(energy * 100))%")
                            .font(.headline.bold()).foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.smooth, value: energy)
                    }
                    HStack(spacing: 12) {
                        Text("😴").font(.title3)
                        Slider(value: $energy)
                            .tint(.white)
                            .onChange(of: energy) { _, _ in Haptics.selection() }
                        Text("⚡️").font(.title3)
                    }
                }
                .padding(18)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .staggered(0, base: 0.05)

                WhiteChipGroup(title: "¿Dónde?", items: MoodContext.allCases, selected: $selectedContext) {
                    ($0.icon, $0.rawValue)
                }
                .padding(.horizontal, 24)
                .staggered(1, base: 0.05)

                WhiteChipGroup(title: "¿Con quién?", items: MoodCompany.allCases, selected: $selectedCompany) {
                    ($0.icon, $0.rawValue)
                }
                .padding(.horizontal, 24)
                .staggered(2, base: 0.05)

                WhiteChipGroup(title: "¿Qué haces?", items: MoodActivity.allCases, selected: $selectedActivity) {
                    ($0.icon, $0.rawValue)
                }
                .padding(.horizontal, 24)
                .staggered(3, base: 0.05)

                Spacer(minLength: 20)
            }
        }
    }
}

struct WhiteChipGroup<T: Hashable & CaseIterable>: View {
    let title: String
    let items: [T]
    @Binding var selected: T
    let label: (T) -> (String, String)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(.white)
            HStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    let (icon, text) = label(item)
                    let isSelected = item == selected
                    Button {
                        Haptics.selection()
                        withAnimation(.springy) { selected = item }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: icon).font(.caption)
                            Text(text).font(.subheadline)
                        }
                        .foregroundStyle(isSelected ? Theme.accent : .white)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(isSelected ? .white : .white.opacity(0.2))
                        .clipShape(Capsule())
                        .scaleEffect(isSelected ? 1.05 : 1)
                        .animation(.springy, value: isSelected)
                    }
                }
            }
        }
    }
}

// MARK: — Step 3: Confirmación

struct ConfirmStep: View {
    let score: Int
    let energy: Double
    let context: MoodContext
    let company: MoodCompany
    let activity: MoodActivity
    let saved: Bool

    @State private var checkScale: CGFloat = 0
    @State private var rowsVisible = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Check / guardado
            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(saved ? 1.2 : 1)
                    .opacity(saved ? 0 : 1)
                    .animation(.easeOut(duration: 0.5), value: saved)

                Image(systemName: saved ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                    .scaleEffect(checkScale)
                    .animation(.bouncy, value: checkScale)
                    .symbolEffect(.bounce, value: saved)
            }

            VStack(spacing: 8) {
                Text(saved ? "¡Guardado!" : "Todo listo")
                    .font(.title.bold()).foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.smooth, value: saved)
                Text("Solo en tu iPhone · nadie más lo ve")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.75))
            }

            // Resumen
            VStack(spacing: 14) {
                ConfirmRow(icon: "face.smiling", text: "\(score)/10 · \(score.moodLabel)")
                ConfirmRow(icon: "bolt", text: "Energía \(Int(energy * 100))%")
                ConfirmRow(icon: context.icon, text: context.rawValue)
                ConfirmRow(icon: company.icon, text: company.rawValue)
                ConfirmRow(icon: activity.icon, text: activity.rawValue)
            }
            .padding(20)
            .background(.white.opacity(rowsVisible ? 0.15 : 0))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 32)
            .animation(.springy.delay(0.1), value: rowsVisible)

            Spacer()
        }
        .onAppear {
            withAnimation(.bouncy.delay(0.15)) { checkScale = 1 }
            withAnimation(.springy.delay(0.2)) { rowsVisible = true }
        }
    }
}

struct ConfirmRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.white.opacity(0.9)).frame(width: 24)
            Text(text).font(.subheadline).foregroundStyle(.white)
            Spacer()
        }
    }
}
