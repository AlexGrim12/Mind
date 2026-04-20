import SwiftUI

// MARK: — Data

enum QuestionnaireType: String, CaseIterable {
    case phq9 = "PHQ-9"
    case gad7 = "GAD-7"

    var title: String {
        switch self {
        case .phq9: return "Depresión"
        case .gad7: return "Ansiedad"
        }
    }

    var color: Color {
        switch self {
        case .phq9: return Theme.moodBlue
        case .gad7: return Theme.moodPurple
        }
    }

    var icon: String {
        switch self {
        case .phq9: return "cloud.drizzle.fill"
        case .gad7: return "waveform.path.ecg"
        }
    }

    var questions: [String] {
        switch self {
        case .phq9:
            return [
                "Poco interés o placer en hacer cosas",
                "Sentirse triste, deprimido/a o sin esperanza",
                "Problemas para dormir, mantenerse despierto/a o dormir demasiado",
                "Sentirse cansado/a o con poca energía",
                "Poco apetito o comer en exceso",
                "Sentirse mal contigo mismo/a",
                "Dificultad para concentrarte",
                "Moverte o hablar tan lento que otros lo notan, o estar tan agitado/a que no puedes quedarte quieto/a",
                "Pensamientos de que estarías mejor muerto/a o de hacerte daño"
            ]
        case .gad7:
            return [
                "Sentirte nervioso/a, ansioso/a o muy tenso/a",
                "No poder dejar de preocuparte o no poder controlar tu preocupación",
                "Preocuparte demasiado por muchas cosas diferentes",
                "Dificultad para relajarte",
                "Estar tan inquieto/a que es difícil quedarse quieto/a",
                "Irritarte o enojarte fácilmente",
                "Sentir miedo de que algo terrible puede pasar"
            ]
        }
    }

    var options: [String] { ["Nunca", "Varios días", "Más de la mitad", "Casi todos los días"] }

    func interpret(score: Int) -> (label: String, color: Color, description: String) {
        switch self {
        case .phq9:
            switch score {
            case 0...4:  return ("Mínimo", Theme.moodGreen, "Sin depresión significativa.")
            case 5...9:  return ("Leve", Theme.moodYellow, "Síntomas leves de depresión.")
            case 10...14: return ("Moderado", Color.orange, "Depresión moderada. Considera hablar con tu psicólogo.")
            case 15...19: return ("Moderado-severo", Color.orange, "Depresión moderada-severa. Se recomienda apoyo profesional.")
            default:     return ("Severo", Color.red, "Depresión severa. Por favor habla con un profesional pronto.")
            }
        case .gad7:
            switch score {
            case 0...4:  return ("Mínima", Theme.moodGreen, "Ansiedad dentro de rangos normales.")
            case 5...9:  return ("Leve", Theme.moodYellow, "Ansiedad leve.")
            case 10...14: return ("Moderada", Color.orange, "Ansiedad moderada. Útil hablar con tu psicólogo.")
            default:     return ("Severa", Color.red, "Ansiedad severa. Se recomienda apoyo profesional pronto.")
            }
        }
    }

    var maxScore: Int { questions.count * 3 }
}

// MARK: — Main View

