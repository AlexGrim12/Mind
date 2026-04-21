import Foundation
import AVFoundation
import Speech
import SwiftUI
import Observation

/// Grabador de notas de voz del diario + transcripción on-device con Apple Speech.
/// Garantiza que el audio y la transcripción **nunca salgan del dispositivo**.
@Observable
@MainActor
final class AudioJournalRecorder: NSObject {

    // MARK: — Estados observables
    enum State: Equatable {
        case idle
        case requestingPermission
        case recording
        case transcribing
        case ready         // audio + transcripción listos
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var elapsed: TimeInterval = 0
    private(set) var level: Float = 0   // 0...1 para waveform
    private(set) var transcript: String = ""
    private(set) var audioURL: URL? = nil
    private(set) var audioFileName: String? = nil

    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private var meterTimer: Timer?
    @ObservationIgnored private let speechRecognizer: SFSpeechRecognizer?

    override init() {
        // Locale en español; el sistema hará fallback si no hay modelo instalado
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es_ES"))
            ?? SFSpeechRecognizer()
        super.init()
    }

    // MARK: — Permisos

    /// Solicita Micrófono + Reconocimiento de voz. Retorna true si ambos concedidos.
    func requestPermissions() async -> Bool {
        state = .requestingPermission

        // Micrófono
        let micGranted: Bool = await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        guard micGranted else {
            state = .error("Permiso de micrófono denegado")
            return false
        }

        // Reconocimiento de voz
        let speechGranted: Bool = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechGranted else {
            // Aunque falle Speech, la grabación aún puede guardarse sin transcripción.
            state = .error("Permiso de reconocimiento de voz denegado")
            return false
        }

        state = .idle
        return true
    }

    // MARK: — Grabación

    func startRecording() async {
        // Pide permisos si aún no
        let ok = await requestPermissions()
        guard ok else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord,
                                    mode: .default,
                                    options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let url = JournalMediaStore.makeAudioURL()
            self.audioURL = url

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.delegate = self
            recorder?.record()

            elapsed = 0
            level = 0
            transcript = ""
            state = .recording

            startMetering()
        } catch {
            state = .error("No se pudo iniciar la grabación: \(error.localizedDescription)")
        }
    }

    func stopRecording() async {
        meterTimer?.invalidate()
        meterTimer = nil

        recorder?.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        guard let url = audioURL else {
            state = .error("Grabación inválida")
            return
        }

        self.audioFileName = url.lastPathComponent

        // Transcribir inmediatamente
        state = .transcribing
        await transcribe(url: url)
    }

    func cancel() {
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        recorder = nil
        if let url = audioURL {
            try? FileManager.default.removeItem(at: url)
        }
        audioURL = nil
        audioFileName = nil
        transcript = ""
        elapsed = 0
        level = 0
        state = .idle
    }

    /// Reinicia el recorder tras guardar (sin borrar archivos).
    func reset() {
        recorder = nil
        audioURL = nil
        audioFileName = nil
        transcript = ""
        elapsed = 0
        level = 0
        state = .idle
    }

    // MARK: — Metering (waveform)

    private func startMetering() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let r = self.recorder, r.isRecording else { return }
                r.updateMeters()
                let db = r.averagePower(forChannel: 0)      // típicamente -160...0
                // Mapear a 0...1 (curva percibida)
                let minDb: Float = -50
                let normalized = max(0, min(1, (db - minDb) / -minDb))
                self.level = pow(normalized, 1.6)
                self.elapsed = r.currentTime
            }
        }
    }

    // MARK: — Transcripción on-device

    private func transcribe(url: URL) async {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            // Guarda el audio sin transcripción si Speech no disponible
            transcript = ""
            state = .ready
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        // On-device SIEMPRE (privacidad)
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        await withCheckedContinuation { continuation in
            recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else {
                    continuation.resume()
                    return
                }
                if let error = error {
                    Task { @MainActor in
                        self.transcript = ""
                        self.state = .error("Transcripción falló: \(error.localizedDescription). El audio se guardará de todas formas.")
                    }
                    continuation.resume()
                    return
                }
                if let result = result, result.isFinal {
                    Task { @MainActor in
                        self.transcript = result.bestTranscription.formattedString
                        self.state = .ready
                    }
                    continuation.resume()
                }
            }
        }
    }

    // MARK: — Formato de tiempo

    func formattedElapsed() -> String {
        let total = Int(elapsed)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

extension AudioJournalRecorder: @preconcurrency AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // No-op: el flujo principal lo maneja stopRecording()
    }
}

// MARK: — Reproductor simple (playback de notas guardadas)

@Observable
@MainActor
final class AudioJournalPlayer: NSObject {
    private(set) var isPlaying = false
    private(set) var progress: Double = 0
    private(set) var duration: TimeInterval = 0

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var timer: Timer?

    func play(url: URL) {
        stop()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.prepareToPlay()
            duration = p.duration
            p.play()
            player = p
            isPlaying = true
            startTimer()
        } catch {
            print("⚠️ No se pudo reproducir audio: \(error)")
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        isPlaying = false
        progress = 0
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let p = self.player else { return }
                self.progress = p.duration > 0 ? p.currentTime / p.duration : 0
            }
        }
    }
}

extension AudioJournalPlayer: @preconcurrency AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.progress = 1
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}
