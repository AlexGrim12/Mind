import SwiftUI
import SwiftData
import Combine

struct AppointmentsView: View {
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @Environment(\.modelContext) private var context
    @State private var showBooking = false
    @State private var appeared = false

    private var upcoming: [Appointment] { appointments.filter(\.isUpcoming) }
    private var past: [Appointment]    { appointments.filter(\.isPast) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                if appointments.isEmpty {
                    EmptyAppointmentsView { showBooking = true }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Próximas
                            if !upcoming.isEmpty {
                                SectionBlock(title: "Próximas", icon: "calendar.badge.clock") {
                                    VStack(spacing: 12) {
                                        ForEach(Array(upcoming.enumerated()), id: \.element.id) { i, appt in
                                            NavigationLink {
                                                SessionPrepView(appointment: appt)
                                            } label: {
                                                UpcomingAppointmentCard(appointment: appt)
                                            }
                                            .buttonStyle(.plain)
                                            .staggered(i)
                                        }
                                    }
                                }
                            }

                            // Anteriores
                            if !past.isEmpty {
                                SectionBlock(title: "Anteriores", icon: "clock.arrow.circlepath") {
                                    VStack(spacing: 10) {
                                        ForEach(Array(past.enumerated()), id: \.element.id) { i, appt in
                                            NavigationLink {
                                                SessionPrepView(appointment: appt)
                                            } label: {
                                                PastAppointmentRow(appointment: appt)
                                            }
                                            .buttonStyle(.plain)
                                            .staggered(i, base: 0.2)
                                        }
                                    }
                                }
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Mis citas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.impact(.medium)
                        showBooking = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 32, height: 32)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showBooking) { BookAppointmentView() }
    }
}

// MARK: — Section block

struct SectionBlock<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            content
        }
    }
}

// MARK: — Upcoming card (destacada)

struct UpcomingAppointmentCard: View {
    let appointment: Appointment
    @State private var shimmerOn = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                // Avatar con gradiente
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Theme.accent.opacity(0.8), Theme.moodPurple.opacity(0.6)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Text(appointment.clinicianName.prefix(2).uppercased())
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.clinicianName)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(appointment.formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(appointment.duration == .express ? "15 min" : "50 min")
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.accent.opacity(0.12))
                        .foregroundStyle(Theme.accent)
                        .clipShape(Capsule())

                    if appointment.isRemote {
                        Label("Remoto", systemImage: "video.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.moodGreen)
                    }
                }
            }

            // Countdown
            CountdownPill(date: appointment.date)

            // CTA
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Preparar sesión")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .cardStyle()
    }
}

struct CountdownPill: View {
    let date: Date
    @State private var timeString = ""

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.caption.bold())
            Text(timeString)
                .font(.caption.bold())
                .contentTransition(.numericText())
        }
        .foregroundStyle(Theme.moodGreen)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Theme.moodGreen.opacity(0.1))
        .clipShape(Capsule())
        .onAppear { updateTime() }
        .onReceive(timer) { _ in withAnimation(.smooth) { updateTime() } }
    }

    private func updateTime() {
        let diff = date.timeIntervalSinceNow
        if diff <= 0 { timeString = "Ahora"; return }
        let days = Int(diff / 86400)
        let hours = Int((diff.truncatingRemainder(dividingBy: 86400)) / 3600)
        let mins = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)
        if days > 0 { timeString = "En \(days)d \(hours)h" }
        else if hours > 0 { timeString = "En \(hours)h \(mins)m" }
        else { timeString = "En \(mins) min" }
    }
}

// MARK: — Past row

struct PastAppointmentRow: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.moodGreen)
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.clinicianName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.secondaryText)
                Text(appointment.formattedDate)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            if appointment.sessionRating != nil {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.moodYellow)
            } else {
                Text("Valorar")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

// MARK: — Empty state

struct EmptyAppointmentsView: View {
    let onBook: () -> Void
    @State private var iconBounce = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.08))
                    .frame(width: 120, height: 120)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.accent)
                    .scaleEffect(iconBounce ? 1.08 : 1)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: iconBounce)
            }

            VStack(spacing: 8) {
                Text("Sin citas agendadas")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("Reserva una sesión con tu psicólogo\npara empezar.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: { Haptics.impact(.medium); onBook() }) {
                Text("Agendar primera cita")
                    .primaryButton()
            }
            .pressEffect()
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { iconBounce = true }
    }
}

// MARK: — Booking sheet

