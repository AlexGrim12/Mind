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
            Theme.ambientBackground.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { 
                        VStack {
                            Image(systemName: selectedTab == 0 ? "sun.max.fill" : "sun.max")
                            Text("Hoy · 今日") 
                        }
                    }
                    .tag(0)

                TrendsView()
                    .tabItem { 
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("Camino · 経") 
                        }
                    }
                    .tag(1)

                WellnessView()
                    .tabItem { 
                        VStack {
                            Image(systemName: selectedTab == 2 ? "heart.text.clipboard.fill" : "heart.text.clipboard")
                            Text("Salud · 康") 
                        }
                    }
                    .tag(2)

                AppointmentsView()
                    .tabItem { 
                        VStack {
                            Image(systemName: selectedTab == 3 ? "calendar.badge.clock" : "calendar")
                            Text("Citas · 会") 
                        }
                    }
                    .tag(3)

                ClinicianView()
                    .tabItem { 
                        VStack {
                            Image(systemName: "person.badge.shield.checkmark")
                            Text("Apoyo · 師") 
                        }
                    }
                    .tag(4)
            }
            .tint(Theme.ai)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)

            // Floating SOS button (Estilo Sello Hanko de Emergencia)
            Button {
                Haptics.warning()
                sosPressed = true
                showCrisis = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { sosPressed = false }
            } label: {
                HStack(spacing: 8) {
                    Text("急") // "Emergency / Urgent"
                        .font(.system(size: 20, weight: .black, design: .serif))
                    Text("Ayuda")
                        .font(.system(.subheadline, design: .serif).weight(.bold))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Theme.aka, Theme.aka.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.35), lineWidth: 1.2)
                )
                .shadow(color: Theme.aka.opacity(0.4), radius: 12, x: 0, y: 6)
                .scaleEffect(sosPressed ? 0.92 : 1)
                .animation(.springy, value: sosPressed)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: $showCrisis) {
            SafetyPlanView()
        }
    }
}