struct QuestionnaireView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("sharesQuestionnaires") private var sharesQuestionnaires = true

    @State private var selectedType: QuestionnaireType = .phq9
    @State private var answers: [Int] = Array(repeating: -1, count: 9)
    @State private var currentQ = 0
    @State private var phase: Phase = .picker
    @State private var showResult = false
    @State private var resultScore = 0
    @State private var appeared = false

    enum Phase { case picker, questions, result }

    private var questions: [String] { selectedType.questions }
    private var totalScore: Int { answers.filter { $0 >= 0 }.reduce(0, +) }
    private var progress: Double { Double(currentQ) / Double(questions.count) }
    private var allAnswered: Bool { answers.prefix(questions.count).allSatisfy { $0 >= 0 } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                switch phase {
                case .picker:   pickerPhase
                case .questions: questionPhase
                case .result:   resultPhase
                }
            }
            .navigationTitle(phase == .picker ? "Cuestionarios" : selectedType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                if phase == .questions {
                    ToolbarItem(placement: .principal) {
                        ProgressCapsule(progress: progress, color: selectedType.color)
                    }
                }
            }
        }
    }

    // MARK: Picker

    private var pickerPhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("¿Cómo te has sentido\nesta semana?")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Cuestionarios validados clínicamente")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.springy.delay(0.05), value: appeared)

                VStack(spacing: 16) {
                    ForEach(Array(QuestionnaireType.allCases.enumerated()), id: \.offset) { i, type in
                        QuestionnairePickerCard(type: type) {
                            Haptics.impact(.medium)
                            selectedType = type
                            answers = Array(repeating: -1, count: type.questions.count)
                            currentQ = 0
                            withAnimation(.springy) { phase = .questions }
                        }
                        .staggered(i, base: 0.1)
                    }
                }

                // Last results placeholder
                VStack(alignment: .leading, spacing: 14) {
                    Text("Últimos resultados").font(.headline)
                    HStack(spacing: 12) {
                        LastResultPill(type: .phq9, score: 8, date: "Hace 7 días")
                        LastResultPill(type: .gad7, score: 11, date: "Hace 7 días")
                    }
                }
                .staggered(2, base: 0.1)
                .padding(.top, 4)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .onAppear { withAnimation { appeared = true } }
    }

    // MARK: Questions

    private var questionPhase: some View {
        VStack(spacing: 0) {
            // Question counter
            HStack {
                Text("\(currentQ + 1) de \(questions.count)")
                    .font(.caption.bold())
                    .foregroundStyle(selectedType.color)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            // Question card
            TabView(selection: $currentQ) {
                ForEach(Array(questions.enumerated()), id: \.offset) { i, q in
                    QuestionCard(
                        question: q,
                        options: selectedType.options,
                        accentColor: selectedType.color,
                        selected: answers.indices.contains(i) ? answers[i] : -1
                    ) { value in
                        Haptics.selection()
                        if answers.indices.contains(i) { answers[i] = value }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(.springy) {
                                if i < questions.count - 1 {
                                    currentQ = i + 1
                                } else {
                                    resultScore = totalScore
                                    phase = .result
                                }
                            }
                        }
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.springy, value: currentQ)
        }
    }

    // MARK: Result

    private var resultPhase: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                ResultHero(type: selectedType, score: resultScore)
                    .padding(.top, 16)

                InterpretationCard(type: selectedType, score: resultScore)

                if selectedType == .phq9 && resultScore >= 10 {
                    CrisisNoteCard()
                }

                // Share toggle
                HStack(spacing: 14) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(Theme.moodGreen)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Compartir con mi psicólogo").font(.subheadline.bold())
                        Text("Solo el puntaje, no las respuestas").font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    Toggle("", isOn: $sharesQuestionnaires).tint(Theme.moodGreen).labelsHidden()
                }
                .cardStyle()

                VStack(spacing: 12) {
                    Button {
                        Haptics.impact(.medium)
                        selectedType = selectedType == .phq9 ? .gad7 : .phq9
                        answers = Array(repeating: -1, count: selectedType.questions.count)
                        currentQ = 0
                        withAnimation(.springy) { phase = .questions }
                    } label: {
                        Label("Hacer \(selectedType == .phq9 ? "GAD-7" : "PHQ-9") también",
                              systemImage: "arrow.right.circle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedType.color.opacity(0.1))
                            .foregroundStyle(selectedType.color)
                            .font(.subheadline.bold())
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }
                    .pressEffect()

                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Text("Listo")
                            .primaryButton()
                    }
                    .pressEffect()
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: — Sub-components

struct ProgressCapsule: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface).frame(height: 6)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * progress, height: 6)
                    .animation(.spring(duration: 0.5), value: progress)
            }
        }
        .frame(width: 120, height: 6)
    }
}

struct QuestionnairePickerCard: View {
    let type: QuestionnaireType
    let onTap: () -> Void
    @State private var appeared = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(type.color.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: type.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(type.color)
                        .symbolEffect(.pulse)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(type.rawValue).font(.headline).foregroundStyle(Theme.textPrimary)
                        Text(type.title)
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(type.color.opacity(0.1))
                            .foregroundStyle(type.color)
                            .clipShape(Capsule())
                    }
                    Text("\(type.questions.count) preguntas · ~2 min")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(18)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 3)
        }
        .buttonStyle(.plain)
        .pressEffect()
    }
}

struct LastResultPill: View {
    let type: QuestionnaireType
    let score: Int
    let date: String
    private var interpretation: (label: String, color: Color, description: String) { type.interpret(score: score) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(type.rawValue).font(.caption.bold()).foregroundStyle(Theme.secondaryText)
                Spacer()
                Text(date).font(.caption2).foregroundStyle(Theme.secondaryText)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(score)").font(.title2.bold()).foregroundStyle(interpretation.color)
                Text("/ \(type.maxScore)").font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Text(interpretation.label)
                .font(.caption.bold())
                .foregroundStyle(interpretation.color)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(type.color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(type.color.opacity(0.2), lineWidth: 1))
    }
}

