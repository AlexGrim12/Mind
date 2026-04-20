import SwiftUI
import Foundation

struct WatchHomeView: View {
    @EnvironmentObject private var store: WatchStore
    @StateObject private var health = WatchHealthService()
    @State private var showCheckin = false
    @State private var showBreathing = false
    @State private var showRemotePrompt = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {

                    SyncStatusCard(store: store)

                    // Stress + HR live
                    LiveStressBar(health: health)

                    // Mood ring + estado de hoy
                    MoodRingWidget(avg: store.avgMood, todayDone: store.todayDone)

                    // Quick check-in
                    if !store.todayDone {
                        Button { showCheckin = true } label: {
                            Label("¿Cómo estás?", systemImage: "face.smiling")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    } else if let score = store.lastSentScore {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("Registrado · \(score)/10")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Sensor mini-grid
                    SensorMiniGrid(health: health)

                    // Próxima cita
                    if let date = store.nextApptDate, let name = store.nextApptClinician {
                        AppointmentWidget(date: date, clinician: name)
                    }

                    // Acciones rápidas
                    HStack(spacing: 8) {
                        NavigationLink {
                            WatchBiometricsView()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.purple)
                                Text("Sensores")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        Button { showBreathing = true } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "wind")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.teal)
                                Text("Respirar")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.teal.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    // Racha
                    HStack(spacing: 6) {
                        Text("🔥").font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(store.streak) registros")
                                .font(.system(size: 13, weight: .bold))
                            Text("sigue así")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Mind")
            .sheet(isPresented: $showCheckin) {
                WatchMoodCheckinView().environmentObject(store)
            }
            .sheet(isPresented: $showBreathing) {
                WatchBreathingView()
            }
            .alert("Solicitud desde iPhone", isPresented: $showRemotePrompt) {
                Button("Abrir check-in") { showCheckin = true }
                Button("Ahora no", role: .cancel) {}
            } message: {
                Text("Tu iPhone te pidió registrar tu ánimo desde el Apple Watch.")
            }
            .task {
                await health.requestAuthorization()
                sendLatestBiometrics()
            }
            .onChange(of: health.stressLevel) { _, _ in
                sendLatestBiometrics()
            }
            .onChange(of: health.heartRate) { _, _ in
                sendLatestBiometrics()
            }
            .onChange(of: health.hrv) { _, _ in
                sendLatestBiometrics()
            }
            .onChange(of: health.oxygenSaturation) { _, _ in
                sendLatestBiometrics()
            }
            .onChange(of: health.steps) { _, _ in
                sendLatestBiometrics()
            }
            .onChange(of: store.remoteCheckinRequestAt) { _, _ in
                if store.remoteCheckinRequestAt != nil {
                    showRemotePrompt = true
                }
            }
        }
    }

    private func sendLatestBiometrics() {
        // Mantiene al iPhone actualizado con timestamp + estado del Watch.
        store.sendBiometrics(health.contextPayload)
    }
}

struct SyncStatusCard: View {
    @ObservedObject var store: WatchStore

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("Conexión iPhone")
                    .font(.system(size: 11, weight: .semibold))
                Text(syncText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let score = store.lastSentScore {
                Text("Último: \(score)/10")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.green)
            }
        }
        .padding(10)
        .background(Color.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var syncText: String {
        guard let date = store.lastPhoneContextSyncAt else { return "Esperando datos del iPhone" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Contexto recibido " + formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: — Live stress bar

struct LiveStressBar: View {
    @ObservedObject var health: WatchHealthService
    @State private var pulse = false

    private var stressColor: Color {
        switch health.stressLevel {
        case .unknown:  return .gray
        case .low:      return .green
        case .moderate: return .yellow
        case .high:     return .red
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Pulsing heart
            ZStack {
                Circle()
                    .fill(stressColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .scaleEffect(pulse ? 1.2 : 1)
                    .animation(
                        .easeInOut(duration: heartbeatInterval).repeatForever(autoreverses: true),
                        value: pulse
                    )
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(stressColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(health.heartRate.map { "\(Int($0)) bpm" } ?? "– bpm")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.smooth, value: health.heartRate)
                    Spacer()
                    Text(health.stressLevel.emoji + " " + health.stressLevel.rawValue)
                        .font(.system(size: 11))
                        .foregroundStyle(stressColor)
                }
                Text("HRV: \(health.hrv.map { String(format: "%.0f ms", $0) } ?? "–")")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(stressColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear { pulse = true }
    }

    private var heartbeatInterval: Double {
        guard let hr = health.heartRate, hr > 0 else { return 1.0 }
        return 60.0 / hr
    }
}

// MARK: — Sensor mini grid

struct SensorMiniGrid: View {
    @ObservedObject var health: WatchHealthService

    var body: some View {
        HStack(spacing: 8) {
            MiniSensorPill(
                icon: "lungs.fill", color: .blue,
                value: health.oxygenSaturation.map { String(format: "%.0f%%", $0) } ?? "–",
                label: "SpO₂"
            )
            MiniSensorPill(
                icon: "figure.walk", color: .green,
                value: stepsLabel,
                label: "Pasos"
            )
        }
    }

    private var stepsLabel: String {
        health.steps >= 1000
            ? String(format: "%.1fk", Double(health.steps) / 1000)
            : "\(health.steps)"
    }
}

struct MiniSensorPill: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .contentTransition(.numericText())
                    .animation(.smooth, value: value)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: — Mood ring (unchanged)

struct MoodRingWidget: View {
    let avg: Double
    let todayDone: Bool
    @State private var progress: Double = 0

    private var color: Color {
        switch Int(avg) {
        case 0...3: return .purple
        case 4...5: return .blue
        case 6...7: return .green
        case 8...9: return .yellow
        default:    return .orange
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1, bounce: 0.2), value: progress)
                Text(avg > 0 ? String(format: "%.0f", avg) : "–")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Ánimo semanal")
                    .font(.system(size: 12, weight: .semibold))
                Text(todayDone ? "Hoy: registrado ✓" : "Hoy: pendiente")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { progress = avg / 10.0 }
        }
    }
}

// MARK: — Appointment widget (unchanged)

struct AppointmentWidget: View {
    let date: Date
    let clinician: String

    private var daysUntil: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 18))
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(clinician)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text(daysUntil == 0 ? "Hoy" : "En \(daysUntil) día\(daysUntil == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
