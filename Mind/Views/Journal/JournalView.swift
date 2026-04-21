import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import AVFoundation

// MARK: — 📜 JournalView · listado + editor + detalle (estilo pergamino japonés)

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moodEntries: [MoodEntry]

    @State private var showEditor = false
    @State private var selectedEntry: JournalEntry? = nil

    private var todayScore: Int? {
        moodEntries.first { Calendar.current.isDateInToday($0.date) }?.score
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    JournalHeader(count: entries.count)
                        .staggered(0, base: 0)

                    // Botón grande "nueva entrada"
                    Button {
                        Haptics.impact(.light)
                        showEditor = true
                    } label: {
                        NewEntryBanner(todayScore: todayScore)
                    }
                    .buttonStyle(.plain)
                    .pressEffect()
                    .staggered(1, base: 0)

                    if entries.isEmpty {
                        JournalEmptyState()
                            .staggered(2, base: 0)
                    } else {
                        Text("Pergaminos guardados")
                            .font(.system(.headline, design: .serif).weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.top, 8)
                            .staggered(2, base: 0)

                        LazyVStack(spacing: 14) {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                                Button {
                                    Haptics.selection()
                                    selectedEntry = entry
                                } label: {
                                    JournalRowCard(entry: entry)
                                }
                                .buttonStyle(.plain)
                                .pressEffect()
                                .staggered(min(idx + 3, 9), base: 0)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(entry)
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .screenBackground()
            .navigationTitle("Diario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(Theme.sumi)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.impact(.light)
                        showEditor = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            JournalEditorView(todayScore: todayScore)
        }
        .sheet(item: $selectedEntry) { entry in
            JournalEntryDetailView(entry: entry)
        }
        .onAppear {
            JournalMediaStore.bootstrap()
        }
    }

    private func delete(_ entry: JournalEntry) {
        JournalMediaStore.deleteAllMedia(audio: entry.audioFileName, images: entry.imageFileNames ?? [])
        context.delete(entry)
    }
}

// MARK: — Encabezado con contador

private struct JournalHeader: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("日記")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.sakuraDeep)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Diario")
                        .font(.system(.title2, design: .serif).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Todo se guarda en tu teléfono, solo para ti")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(count)")
                        .font(.system(.title3, design: .serif).weight(.bold))
                        .foregroundStyle(Theme.matchaDeep)
                    Text(count == 1 ? "entrada" : "entradas")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            InkBrushDivider().frame(height: 8)
        }
    }
}

// MARK: — Banner "nueva entrada"

private struct NewEntryBanner: View {
    let todayScore: Int?

    private var promptText: String {
        if let s = todayScore { return JournalPrompt.promptForMood(score: s) }
        return JournalPrompt.deepestThoughts.text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.sakura.opacity(0.35))
                    .frame(width: 56, height: 56)
                Circle()
                    .stroke(Theme.sakuraDeep.opacity(0.3), lineWidth: 0.8)
                    .frame(width: 56, height: 56)
                Image(systemName: "scroll.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.sakuraDeep)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Escribir nueva entrada")
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("新")
                        .font(.system(.caption2, design: .serif))
                        .foregroundStyle(Theme.sakuraDeep)
                }
                Text(promptText)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    FeatureChip(icon: "text.alignleft", label: "Texto")
                    FeatureChip(icon: "mic.fill", label: "Voz")
                    FeatureChip(icon: "photo.fill", label: "Fotos")
                }
                .padding(.top, 2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.sakuraDeep)
                .font(.subheadline.bold())
        }
        .cardStyle()
    }
}

private struct FeatureChip: View {
    let icon: String
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.system(.caption2, design: .rounded).weight(.semibold))
        }
        .foregroundStyle(Theme.matchaDeep)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.matcha.opacity(0.18), in: Capsule())
        .overlay(Capsule().stroke(Theme.matchaDeep.opacity(0.25), lineWidth: 0.5))
    }
}

// MARK: — Tarjeta de fila (lista)

private struct JournalRowCard: View {
    let entry: JournalEntry

