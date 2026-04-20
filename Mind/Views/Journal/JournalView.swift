import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]

    @State private var text = ""
    @State private var showSummaryPrompt = false
    @State private var aiSummary: String? = nil
    @State private var isSummarizing = false
    @State private var wordCount = 0
    @State private var editorAppeared = false
    @FocusState private var isEditing: Bool

    private var todayScore: Int? {
        moodEntries.first { Calendar.current.isDateInToday($0.date) }?.score
    }

    private var prompt: String {
        if let s = todayScore { return JournalPrompt.promptForMood(score: s) }
        return JournalPrompt.deepestThoughts.text
    }

    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Theme.ambientBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {

                        // Prompt card animada
                        PromptCard(prompt: prompt, moodScore: todayScore)
                            .staggered(0, base: 0)

                        // Writing area
                        VStack(alignment: .leading, spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                if text.isEmpty && !isEditing {
                                    Text("Escribe libremente, sin censura…\n\nNo hay respuestas correctas o incorrectas.")
                                        .font(.body)
                                        .foregroundStyle(Color(.tertiaryLabel))
                                        .padding(16)
                                        .onTapGesture { isEditing = true }
                                }
                                TextEditor(text: $text)
                                    .font(.body)
                                    .lineSpacing(6)
                                    .frame(minHeight: 280)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .focused($isEditing)
                                    .onChange(of: text) { _, new in
                                        wordCount = new.split(separator: " ").filter { !$0.isEmpty }.count
                                    }
                            }

                            // Footer del editor
                            Divider()
                            HStack(spacing: 16) {
                                Label("Solo en tu iPhone", systemImage: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                Spacer()
                                // Word count con color según progreso
                                HStack(spacing: 4) {
                                    Text("\(wordCount)")
                                        .font(.caption.bold())
                                        .foregroundStyle(wordCountColor)
                                        .contentTransition(.numericText())
                                        .animation(.smooth, value: wordCount)
                                    Text("palabras")
                                        .font(.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                                // Mic button
                                Image(systemName: "mic.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Theme.accent)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .shadow(color: isEditing ? Theme.accent.opacity(0.12) : .black.opacity(0.05),
                                radius: isEditing ? 16 : 10, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardRadius)
                                .stroke(isEditing ? Theme.accent.opacity(0.3) : .clear, lineWidth: 1.5)
                        )
                        .animation(.smooth, value: isEditing)
                        .staggered(1, base: 0)

                        // Progress bar de escritura (meta: 100 palabras)
                        if wordCount > 0 {
                            WritingProgressBar(wordCount: wordCount, goal: 100)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .staggered(0, base: 0)
                        }

                        // AI Summary card
                        if let summary = aiSummary {
                            AISummaryCard(summary: summary)
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .animation(.springy, value: aiSummary != nil)
                    .animation(.springy, value: wordCount > 0)
                }

                // Guardar flotante
                if !isEmpty || isSummarizing {
                    VStack(spacing: 0) {
                        LinearGradient(colors: [Theme.background.opacity(0), Theme.background],
                                       startPoint: .top, endPoint: .bottom)
                        .frame(height: 32)

                        Button {
                            Haptics.impact(.medium)
                            save()
                        } label: {
                            Group {
                                if isSummarizing {
                                    HStack(spacing: 10) {
                                        ProgressView().tint(.white).scaleEffect(0.8)
                                        Text("Generando resumen on-device…")
                                    }
                                } else {
                                    Text("Guardar entrada")
                                }
                            }
                            .primaryButton()
                        }
                        .pressEffect()
                        .disabled(isSummarizing || isEmpty)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .background(.ultraThinMaterial)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.springy, value: isEmpty)
            .navigationTitle("Diario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { isEditing = false }
                }
            }
            .confirmationDialog("¿Resumen on-device?", isPresented: $showSummaryPrompt, titleVisibility: .visible) {
                Button("Sí, resumir en mi iPhone") { summarize() }
                Button("No, guardar sin resumen", role: .cancel) { dismiss() }
            } message: {
                Text("El resumen se genera aquí. Nunca sale del dispositivo.")
            }
        }
    }

    private var wordCountColor: Color {
        if wordCount < 30 { return Theme.secondaryText }
        if wordCount < 100 { return Theme.moodYellow }
        return Theme.moodGreen
    }

    private func save() {
        let entry = JournalEntry(prompt: prompt, body: text)
        context.insert(entry)
        showSummaryPrompt = true
    }

    private func summarize() {
        isSummarizing = true
        Task {
            let service = LLMService()
            let summary = await service.summarizeJournal(text)
            await MainActor.run {
                withAnimation(.springy) { aiSummary = summary }
                isSummarizing = false
            }
        }
    }
}

// MARK: — Prompt card dinámica

struct PromptCard: View {
    let prompt: String
    let moodScore: Int?
    @State private var appeared = false

    private var accentColor: Color {
        guard let s = moodScore else { return Theme.moodYellow }
        return s.moodColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "quote.opening")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accentColor)
            }
            .scaleEffect(appeared ? 1 : 0.4)
            .animation(.bouncy.delay(0.1), value: appeared)

            VStack(alignment: .leading, spacing: 5) {
                Text("Prompt de hoy")
                    .font(.caption.bold())
                    .foregroundStyle(accentColor)
                Text(prompt)
                    .font(.subheadline.italic())
                    .foregroundStyle(Theme.textPrimary.opacity(0.85))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(.springy.delay(0.12), value: appeared)
        }
        .padding(16)
        .background(accentColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: — Writing progress bar

struct WritingProgressBar: View {
    let wordCount: Int
    let goal: Int
    @State private var progress: Double = 0

    private var clampedProgress: Double { min(Double(wordCount) / Double(goal), 1.0) }
    private var color: Color {
        if clampedProgress < 0.3 { return Theme.secondaryText }
        if clampedProgress < 0.7 { return Theme.moodYellow }
        return Theme.moodGreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(progressLabel)
                    .font(.caption)
                    .foregroundStyle(color)
                    .animation(.smooth, value: wordCount)
                Spacer()
                Text("\(min(wordCount, goal)) / \(goal) palabras")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surface).frame(height: 6)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(duration: 0.6, bounce: 0.2), value: progress)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation { progress = clampedProgress }
        }
        .onChange(of: wordCount) { _, _ in
            withAnimation(.smooth) { progress = clampedProgress }
        }
    }

    private var progressLabel: String {
        if clampedProgress >= 1 { return "¡Excelente entrada! 🎉" }
        if clampedProgress >= 0.5 { return "Sigue, vas muy bien" }
        return "Meta: \(goal) palabras"
    }

}

// MARK: — AI Summary card

struct AISummaryCard: View {
    let summary: String
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "brain")
                        .foregroundStyle(Theme.moodPurple)
                        .symbolEffect(.pulse)
                    Text("Resumen on-device · solo para ti")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.moodPurple)
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(5)
                .opacity(appeared ? 1 : 0)
                .animation(.smooth.delay(0.1), value: appeared)
        }
        .padding(16)
        .background(Theme.moodPurple.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.moodPurple.opacity(0.2), lineWidth: 1))
        .onAppear { withAnimation { appeared = true } }
    }
}
