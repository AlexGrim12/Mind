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
            Theme.ambientBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cerrar") { dismiss() }
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.sumiSoft)
                    Spacer()
                    Text("Auto-reflexión")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Theme.sumi)
                    Spacer()
                    Text("Cerrar").opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Progress dots (Zen style)
                HStack(spacing: 12) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i <= step ? Theme.ai : Theme.sumi.opacity(0.1))
                            .frame(width: 6, height: 6)
                            .overlay(
                                Circle()
                                    .stroke(Theme.ai.opacity(0.3), lineWidth: i == step ? 4 : 0)
                                    .scaleEffect(i == step ? 1.5 : 1)
                            )
                            .animation(.springy, value: step)
                    }
                }
                .padding(.top, 16)

                // Contenido
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

                Spacer()

                // Botones
                VStack(spacing: 16) {
                    Button {
                        if step < 2 {
                            Haptics.impact(.light)
                            withAnimation(.springy) { step += 1 }
                        } else {
                            save()
                        }
                    } label: {
                        Text(step == 0 ? "Continuar" : step == 1 ? "Revisar" : "Guardar")
                            .primaryButton()
                    }
                    .pressEffect()
                    .padding(.horizontal, 30)

                    if step > 0 {
                        Button("Volver") {
                            Haptics.impact(.light)
                            withAnimation(.springy) { step -= 1 }
                        }
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.sumiSoft)
                        .transition(.opacity)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }

    private func save() {
        Haptics.success()
        withAnimation(.springy) { savedSuccessfully = true }
        let entry = MoodEntry(score: score, energy: energy, context: selectedContext,
                              company: selectedCompany, activity: selectedActivity)
        context.insert(entry)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }
}

// MARK: — Step 1: Selector de score (Zen)

struct ScoreStep: View {
    @Binding var score: Int
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Kanji + label
            VStack(spacing: 16) {
                ZStack {
                    EnsoCircle(color: score.moodColor, lineWidth: 3)
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(Double(score) * 10))
                        .animation(.spring(duration: 0.8), value: score)
                    
                    Text(score.moodKanji)
                        .font(.system(size: 80, weight: .black, design: .serif))
                        .foregroundStyle(Theme.sumi)
                        .shadow(color: score.moodColor.opacity(0.2), radius: 10)
                        .scaleEffect(appeared ? 1 : 0.4)
                        .animation(.bouncy.delay(0.1), value: appeared)
                }

                VStack(spacing: 4) {
                    Text(score.moodLabel)
                        .font(.system(.title, design: .serif).weight(.bold))
                        .foregroundStyle(Theme.sumi)
                    
                    Text("¿Cómo está tu mente en este momento?")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.sumiSoft)
                }
                .opacity(appeared ? 1 : 0)
                .animation(.smooth.delay(0.2), value: appeared)
            }

            // Score bubbles (Zen stones)
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ForEach(0...5, id: \.self) { i in
                        ZenStoneBubble(value: i, selected: score == i) {
                            Haptics.selection()
                            withAnimation(.springy) { score = i }
                        }
                    }
                }
                HStack(spacing: 12) {
                    ForEach(6...10, id: \.self) { i in
                        ZenStoneBubble(value: i, selected: score == i) {
                            Haptics.selection()
                            withAnimation(.springy) { score = i }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

struct ZenStoneBubble: View {
    let value: Int
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(selected ? value.moodColor : Theme.kinari.opacity(0.5))
                    .frame(width: selected ? 50 : 40, height: selected ? 50 : 40)
                    .shadow(color: Theme.sumi.opacity(selected ? 0.2 : 0.05), radius: 5, y: 2)

                Text("\(value)")
                    .font(.system(size: selected ? 18 : 14, weight: .bold, design: .serif))
                    .foregroundStyle(selected ? .white : Theme.sumiSoft)
            }
            .animation(.springy, value: selected)
        }
    }
}

// MARK: — Step 2: Energía y contexto (Estilo Washi)

