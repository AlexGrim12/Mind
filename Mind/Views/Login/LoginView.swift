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
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.14),
                    Color(red: 0.10, green: 0.08, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Brand header
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.indigo.opacity(0.18))
                            .frame(width: 96, height: 96)
                        Circle()
                            .stroke(Color.indigo.opacity(0.35), lineWidth: 1)
                            .frame(width: 96, height: 96)
                        Image(systemName: "brain.filled.head.profile")
                            .font(.system(size: 42, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.indigo, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    VStack(spacing: 4) {
                        Text("MIND-LINK")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Sistema de Bienestar Universitario")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 44)

                // MARK: Form card
                VStack(spacing: 20) {
                    // Username field
                    VStack(alignment: .leading, spacing: 7) {
                        Text("MATRÍCULA / CÉDULA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(1.0)

                        HStack(spacing: 14) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(focusedField == .username ? Color.indigo : Color.white.opacity(0.4))
                                .frame(width: 22)
                                .animation(.easeInOut(duration: 0.2), value: focusedField)

                            TextField("Ingresa tu usuario", text: $username)
                                .focused($focusedField, equals: .username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(.white)
                                .tint(Color.indigo)
                                .onSubmit { focusedField = .password }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .background(.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    focusedField == .username ? Color.indigo : Color.white.opacity(0.1),
                                    lineWidth: focusedField == .username ? 1.5 : 1
                                )
                        )
                        .animation(.easeInOut(duration: 0.2), value: focusedField)
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 7) {
                        Text("CONTRASEÑA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(1.0)

                        HStack(spacing: 14) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(focusedField == .password ? Color.indigo : Color.white.opacity(0.4))
                                .frame(width: 22)
                                .animation(.easeInOut(duration: 0.2), value: focusedField)

                            SecureField("Ingresa tu contraseña", text: $password)
                                .focused($focusedField, equals: .password)
                                .foregroundStyle(.white)
                                .tint(Color.indigo)
                                .onSubmit { attemptLogin() }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .background(.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    focusedField == .password ? Color.indigo : Color.white.opacity(0.1),
                                    lineWidth: focusedField == .password ? 1.5 : 1
                                )
                        )
                        .animation(.easeInOut(duration: 0.2), value: focusedField)
                    }

                    // Error message
                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.subheadline)
                            Text("Credenciales incorrectas. Inténtalo de nuevo.")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }

                    // Login button
                    Button(action: attemptLogin) {
                        ZStack {
                            LinearGradient(
                                colors: [Color.indigo, Color(red: 0.5, green: 0.2, blue: 0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.1)
                            } else {
                                HStack(spacing: 10) {
                                    Text("Iniciar Sesión")
                                        .font(.system(size: 16, weight: .bold))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 16))
                                }
                                .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .shadow(color: Color.indigo.opacity(0.45), radius: 14, x: 0, y: 7)
                    }
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
                    .opacity((username.isEmpty || password.isEmpty) ? 0.55 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: username.isEmpty || password.isEmpty)
                    .padding(.top, 4)
                }
                .padding(24)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.09), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Spacer()

                // Footer
                VStack(spacing: 6) {
                    Label("Portal seguro · Datos locales", systemImage: "lock.shield.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.25))
                    Text("UANL · MIND-LINK v1.0")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.18))
                }
                .padding(.bottom, 36)
            }
        }
        .animation(.smooth, value: showError)
        .contentShape(Rectangle())
        .onTapGesture { focusedField = nil }
    }

    private func attemptLogin() {
        guard !username.isEmpty, !password.isEmpty else { return }
        focusedField = nil
        isLoading = true
        showError = false

        // Simulated auth: "doctor" → clinician role, anyone else → patient role
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            isLoading = false
            userRole = username.lowercased() == "doctor" ? "doctor" : "patient"
            isLoggedIn = true
        }
    }
}

#Preview {
    LoginView()
}