    private var accentColor: Color {
        switch entry.aiMood {
        case .some(let m) where m.contains("alegr") || m.contains("grat"): return Theme.tamago
        case .some(let m) where m.contains("calm") || m.contains("esper"): return Theme.matchaDeep
        case .some(let m) where m.contains("triste") || m.contains("cansan"): return Theme.asagi
        case .some(let m) where m.contains("rab") || m.contains("ansied"): return Theme.sango
        default: return Theme.sakuraDeep
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Bloque fecha/kanji
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: entry.date))")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(accentColor)
                Text(entry.monthKanji)
                    .font(.system(.caption2, design: .serif))
                    .foregroundStyle(Theme.sumiSoft)
            }
            .frame(width: 56)
            .padding(.vertical, 10)
            .background(Theme.kinari.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.inkLine, lineWidth: 0.5)
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(entry.shortDate)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(Theme.sumiSoft)
                    Spacer()
                    if entry.audioFileName != nil {
                        Image(systemName: "waveform")
                            .font(.caption2)
                            .foregroundStyle(Theme.accentPurple)
                    }
                    if !(entry.imageFileNames ?? []).isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "photo.fill")
                                .font(.caption2)
                            Text("\(entry.imageFileNames?.count ?? 0)")
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                        }
                        .foregroundStyle(Theme.matchaDeep)
                    }
                }

                Text(entry.preview)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                if let mood = entry.aiMood, !mood.isEmpty {
                    Text(mood.capitalized)
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(accentColor.opacity(0.14), in: Capsule())
                        .overlay(Capsule().stroke(accentColor.opacity(0.3), lineWidth: 0.5))
                }
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 14)
    }
}

// MARK: — Estado vacío

private struct JournalEmptyState: View {
    var body: some View {
        VStack(spacing: 14) {
            SakuraBlossom(tint: Theme.sakura, core: Theme.sakuraDeep, size: 50)
                .padding(.top, 20)
            Text("Aún no has escrito en tu pergamino")
                .font(.system(.headline, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Escribe, graba tu voz o guarda una imagen.\nTodo queda en tu teléfono, solo para ti.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 20)
    }
}

// MARK: — ✍️ EDITOR

struct JournalEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let todayScore: Int?

    @State private var text = ""
    @State private var wordCount = 0
    @FocusState private var isEditing: Bool

    @State private var recorder = AudioJournalRecorder()

    @State private var photoItems: [PhotosPickerItem] = []
    @State private var loadedImages: [(fileName: String, image: UIImage)] = []

    @State private var isSaving = false

    private var prompt: String {
        if let s = todayScore { return JournalPrompt.promptForMood(score: s) }
        return JournalPrompt.deepestThoughts.text
    }

    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && recorder.audioFileName == nil
        && loadedImages.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    PromptCard(prompt: prompt, moodScore: todayScore)

                    // Editor de texto estilo pergamino
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            if text.isEmpty && !isEditing {
                                Text("Escribe libremente, sin censura…")
                                    .font(.system(.body, design: .serif))
                                    .foregroundStyle(Theme.sumiSoft.opacity(0.6))
                                    .padding(16)
                                    .onTapGesture { isEditing = true }
                            }
                            TextEditor(text: $text)
                                .font(.system(.body, design: .serif))
                                .lineSpacing(6)
                                .frame(minHeight: 200)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .focused($isEditing)
                                .onChange(of: text) { _, new in
                                    wordCount = new.split(separator: " ").filter { !$0.isEmpty }.count
                                }
                        }
                        Divider().background(Theme.inkLine)
                        HStack {
                            Label("Privado · on-device", systemImage: "lock.fill")
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                .foregroundStyle(Theme.sumiSoft)
                            Spacer()
                            Text("\(wordCount) palabras")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(Theme.sumiSoft)
                        }
                        .padding(12)
                    }
                    .background(Theme.cardBackground.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .stroke(Theme.inkLine, lineWidth: 0.6)
                    )

                    // Notas de voz
                    AudioRecordSection(recorder: recorder)

                    // Imágenes adjuntas
                    PhotoAttachmentsSection(
                        photoItems: $photoItems,
                        loadedImages: $loadedImages
                    )

                    Spacer(minLength: 140)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .screenBackground()
            .navigationTitle("Nueva entrada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        recorder.cancel()
                        cleanupUnsavedMedia()
                        dismiss()
                    }
                    .foregroundStyle(Theme.sumiSoft)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !isEmpty || isSaving {
                    Button {
                        Haptics.impact(.medium)
                        Task { await save() }
                    } label: {
                        Group {
                            if isSaving {
                                HStack(spacing: 8) {
                                    ProgressView().tint(.white)
                                    Text("Guardando…")
                                }
                            } else {
                                Label("Guardar en el pergamino", systemImage: "checkmark.seal.fill")
                            }
                        }
                        .primaryButton()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.springy, value: isEmpty)
            .animation(.springy, value: isSaving)
        }
    }

    // MARK: Guardado

    @MainActor
    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let entry = JournalEntry(prompt: prompt, body: text)

        // Audio
        if let audioName = recorder.audioFileName {
            entry.audioFileName = audioName
            entry.audioTranscript = recorder.transcript
            entry.audioDuration = recorder.elapsed > 0 ? recorder.elapsed : nil
        }

        // Imágenes
        entry.imageFileNames = loadedImages.map { $0.fileName }

        // Resumen IA
        let textForAI = entry.combinedText
        if !textForAI.isEmpty {
            let digest = await LLMService().digestJournal(textForAI)
            entry.aiSummary = digest.summary
            entry.aiMood = digest.mood
            entry.sharedTopics = digest.topics
            entry.aiSummaryDate = Date()
        }

        context.insert(entry)
        try? context.save()

        Haptics.success()
        dismiss()
    }

    private func cleanupUnsavedMedia() {
        // Solo limpiar imágenes cargadas a disco; el audio ya lo maneja recorder.cancel()
        for img in loadedImages {
            JournalMediaStore.deleteImage(fileName: img.fileName)
        }
        loadedImages.removeAll()
    }
}

