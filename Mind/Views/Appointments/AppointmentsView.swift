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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // Encabezado Zen
                    ToriiHeader(title: "Tus Encuentros", subtitle: "Espacio de escucha y apoyo", kanji: "会")
                        .padding(.top, 20)

                    if appointments.isEmpty {
                        EmptyAppointmentsZenView { showBooking = true }
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 32) {
                            // Próximas
                            if !upcoming.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    zenSectionHeader(title: "Próximas Sesiones", subtitle: "Momentos de reflexión")
                                    
                                    ForEach(Array(upcoming.enumerated()), id: \.element.id) { i, appt in
                                        NavigationLink {
                                            SessionPrepView(appointment: appt)
                                        } label: {
                                            UpcomingAppointmentZenCard(appointment: appt)
                                        }
                                        .buttonStyle(.plain)
                                        .staggered(i)
                                    }
                                }
                            }

                            // Anteriores
                            if !past.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    zenSectionHeader(title: "Historial", subtitle: "Tu camino recorrido")
                                    
                                    ForEach(Array(past.enumerated()), id: \.element.id) { i, appt in
                                        PastAppointmentZenRow(appointment: appt)
                                            .staggered(i, base: 0.2)
                                    }
                                }
                            }

                            Spacer(minLength: 120)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .screenBackground()
            .navigationTitle("Citas · 会")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.impact(.medium)
                        showBooking = true
                    } label: {
                        HankoStamp(kanji: "＋", color: Theme.ai, size: 32)
                    }
                }
            }
        }
        .sheet(isPresented: $showBooking) { BookAppointmentView() }
    }
}

// MARK: — Upcoming Zen Card

struct UpcomingAppointmentZenCard: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                // Avatar Estilo Enso
                ZStack {
                    EnsoCircle(color: Theme.ai, lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                    Text(appointment.clinicianName.prefix(1))
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.sumi)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.clinicianName)
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                    Text(appointment.formattedDate)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.sumiSoft)
                }
                Spacer()
                
                HankoStamp(kanji: "師", color: Theme.ai.opacity(0.6), size: 28)
            }

            HStack {
                Label(appointment.duration == .express ? "15 min" : "50 min", systemImage: "clock")
                Spacer()
                if appointment.isRemote {
                    Label("En remoto", systemImage: "video.fill")
                        .foregroundStyle(Theme.matchaDeep)
                }
            }
            .font(.system(.caption, design: .serif).bold())
            .foregroundStyle(Theme.sumiSoft)
            
            // Botón Zen CTA
            HStack {
                Text("Preparar el corazón para la sesión")
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(Theme.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .cardStyle()
    }
}

// MARK: — Past Zen Row

struct PastAppointmentZenRow: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Theme.kinari.opacity(0.5))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(Theme.matchaDeep))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.clinicianName)
                    .font(.system(.subheadline, design: .serif).weight(.bold))
                    .foregroundStyle(Theme.sumi)
                Text(appointment.formattedDate)
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(Theme.sumiSoft)
            }
            Spacer()
            
            if appointment.sessionRating != nil {
                SakuraBlossom(size: 16)
            }
        }
        .padding(14)
        .background(Theme.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.inkLine, lineWidth: 0.5))
    }
}

// MARK: — Empty state Zen

struct EmptyAppointmentsZenView: View {
    let onBook: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                EnsoCircle(color: Theme.sumi.opacity(0.1), lineWidth: 2)
                    .frame(width: 140, height: 140)
                PagodaIcon()
                    .frame(width: 60, height: 60)
                    .opacity(0.2)
            }

            VStack(spacing: 12) {
                Text("Silencio en tu agenda")
                    .font(.system(.title3, design: .serif).weight(.bold))
                Text("No hay encuentros programados. Reserva un momento para tu bienestar.")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(Theme.sumiSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onBook) {
                Text("Solicitar Encuentro")
            }
            .primaryButton()
            .padding(.horizontal, 40)
        }
    }
}