struct ContextStep: View {
    @Binding var energy: Double
    @Binding var selectedContext: MoodContext
    @Binding var selectedCompany: MoodCompany
    @Binding var selectedActivity: MoodActivity

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer(minLength: 10)
                
                ToriiHeader(title: "Contexto", subtitle: "Define tu entorno actual")

                // Energy
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Energía Vital").font(.system(.headline, design: .serif)).foregroundStyle(Theme.sumi)
                        Spacer()
                        Text("\(Int(energy * 100))%")
                            .font(.system(.headline, design: .serif).weight(.bold))
                            .foregroundStyle(Theme.ai)
                    }
                    
                    HStack(spacing: 16) {
                        Text("静").font(.caption).foregroundStyle(Theme.sumiSoft) // Quiet
                        Slider(value: $energy)
                            .tint(Theme.ai)
                        Text("動").font(.caption).foregroundStyle(Theme.sumiSoft) // Action
                    }
                }
                .cardStyle()
                .padding(.horizontal, 24)

                ZenChipGroup(title: "¿Dónde estás?", items: MoodContext.allCases, selected: $selectedContext) {
                    ($0.icon, $0.rawValue)
                }
                .padding(.horizontal, 24)

                ZenChipGroup(title: "¿Quién te acompaña?", items: MoodCompany.allCases, selected: $selectedCompany) {
                    ($0.icon, $0.rawValue)
                }
                .padding(.horizontal, 24)

                ZenChipGroup(title: "¿Qué actividad realizas?", items: MoodActivity.allCases, selected: $selectedActivity) {
                    ($0.icon, $0.rawValue)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 30)
            }
        }
    }
}

struct ZenChipGroup<T: Hashable & CaseIterable>: View {
    let title: String
    let items: [T]
    @Binding var selected: T
    let label: (T) -> (String, String)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(.subheadline, design: .serif).weight(.semibold)).foregroundStyle(Theme.sumiSoft)
            
            FlowLayout(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    let (icon, text) = label(item)
                    let isSelected = item == selected
                    Button {
                        Haptics.selection()
                        withAnimation(.springy) { selected = item }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: icon).font(.caption)
                            Text(text).font(.system(.subheadline, design: .serif))
                        }
                        .foregroundStyle(isSelected ? .white : Theme.sumi)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(isSelected ? Theme.ai : Theme.kinari.opacity(0.4))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Theme.inkLine, lineWidth: isSelected ? 0 : 0.5))
                    }
                }
            }
        }
    }
}

// MARK: — Step 3: Confirmación (Pergamino)

struct ConfirmStep: View {
    let score: Int
    let energy: Double
    let context: MoodContext
    let company: MoodCompany
    let activity: MoodActivity
    let saved: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                HankoStamp(kanji: "認", color: Theme.aka, size: 100) // "Aprobado/Confirmado"
                    .scaleEffect(saved ? 1.2 : 1)
                    .opacity(saved ? 0.2 : 0.8)
                
                if saved {
                    FloatingSparkles()
                        .frame(width: 150, height: 150)
                }
            }

            VStack(spacing: 12) {
                Text(saved ? "Registrado" : "Revisión")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(Theme.sumi)
                
                Text("Tu estado se guardará en tu bitácora personal")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(Theme.sumiSoft)
            }

            VStack(spacing: 16) {
                ConfirmRowZen(icon: "face.smiling", title: "Ánimo", value: score.moodLabel)
                ConfirmRowZen(icon: "bolt", title: "Energía", value: "\(Int(energy * 100))%")
                ConfirmRowZen(icon: context.icon, title: "Lugar", value: context.rawValue)
                ConfirmRowZen(icon: company.icon, title: "Compañía", value: company.rawValue)
            }
            .cardStyle()
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

struct ConfirmRowZen: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.sumiSoft).frame(width: 20)
            Text(title).font(.system(.caption, design: .serif)).foregroundStyle(Theme.sumiSoft)
            Spacer()
            Text(value).font(.system(.subheadline, design: .serif).weight(.semibold)).foregroundStyle(Theme.sumi)
        }
    }
}
