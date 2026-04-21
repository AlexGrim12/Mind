import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userRole") private var userRole = ""

    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @State private var isLoading = false
    @FocusState private var focusedField: LoginField?

    private enum LoginField { case username, password }

    var body: some View {
        ZStack {
            // Fondo global zen
            Theme.ambientBackground.ignoresSafeArea()
            
            // Lluvia de pétalos sutil
            SakuraRain(petalCount: 12)
                .opacity(0.4)

            VStack(spacing: 0) {
                Spacer()

                // MARK: Brand header (Estilo Zen)
                VStack(spacing: 20) {
                    ToriiHeader(
                        title: "MIND-LINK",
                        subtitle: "Sistema de Bienestar Universitario",
                        kanji: "心"
                    )
                    
                    HankoStamp(kanji: "開", color: Theme.ai, size: 48)
                        .padding(.top, 10)
                }
                .padding(.bottom, 44)

                // MARK: Form card (Estilo Washi)
                VStack(spacing: 24) {
                    // Username field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MATRÍCULA / CÉDULA")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .foregroundStyle(Theme.sumiSoft)
                            .tracking(1.5)

                        HStack(spacing: 12) {
                            Image(systemName: "person")
                                .font(.system(size: 16))
                                .foregroundStyle(focusedField == .username ? Theme.ai : Theme.sumiSoft)

                            TextField("Ingresa tu usuario", text: $username)
                                .focused($focusedField, equals: .username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(Theme.sumi)
                                .tint(Theme.ai)
                                .onSubmit { focusedField = .password }
                        }
                        .padding(.vertical, 12)
                        .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.inkLine), alignment: .bottom)
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONTRASEÑA")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .foregroundStyle(Theme.sumiSoft)
                            .tracking(1.5)

                        HStack(spacing: 12) {
                            Image(systemName: "lock")
                                .font(.system(size: 16))
                                .foregroundStyle(focusedField == .password ? Theme.ai : Theme.sumiSoft)

                            SecureField("Ingresa tu contraseña", text: $password)
                                .focused($focusedField, equals: .password)
                                .foregroundStyle(Theme.sumi)
                                .tint(Theme.ai)
                                .onSubmit { attemptLogin() }
                        }
                        .padding(.vertical, 12)
                        .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.inkLine), alignment: .bottom)
                    }

                    // Error message
                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text("Credenciales incorrectas")
                        }
                        .font(.caption)
                        .foregroundStyle(Theme.aka)
                        .transition(.opacity)
                    }

                    // Login button (Estilo Hanko/Zen)
                    Button(action: attemptLogin) {
                        ZStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Entrar")
                            }
                        }
                        .primaryButton()
                    }
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
                    .opacity((username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                }
                .cardStyle()
                .padding(.horizontal, 24)

                Spacer()

                // Footer
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        EnsoCircle(color: Theme.sumiSoft, lineWidth: 1)
                            .frame(width: 14, height: 14)
                        Text("Portal seguro · Datos locales")
                            .font(.system(.caption2, design: .serif))
                            .foregroundStyle(Theme.sumiSoft)
                    }
                    Text("FI - UNAM · MIND-LINK v1.0")
                        .font(.system(.caption2, design: .serif))
                        .foregroundStyle(Theme.sumiSoft.opacity(0.6))
                }
                .padding(.bottom, 36)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { focusedField = nil }
    }

    private func attemptLogin() {
        guard !username.isEmpty, !password.isEmpty else { return }
        focusedField = nil
        isLoading = true
        showError = false

        // Simulated auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            userRole = username.lowercased() == "doctor" ? "doctor" : "patient"
            isLoggedIn = true
        }
    }
}

#Preview {
    LoginView()
}