// MARK: — Prompt card (sin cambios funcionales, re-diseñada)

struct PromptCard: View {
    let prompt: String
    let moodScore: Int?

    private var accentColor: Color {
        guard let s = moodScore else { return Theme.sakuraDeep }
        return s.moodColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: "quote.opening")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Prompt de hoy")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(accentColor)
                Text(prompt)
                    .font(.system(.subheadline, design: .serif).italic())
                    .foregroundStyle(Theme.textPrimary.opacity(0.85))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.22), lineWidth: 1)
        )
    }
}

// MARK: — Sección de grabación de audio

private struct AudioRecordSection: View {
    var recorder: AudioJournalRecorder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.circle.fill")
                    .foregroundStyle(Theme.accentPurple)
                Text("Nota de voz")
                    .font(.system(.headline, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("声")
                    .font(.system(.caption2, design: .serif))
                    .foregroundStyle(Theme.accentPurple)
                Spacer()
                if recorder.audioFileName != nil && recorder.state != .recording {
                    Button {
                        Haptics.selection()
                        recorder.cancel()
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.sumiSoft)
                    }
                    .buttonStyle(.plain)
                }
            }

            switch recorder.state {
            case .idle, .requestingPermission:
                RecordButton(isRecording: false) {
                    Haptics.impact(.medium)
                    Task { await recorder.startRecording() }
                }
                Text("Toca y habla · se transcribe en tu dispositivo")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)

            case .recording:
                VStack(spacing: 10) {
                    LiveWaveform(level: recorder.level)
                        .frame(height: 52)
                    HStack {
                        Circle().fill(Theme.aka).frame(width: 8, height: 8)
                            .opacity(0.9)
                        Text("Grabando · \(recorder.formattedElapsed())")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.aka)
                        Spacer()
                    }
                    RecordButton(isRecording: true) {
                        Haptics.impact(.medium)
                        Task { await recorder.stopRecording() }
                    }
                }

            case .transcribing:
                HStack(spacing: 10) {
                    ProgressView().tint(Theme.accentPurple)
                    Text("Transcribiendo con Apple Speech…")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.vertical, 8)

            case .ready:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.matchaDeep)
                        Text("Audio guardado · \(recorder.formattedElapsed())")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.matchaDeep)
                    }
                    if !recorder.transcript.isEmpty {
                        Text(recorder.transcript)
                            .font(.system(.footnote, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.kinari.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                    } else {
                        Text("Sin transcripción. El audio se guardará igualmente.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }

            case .error(let msg):
                Label(msg, systemImage: "exclamationmark.triangle")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.sango)
                RecordButton(isRecording: false) {
                    Haptics.impact(.medium)
                    Task { await recorder.startRecording() }
                }
            }
        }
        .cardStyle()
    }
}

private struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Theme.aka : Theme.accentPurple)
                        .frame(width: 44, height: 44)
                        .shadow(color: (isRecording ? Theme.aka : Theme.accentPurple).opacity(0.35), radius: 8, y: 3)
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(isRecording ? "Detener grabación" : "Grabar nota de voz")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(10)
            .background(Theme.cardBackground.opacity(0.85), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.inkLine, lineWidth: 0.6)
            )
        }
        .buttonStyle(.plain)
        .pressEffect()
    }
}

