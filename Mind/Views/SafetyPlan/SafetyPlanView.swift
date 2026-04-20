import SwiftUI
import SwiftData

struct SafetyPlanView: View {
    @Query private var plans: [SafetyPlan]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private var plan: SafetyPlan {
        if let p = plans.first { return p }
        let new = SafetyPlan(); context.insert(new); return new
    }

    var body: some View {
        NavigationStack {
            ZStack { Theme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        BreathingHero()
                            .staggered(0, base: 0.0)

                        SafetyStepCard(step: 1, icon: "exclamationmark.triangle.fill", color: .orange,
                                       title: "Señales de alerta",
                                       hint: "Ej. pensamientos repetitivos, aislamiento, insomnio",
                                       items: plan.warningSignals)
                        .staggered(1, base: 0.0)

                        SafetyStepCard(step: 2, icon: "brain.fill", color: Theme.moodBlue,
                                       title: "Estrategias internas",
                                       hint: "Ej. respirar profundo, salir a caminar, escuchar música",
                                       items: plan.copingStrategies)
                        .staggered(2, base: 0.0)

                        ContactStepCard(step: 3, icon: "message.fill", color: Theme.moodGreen,
                                        title: "Personas que me distraen", contacts: plan.distractingContacts)
                        .staggered(3, base: 0.0)

                        ContactStepCard(step: 4, icon: "hand.raised.fill", color: Theme.moodPurple,
                                        title: "Personas de apoyo", contacts: plan.supportContacts)
                        .staggered(4, base: 0.0)

                        ContactStepCard(step: 5, icon: "stethoscope", color: Theme.accent,
                                        title: "Mis profesionales", contacts: plan.professionals)
                        .staggered(5, base: 0.0)

                        CrisisLinesCard(lines: plan.crisisLines)
                            .staggered(6, base: 0.0)

                        Text("Buscar ayuda es un acto de valentía.")
                            .font(.footnote).foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 8)
                }
            }
            .navigationTitle("Plan de seguridad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }.font(.headline)
                }
            }
        }
    }
}

// MARK: — Breathing hero (animación de respiración)

struct BreathingHero: View {
    @State private var breatheIn = false
    @State private var appeared = false

    private let breathDuration = 4.0

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Ondas de expansión
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Theme.crisisRed.opacity(0.12 - Double(i) * 0.03), lineWidth: 1.5)
                        .frame(width: 90 + CGFloat(i) * 24, height: 90 + CGFloat(i) * 24)
                        .scaleEffect(breatheIn ? 1 + CGFloat(i) * 0.18 : 1)
                        .animation(
                            .easeInOut(duration: breathDuration).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                            value: breatheIn
                        )
                }
                // Círculo principal
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.crisisRed.opacity(0.25), Theme.crisisRed.opacity(0.08)],
                            center: .center, startRadius: 0, endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)
                    .scaleEffect(breatheIn ? 1.12 : 0.94)
                    .animation(.easeInOut(duration: breathDuration).repeatForever(autoreverses: true), value: breatheIn)

                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.crisisRed)
                    .scaleEffect(breatheIn ? 1.08 : 0.96)
                    .animation(.easeInOut(duration: breathDuration).repeatForever(autoreverses: true), value: breatheIn)
            }
            .frame(height: 120)

            VStack(spacing: 6) {
                Text("Estás a salvo")
                    .font(.title.bold()).foregroundStyle(Theme.textPrimary)
                Text(breatheIn ? "Exhala… suelta la tensión" : "Inhala… despacio")
                    .font(.subheadline).foregroundStyle(Theme.secondaryText)
                    .animation(.smooth, value: breatheIn)
                    .contentTransition(.opacity)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 0)
        .onAppear {
            withAnimation { appeared = true }
            withAnimation(.easeInOut(duration: breathDuration).repeatForever(autoreverses: true)) {
                breatheIn = true
            }
        }
    }
}

// MARK: — Step cards

struct SafetyStepCard: View {
    let step: Int; let icon: String; let color: Color
    let title: String; let hint: String; let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PlanStepHeader(step: step, icon: icon, color: color, title: title)
            Divider()
            if items.isEmpty {
                Text(hint).font(.subheadline.italic()).foregroundStyle(Color(.tertiaryLabel))
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    HStack(spacing: 10) {
                        Circle().fill(color).frame(width: 7, height: 7)
                        Text(item).font(.subheadline)
                    }
                    .staggered(i, base: 0.05)
                }
            }
        }
        .cardStyle()
    }
}

struct ContactStepCard: View {
    let step: Int; let icon: String; let color: Color
    let title: String; let contacts: [Contact]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PlanStepHeader(step: step, icon: icon, color: color, title: title)
            Divider()
            if contacts.isEmpty {
                Text("Agrega contactos con tu psicólogo en la próxima sesión.")
                    .font(.subheadline.italic()).foregroundStyle(Color(.tertiaryLabel))
            } else {
                ForEach(contacts) { c in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.name).font(.subheadline.bold())
                            Text(c.relationship).font(.caption).foregroundStyle(Theme.secondaryText)
                        }
                        Spacer()
                        Link(destination: URL(string: "tel:\(c.phone)")!) {
                            Image(systemName: "phone.fill").foregroundStyle(.white)
                                .padding(10).background(color).clipShape(Circle())
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct CrisisLinesCard: View {
    let lines: [CrisisLine]
    @State private var buttonScale: [UUID: CGFloat] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PlanStepHeader(step: 6, icon: "sos.circle.fill", color: Theme.crisisRed, title: "Líneas de crisis")
            Divider()
            ForEach(lines) { line in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(line.name).font(.subheadline.bold())
                        Text(line.country).font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    Link(destination: URL(string: "tel:\(line.number.filter(\.isNumber))")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                            Text(line.number).font(.subheadline.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(Theme.crisisRed)
                        .clipShape(Capsule())
                        .scaleEffect(buttonScale[line.id] ?? 1)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        Haptics.warning()
                        withAnimation(.bouncy) { buttonScale[line.id] = 0.9 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.springy) { buttonScale[line.id] = 1 }
                        }
                    })
                }
            }
        }
        .cardStyle()
    }
}

struct PlanStepHeader: View {
    let step: Int; let icon: String; let color: Color; let title: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 38, height: 38)
                Image(systemName: icon).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Paso \(step)").font(.caption.bold()).foregroundStyle(color)
                Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
            }
        }
    }
}
