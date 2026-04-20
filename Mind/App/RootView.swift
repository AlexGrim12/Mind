import SwiftUI

struct RootView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userRole") private var userRole = ""

    var body: some View {
        Group {
            if !isLoggedIn {
                LoginView()
                    .transition(.opacity)
            } else if userRole == "doctor" {
                DoctorDashboardView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                PatientRootView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.smooth, value: isLoggedIn)
        .animation(.smooth, value: userRole)
    }
}

// MARK: - Patient flow (keeps existing onboarding logic)

struct PatientRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth, value: hasCompletedOnboarding)
    }
}

// MARK: - MainTabView (patient app)

struct MainTabView: View {
    @State private var showCrisis = false
    @State private var selectedTab = 0
    @State private var sosPressed = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.appBackground
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Hoy", systemImage: selectedTab == 0 ? "sun.max.fill" : "sun.max") }
                    .tag(0)

                TrendsView()
                    .tabItem { Label("Tendencia", systemImage: "chart.line.uptrend.xyaxis") }
                    .tag(1)

                SleepView()
                    .tabItem { Label("Sueño", systemImage: selectedTab == 2 ? "moon.stars.fill" : "moon.fill") }
                    .tag(2)

                AppointmentsView()
                    .tabItem { Label("Citas", systemImage: selectedTab == 3 ? "calendar.badge.clock" : "calendar") }
                    .tag(3)

                ClinicianView()
                    .tabItem { Label("Psicólogo", systemImage: "person.badge.shield.checkmark") }
                    .tag(4)
            }
            .tint(Theme.accent)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)

            // Floating SOS button
            Button {
                Haptics.warning()
                sosPressed = true
                showCrisis = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { sosPressed = false }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sos.circle.fill")
                        .font(.system(size: 17, weight: .bold))
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                    Text("Ayuda")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Theme.crisisRed.opacity(0.92), Theme.crisisRed],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                .shadow(color: Theme.crisisRed.opacity(0.44), radius: 16, x: 0, y: 8)
                .scaleEffect(sosPressed ? 0.95 : 1)
                .animation(.springy, value: sosPressed)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 90)
        }
        .sheet(isPresented: $showCrisis) {
            SafetyPlanView()
        }
    }
}
