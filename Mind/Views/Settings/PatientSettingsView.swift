import SwiftUI

struct PatientSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userRole") private var userRole = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: - Perfil
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.sakura.opacity(0.35))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Theme.sumi)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Zenith")
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundStyle(Theme.textPrimary)
                                
                                Text("Estudiante · FI - UNAM")
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Theme.matcha)
                                    .frame(width: 8, height: 8)
                                Text("Estado: En equilibrio")
                                    .font(.system(.caption, design: .serif).weight(.bold))
                                    .foregroundStyle(Theme.matchaDeep)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.matcha.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 20)
                        
                        // MARK: - Secciones de Configuración
                        VStack(spacing: 16) {
                            
                            // Sección Sistema
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SISTEMA")
                                    .font(.system(.caption2, design: .serif).weight(.bold))
                                    .tracking(1.5)
                                    .foregroundStyle(Theme.sumiSoft)
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 0) {
                                    SettingsRow(icon: "brain.filled.head.profile", title: "MIND-LINK App", detail: "v1.0.2", color: Theme.ai)
                                    Divider().padding(.leading, 44)
                                    SettingsRow(icon: "checkmark.seal.fill", title: "IA On-Device", detail: "Activa", color: Theme.matchaDeep)
                                    Divider().padding(.leading, 44)
                                    SettingsRow(icon: "applewatch", title: "Sincronización Watch", detail: "Automática", color: Theme.asagi)
                                }
                                .cardStyle(padding: 0)
                            }
                            
                            // Sección Cuenta
                            VStack(alignment: .leading, spacing: 12) {
                                Text("CUENTA")
                                    .font(.system(.caption2, design: .serif).weight(.bold))
                                    .tracking(1.5)
                                    .foregroundStyle(Theme.sumiSoft)
                                    .padding(.horizontal, 4)
                                
                                Button(role: .destructive) {
                                    Haptics.warning()
                                    showLogoutAlert = true
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Theme.aka.opacity(0.1))
                                                .frame(width: 32, height: 32)
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(Theme.aka)
                                        }
                                        Text("Cerrar Sesión")
                                            .font(.system(.subheadline, design: .serif).weight(.bold))
                                            .foregroundStyle(Theme.aka)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(Theme.sumiSoft.opacity(0.5))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)
                                .cardStyle(padding: 0)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                        
                        Text("MIND-LINK · Proyecto de Bienestar FI - UNAM\n2026 · Monterrey, México")
                            .font(.system(.caption2, design: .serif))
                            .foregroundStyle(Theme.sumiSoft.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .font(.system(.body, design: .serif).weight(.bold))
                    .foregroundStyle(Theme.ai)
                }
            }
        }
        .alert("¿Cerrar sesión?", isPresented: $showLogoutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar sesión", role: .destructive) {
                logout()
            }
        } message: {
            Text("Tu progreso local está a salvo, pero necesitarás ingresar tus credenciales de nuevo.")
        }
    }
    
    private func logout() {
        withAnimation(.smooth) {
            isLoggedIn = false
            userRole = ""
            // hasCompletedOnboarding = false // Opcional: si quieres resetear el onboarding
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
            
            Text(detail)
                .font(.system(.caption, design: .serif))
                .foregroundStyle(Theme.secondaryText)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.sumiSoft.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    PatientSettingsView()
}
