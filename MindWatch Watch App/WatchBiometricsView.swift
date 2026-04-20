import SwiftUI

struct WatchBiometricsView: View {
    @StateObject private var health = WatchHealthService()
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Stress header
                StressHeader(level: health.stressLevel)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: appeared)

                // Sensor grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    BiometricTile(
                        icon: "heart.fill",
                        color: .red,
                        label: "Frec. cardíaca",
                        value: health.heartRate.map { "\(Int($0))" } ?? "–",
                        unit: "bpm"
                    )
                    BiometricTile(
                        icon: "waveform.path.ecg",
                        color: .purple,
                        label: "HRV",
                        value: health.hrv.map { String(format: "%.0f", $0) } ?? "–",
                        unit: "ms"
                    )
                    BiometricTile(
                        icon: "lungs.fill",
                        color: .blue,
                        label: "SpO₂",
                        value: health.oxygenSaturation.map { String(format: "%.0f", $0) } ?? "–",
                        unit: "%"
                    )
                    BiometricTile(
                        icon: "figure.walk",
                        color: .green,
                        label: "Pasos",
                        value: "\(health.steps)",
                        unit: "hoy"
                    )
                }

                // HRV explanation
                if health.hrv != nil {
                    HRVInsightCard(hrv: health.hrv!, level: health.stressLevel)
                }

                // Refresh
                Button {
                    Task { await health.fetchAll() }
                } label: {
                    Label("Actualizar", systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Biométricos")
        .task {
            await health.requestAuthorization()
            withAnimation { appeared = true }
        }
    }
}

// MARK: — Stress header

struct StressHeader: View {
    let level: WatchHealthService.StressLevel
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(stressColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .scaleEffect(pulse ? 1.15 : 1)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                Text(level.emoji)
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Nivel de estrés")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(level.rawValue)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(stressColor)
            }
            Spacer()
        }
        .padding(10)
        .background(stressColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear { pulse = true }
    }

    private var stressColor: Color {
        switch level {
        case .unknown:  return .gray
        case .low:      return .green
        case .moderate: return .yellow
        case .high:     return .red
        }
    }
}

// MARK: — Biometric tile

struct BiometricTile: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let unit: String
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.smooth, value: value)

            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(0.15)) {
                appeared = true
            }
        }
    }
}

// MARK: — HRV insight

struct HRVInsightCard: View {
    let hrv: Double
    let level: WatchHealthService.StressLevel

    private var insight: String {
        switch level {
        case .low:
            return "Tu sistema nervioso está en calma. Buen momento para estudiar o concentrarte."
        case .moderate:
            return "Algo de tensión presente. Un ejercicio de respiración puede ayudar."
        case .high:
            return "Estrés elevado detectado. Considera una pausa antes de tu próxima actividad."
        case .unknown:
            return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Insight HRV", systemImage: "brain")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.purple)
            Text(insight)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