private struct LiveWaveform: View {
    let level: Float
    @State private var bars: [Float] = Array(repeating: 0, count: 24)

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<bars.count, id: \.self) { i in
                Capsule()
                    .fill(Theme.accentPurple.opacity(0.85))
                    .frame(width: 3, height: CGFloat(max(0.1, bars[i])) * 52)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: level) { _, newLevel in
            bars.removeFirst()
            // Valor con un poco de variación para aspecto natural
            let variance = Float.random(in: 0.7...1.1)
            bars.append(min(1, newLevel * variance))
        }
    }
}

// MARK: — Sección de imágenes adjuntas

private struct PhotoAttachmentsSection: View {
    @Binding var photoItems: [PhotosPickerItem]
    @Binding var loadedImages: [(fileName: String, image: UIImage)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "photo.stack.fill")
                    .foregroundStyle(Theme.matchaDeep)
                Text("Imágenes")
                    .font(.system(.headline, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("写真")
                    .font(.system(.caption2, design: .serif))
                    .foregroundStyle(Theme.matchaDeep)
                Spacer()
                Text("\(loadedImages.count)/4")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.secondaryText)
            }

            if !loadedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(loadedImages, id: \.fileName) { item in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: item.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Theme.inkLine, lineWidth: 0.6)
                                    )
                                Button {
                                    Haptics.selection()
                                    JournalMediaStore.deleteImage(fileName: item.fileName)
                                    loadedImages.removeAll { $0.fileName == item.fileName }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.white, Theme.sumi.opacity(0.75))
                                }
                                .buttonStyle(.plain)
                                .padding(6)
                            }
                        }
                    }
                }
            }

            PhotosPicker(
                selection: $photoItems,
                maxSelectionCount: 4,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.matchaDeep)
                        .font(.title3)
                    Text(loadedImages.isEmpty ? "Añadir imágenes" : "Añadir más")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
                .padding(10)
                .background(Theme.matcha.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.matchaDeep.opacity(0.25), lineWidth: 0.6)
                )
            }
            .onChange(of: photoItems) { _, newItems in
                Task { await loadPickedPhotos(newItems) }
            }
        }
        .cardStyle()
    }

    private func loadPickedPhotos(_ items: [PhotosPickerItem]) async {
        var results: [(String, UIImage)] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data),
               let fileName = JournalMediaStore.saveImage(img) {
                results.append((fileName, img))
            }
        }
        await MainActor.run {
            // Añadir lo nuevo manteniendo lo viejo, hasta 4
            var combined = loadedImages + results.map { (fileName: $0.0, image: $0.1) }
            if combined.count > 4 {
                let toDrop = combined.suffix(combined.count - 4)
                for d in toDrop {
                    JournalMediaStore.deleteImage(fileName: d.fileName)
                }
                combined = Array(combined.prefix(4))
            }
            loadedImages = combined
            photoItems = []
        }
    }
}

// MARK: — 👁️ Vista detalle de una entrada guardada