struct BookAppointmentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSlot: Date? = nil
    @State private var duration: AppointmentDuration = .full
    @State private var isRemote = false
    @State private var confirmed = false

    private let slots: [Date] = {
        let base = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        return [9, 10, 11, 14, 15, 16, 17].compactMap {
            Calendar.current.date(bySettingHour: $0, minute: 0, second: 0, of: base)
        }
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                if confirmed {
                    BookingConfirmedView { dismiss() }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Clinician header
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [Theme.accent, Theme.moodPurple],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 56, height: 56)
                                    Text("DR").font(.headline.bold()).foregroundStyle(.white)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Dra. Laura Rivera")
                                        .font(.headline).foregroundStyle(Theme.textPrimary)
                                    Text("Psicología clínica · CBT")
                                        .font(.caption).foregroundStyle(Theme.secondaryText)
                                    HStack(spacing: 4) {
                                        Circle().fill(Theme.moodGreen).frame(width: 7, height: 7)
                                        Text("Disponible").font(.caption).foregroundStyle(Theme.moodGreen)
                                    }
                                }
                                Spacer()
                            }
                            .cardStyle()

                            // Tipo
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tipo de cita").font(.headline)
                                HStack(spacing: 12) {
                                    ForEach(AppointmentDuration.allCases, id: \.self) { d in
                                        DurationChip(duration: d, selected: duration == d) {
                                            Haptics.selection()
                                            withAnimation(.springy) { duration = d }
                                        }
                                    }
                                }
                                Toggle(isOn: $isRemote) {
                                    Label("Videollamada", systemImage: "video.fill")
                                        .font(.subheadline)
                                }
                                .tint(Theme.accent)
                                .onChange(of: isRemote) { _, _ in Haptics.selection() }
                            }
                            .cardStyle()

                            // Horarios
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Horarios disponibles")
                                    .font(.headline)
                                Text("Mañana · \(slots.first?.formatted(.dateTime.weekday(.wide).day().month()) ?? "")")
                                    .font(.subheadline).foregroundStyle(Theme.secondaryText)

                                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 10) {
                                    ForEach(slots, id: \.self) { slot in
                                        TimeSlotButton(slot: slot, selected: selectedSlot == slot) {
                                            Haptics.selection()
                                            withAnimation(.springy) { selectedSlot = slot }
                                        }
                                    }
                                }
                            }
                            .cardStyle()

                            // Confirmar
                            Button {
                                guard selectedSlot != nil else { return }
                                Haptics.success()
                                book()
                                withAnimation(.springy) { confirmed = true }
                            } label: {
                                Text(selectedSlot == nil ? "Selecciona un horario" : "Confirmar cita")
                                    .primaryButton(color: selectedSlot == nil ? Color(.systemGray3) : Theme.accent)
                            }
                            .pressEffect()
                            .disabled(selectedSlot == nil)

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20).padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Reservar cita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func book() {
        let appt = Appointment(date: selectedSlot!, duration: duration,
                               clinicianName: "Dra. Laura Rivera", isRemote: isRemote)
        context.insert(appt)
    }
}

struct DurationChip: View {
    let duration: AppointmentDuration
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: duration.icon)
                    .font(.title3)
                    .foregroundStyle(selected ? .white : Theme.accent)
                Text(duration == .express ? "15 min" : "50 min")
                    .font(.caption.bold())
                    .foregroundStyle(selected ? .white : Theme.textPrimary)
                Text(duration == .express ? "Express" : "Completa")
                    .font(.caption2)
                    .foregroundStyle(selected ? .white.opacity(0.8) : Theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selected ? Theme.accent : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(selected ? 1.03 : 1)
            .animation(.springy, value: selected)
        }
    }
}

struct TimeSlotButton: View {
    let slot: Date
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(slot, format: .dateTime.hour().minute())
                .font(.subheadline.bold())
                .foregroundStyle(selected ? .white : Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Theme.accent : Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .scaleEffect(selected ? 1.06 : 1)
                .shadow(color: selected ? Theme.accent.opacity(0.4) : .clear, radius: 6, y: 3)
                .animation(.springy, value: selected)
        }
    }
}

struct BookingConfirmedView: View {
    let onDone: () -> Void
    @State private var scale: CGFloat = 0
    @State private var ringsVisible = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Theme.moodGreen.opacity(0.15 - Double(i) * 0.04), lineWidth: 2)
                        .frame(width: 100 + CGFloat(i) * 30)
                        .scaleEffect(ringsVisible ? 1 : 0.5)
                        .opacity(ringsVisible ? 1 : 0)
                        .animation(.springy.delay(Double(i) * 0.1), value: ringsVisible)
                }
                ZStack {
                    Circle().fill(Theme.moodGreen).frame(width: 90, height: 90)
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)
                .animation(.bouncy.delay(0.1), value: scale)
            }

            VStack(spacing: 8) {
                Text("¡Cita confirmada!")
                    .font(.title.bold()).foregroundStyle(Theme.textPrimary)
                Text("Te esperamos. Revisa tu calendario.")
                    .font(.subheadline).foregroundStyle(Theme.secondaryText)
            }

            Button(action: { Haptics.impact(.light); onDone() }) {
                Text("Perfecto")
                    .primaryButton(color: Theme.moodGreen)
            }
            .pressEffect()
            .padding(.horizontal, 40)
            Spacer()
        }
        .onAppear {
            withAnimation { scale = 1; ringsVisible = true }
        }
    }
}