struct QuestionCard: View {
    let question: String
    let options: [String]
    let accentColor: Color
    let selected: Int
    let onSelect: (Int) -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(question)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)
                .padding(.horizontal, 8)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.springy.delay(0.05), value: appeared)

            Text("En los últimos 14 días…")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
                .opacity(appeared ? 1 : 0)
                .animation(.springy.delay(0.1), value: appeared)

            Spacer()

            VStack(spacing: 10) {
                ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                    OptionRow(label: option, value: i, accentColor: accentColor,
                              selected: selected == i, delay: Double(i) * 0.06) {
                        onSelect(i)
                    }
                }
            }
            .padding(.horizontal, 4)

            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            appeared = false
            withAnimation { appeared = true }
        }
    }
}

struct OptionRow: View {
    let label: String
    let value: Int
    let accentColor: Color
    let selected: Bool
    let delay: Double
    let onTap: () -> Void
    @State private var appeared = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(selected ? accentColor : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if selected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 14, height: 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.springy, value: selected)

                Text(label)
                    .font(.subheadline.bold())
                    .foregroundStyle(selected ? accentColor : Theme.textPrimary)
                    .animation(.smooth, value: selected)

                Spacer()

                Text("\(value)")
                    .font(.caption.bold())
                    .foregroundStyle(selected ? accentColor : Theme.secondaryText)
                    .animation(.smooth, value: selected)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(selected ? accentColor.opacity(0.08) : Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
            .animation(.springy, value: selected)
            .shadow(color: selected ? accentColor.opacity(0.15) : .black.opacity(0.04),
                    radius: selected ? 10 : 6, y: 2)
            .animation(.smooth, value: selected)
        }
        .buttonStyle(.plain)
        .pressEffect()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.springy.delay(delay)) { appeared = true }
        }
    }
}

struct ResultHero: View {
    let type: QuestionnaireType
    let score: Int
    @State private var ringProgress: Double = 0
    @State private var appeared = false

    private var interpretation: (label: String, color: Color, description: String) { type.interpret(score: score) }
    private var fraction: Double { Double(score) / Double(type.maxScore) }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(interpretation.color.opacity(0.1), lineWidth: 16)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(colors: [interpretation.color, interpretation.color.opacity(0.6)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1.2, bounce: 0.2), value: ringProgress)

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(interpretation.color)
                        .contentTransition(.numericText())
                    Text("/ \(type.maxScore)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .animation(.bouncy.delay(0.1), value: appeared)

            VStack(spacing: 6) {
                Text(type.rawValue + " · " + interpretation.label)
                    .font(.title3.bold())
                    .foregroundStyle(interpretation.color)
                Text(type.title)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.springy.delay(0.2), value: appeared)
        }
        .onAppear {
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                ringProgress = fraction
            }
        }
    }
}

struct InterpretationCard: View {
    let type: QuestionnaireType
    let score: Int
    private var interpretation: (label: String, color: Color, description: String) { type.interpret(score: score) }

    private var ranges: [(label: String, range: String, color: Color)] {
        switch type {
        case .phq9: return [
            ("Mínimo", "0–4", Theme.moodGreen),
            ("Leve", "5–9", Theme.moodYellow),
            ("Moderado", "10–14", .orange),
            ("Mod-severo", "15–19", .orange),
            ("Severo", "20–27", .red),
        ]
        case .gad7: return [
            ("Mínima", "0–4", Theme.moodGreen),
            ("Leve", "5–9", Theme.moodYellow),
            ("Moderada", "10–14", .orange),
            ("Severa", "15–21", .red),
        ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Interpretación")
                .font(.headline)

            Text(interpretation.description)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)

            Divider()

            HStack(spacing: 8) {
                ForEach(ranges, id: \.label) { r in
                    VStack(spacing: 4) {
                        Text(r.range)
                            .font(.caption2.bold())
                            .foregroundStyle(r.color)
                        Text(r.label)
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(r.color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(score >= (rangeStart(r.range)) && score <= (rangeEnd(r.range))
                                    ? r.color.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                }
            }
        }
        .cardStyle()
    }

    private func rangeStart(_ r: String) -> Int { Int(r.split(separator: "–").first ?? "0") ?? 0 }
    private func rangeEnd(_ r: String) -> Int { Int(r.split(separator: "–").last ?? "0") ?? 0 }
}

struct CrisisNoteCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tu bienestar importa")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                Text("Tu puntaje indica síntomas importantes. Considera hablar con tu psicólogo o llamar a una línea de crisis.")
                    .font(.caption)
                    .foregroundStyle(Theme.textPrimary)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.25), lineWidth: 1))
    }
}