// MARK: — Booking View Zen

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
                Theme.ambientBackground.ignoresSafeArea()

                if confirmed {
                    BookingConfirmedZenView { dismiss() }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            ToriiHeader(title: "Agendar Encuentro", subtitle: "Selecciona un momento de paz", kanji: "約")
                                .padding(.top, 20)

                            // Guía Header
                            HStack(spacing: 16) {
                                ZStack {
                                    EnsoCircle(color: Theme.ai, lineWidth: 1.5)
                                        .frame(width: 60, height: 60)
                                    Text("師").font(.system(size: 24, design: .serif)).foregroundStyle(Theme.sumi)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dra. Laura Rivera").font(.system(.headline, design: .serif))
                                    Text("Tu guía en el camino").font(.system(.caption, design: .serif)).foregroundStyle(Theme.sumiSoft)
                                }
                                Spacer()
                            }
                            .cardStyle()

                            // Duración
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Duración del Encuentro").font(.system(.subheadline, design: .serif).bold())
                                HStack(spacing: 12) {
                                    ForEach(AppointmentDuration.allCases, id: \.self) { d in
                                        DurationZenChip(duration: d, selected: duration == d) {
                                            Haptics.selection()
                                            withAnimation(.springy) { duration = d }
                                        }
                                    }
                                }
                                
                                Divider().background(Theme.inkLine)
                                
                                Toggle(isOn: $isRemote) {
                                    Label("Encuentro Virtual", systemImage: "video.fill")
                                        .font(.system(.subheadline, design: .serif))
                                }
                                .tint(Theme.ai)
                            }
                            .cardStyle()

                            // Horarios
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Horarios Disponibles").font(.system(.subheadline, design: .serif).bold())
                                
                                FlowLayout(spacing: 10) {
                                    ForEach(slots, id: \.self) { slot in
                                        TimeSlotZenButton(slot: slot, selected: selectedSlot == slot) {
                                            Haptics.selection()
                                            withAnimation(.springy) { selectedSlot = slot }
                                        }
                                    }
                                }
                            }
                            .cardStyle()

                            // Botón de Confirmación
                            Button {
                                guard selectedSlot != nil else { return }
                                Haptics.success()
                                book()
                                withAnimation(.springy) { confirmed = true }
                            } label: {
                                Text(selectedSlot == nil ? "Elige un horario" : "Confirmar Cita")
                            }
                            .primaryButton(color: selectedSlot == nil ? Theme.sumiSoft.opacity(0.5) : Theme.ai)
                            .disabled(selectedSlot == nil)

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.sumiSoft)
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

struct DurationZenChip: View {
    let duration: AppointmentDuration
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(duration == .express ? "短" : "全") // Short vs Full
                    .font(.system(size: 20, weight: .bold, design: .serif))
                Text(duration == .express ? "15 min" : "50 min")
                    .font(.system(.caption2, design: .serif).bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? Theme.ai : Theme.kinari.opacity(0.3))
            .foregroundStyle(selected ? .white : Theme.sumi)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.inkLine, lineWidth: selected ? 0 : 0.5))
        }
    }
}

struct TimeSlotZenButton: View {
    let slot: Date
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(slot, format: .dateTime.hour().minute())
                .font(.system(.subheadline, design: .serif).weight(.bold))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(selected ? Theme.ai : Theme.cardBackground)
                .foregroundStyle(selected ? .white : Theme.sumi)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.inkLine, lineWidth: selected ? 0 : 0.5))
        }
    }
}

struct BookingConfirmedZenView: View {
    let onDone: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                EnsoCircle(color: Theme.matcha, lineWidth: 3)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(appeared ? 360 : 0))
                
                HankoStamp(kanji: "成", color: Theme.matchaDeep, size: 80) // "Success / Accomplished"
                    .scaleEffect(appeared ? 1 : 0.5)
            }
            
            VStack(spacing: 12) {
                Text("Vínculo Establecido")
                    .font(.system(.title2, design: .serif).weight(.bold))
                Text("Tu encuentro ha sido registrado en el gran pergamino de tu camino.")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(Theme.sumiSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onDone) {
                Text("Cerrar")
            }
            .primaryButton()
            .padding(.horizontal, 60)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(duration: 1.5)) { appeared = true }
        }
    }
}