struct JournalEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let entry: JournalEntry

    @State private var player = AudioJournalPlayer()
    @State private var isRegenerating = false

    private var accentColor: Color {
        switch entry.aiMood {
        case .some(let m) where m.contains("alegr") || m.contains("grat"): return Theme.tamago
        case .some(let m) where m.contains("calm") || m.contains("esper"): return Theme.matchaDeep
        case .some(let m) where m.contains("triste") || m.contains("cansan"): return Theme.asagi
        case .some(let m) where m.contains("rab") || m.contains("ansied"): return Theme.sango
        default: return Theme.sakuraDeep
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Cabecera con fecha y mood
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(entry.monthKanji)
                                .font(.system(.title3, design: .serif).weight(.bold))
                                .foregroundStyle(accentColor)
                            Text(entry.date.formatted(date: .complete, time: .shortened))
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        if let mood = entry.aiMood {
                            Text(mood.capitalized)
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(accentColor.opacity(0.14), in: Capsule())
                                .overlay(Capsule().stroke(accentColor.opacity(0.3), lineWidth: 0.5))
                        }
                        InkBrushDivider().frame(height: 8)
                    }

                    // Prompt
                    if !entry.prompt.isEmpty {
                        PromptCard(prompt: entry.prompt, moodScore: nil)
                    }

                    // Cuerpo del texto
                    if !entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Text("Texto")
                                    .kanjiBadge()
                                Spacer()
                            }
                            Text(entry.body)
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Theme.textPrimary)
                                .lineSpacing(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .cardStyle()
                    }

                    // Audio
                    if let fileName = entry.audioFileName {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Text("Voz · 声").kanjiBadge()
                                Spacer()
                                if let d = entry.audioDuration {
                                    Text(formatSeconds(d))
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                        .foregroundStyle(Theme.secondaryText)
                                }
                            }

                            Button {
                                Haptics.selection()
                                if player.isPlaying {
                                    player.stop()
                                } else {
                                    player.play(url: JournalMediaStore.audioURL(for: fileName))
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Theme.accentPurple)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                            .foregroundStyle(.white)
                                    }
                                    WaveformStatic()
                                        .foregroundStyle(Theme.accentPurple.opacity(0.85))
                                        .frame(height: 32)
                                    ProgressView(value: player.progress)
                                        .frame(width: 60)
                                        .tint(Theme.accentPurple)
                                }
                            }
                            .buttonStyle(.plain)

                            if let transcript = entry.audioTranscript, !transcript.isEmpty {
                                Text(transcript)
                                    .font(.system(.footnote, design: .serif))
                                    .foregroundStyle(Theme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Theme.kinari.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .cardStyle()
                    }

                    // Imágenes
                    if !(entry.imageFileNames ?? []).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Text("Imágenes · 写真").kanjiBadge()
                                Spacer()
                                Text("\(entry.imageFileNames?.count ?? 0)")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            let cols = [GridItem(.flexible()), GridItem(.flexible())]
                            LazyVGrid(columns: cols, spacing: 8) {
                                ForEach(entry.imageFileNames ?? [], id: \.self) { name in
                                    if let img = JournalMediaStore.loadImage(fileName: name) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 140)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(Theme.inkLine, lineWidth: 0.5)
                                            )
                                    }
                                }
                            }
                        }
                        .cardStyle()
                    }

                    // Resumen IA
                    AISummarySection(entry: entry, isRegenerating: $isRegenerating) {
                        await regenerate()
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 40)
            }
            .screenBackground()
            .navigationTitle("Entrada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Theme.sumi)
                }
            }
        }
        .onDisappear { player.stop() }
    }

    private func formatSeconds(_ s: Double) -> String {
        let total = Int(s)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    @MainActor
    private func regenerate() async {
        guard !isRegenerating else { return }
        isRegenerating = true
        defer { isRegenerating = false }
        let digest = await LLMService().digestJournal(entry.combinedText)
        entry.aiSummary = digest.summary
        entry.aiMood = digest.mood
        entry.sharedTopics = digest.topics
        entry.aiSummaryDate = Date()
        try? context.save()
        Haptics.success()
    }
}

// MARK: — Resumen IA dentro de la nota

struct AISummarySection: View {
    let entry: JournalEntry
    @Binding var isRegenerating: Bool
    let onRegenerate: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.accentPurple)
                    .symbolEffect(.pulse, options: .nonRepeating)
                Text("Reflexión · Apple Intelligence")
                    .font(.system(.headline, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }

            if let summary = entry.aiSummary, !summary.isEmpty {
                Text(summary)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let topics = entry.sharedTopics, !topics.isEmpty {
                    FlowRow(items: topics) { topic in
                        Text(topic)
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.accentPurple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accentPurple.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(Theme.accentPurple.opacity(0.3), lineWidth: 0.5))
                    }
                }

                if let date = entry.aiSummaryDate {
                    Text("Generado \(date.formatted(.relative(presentation: .named)))")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)
                }
            } else {
                Text("Aún no hay reflexión generada para esta entrada.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
            }

            Button {
                Haptics.selection()
                Task { await onRegenerate() }
            } label: {
                HStack(spacing: 6) {
                    if isRegenerating {
                        ProgressView().tint(Theme.accentPurple).scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(isRegenerating ? "Generando…" : (entry.aiSummary == nil ? "Generar reflexión" : "Regenerar"))
                }
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.accentPurple)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.accentPurple.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Theme.accentPurple.opacity(0.3), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .disabled(isRegenerating || !entry.hasContent)
        }
        .cardStyle()
    }
}

// MARK: — Flow layout simple para tags

struct FlowRow<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}

// MARK: — Waveform estático decorativo

private struct WaveformStatic: View {
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<28, id: \.self) { i in
                Capsule()
                    .frame(width: 2, height: barHeight(i))
            }
        }
    }

    private func barHeight(_ i: Int) -> CGFloat {
        // Pseudo-aleatorio estable con aspecto de onda
        let seed = sin(Double(i) * 0.9) * 0.5 + sin(Double(i) * 0.3) * 0.5
        return 6 + CGFloat(abs(seed)) * 22
    }
}
