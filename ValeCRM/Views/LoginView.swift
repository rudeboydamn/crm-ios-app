import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Logo/Branding
                Image(systemName: brandSymbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)
                
                Text("ValeCRM")
                    .font(.system(size: 40, weight: .bold))
                
                Text("Manage your real estate business")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Login Form
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                    
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: {
                        Task {
                            await authManager.signIn(email: email, password: password)
                        }
                    }) {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                    
                    Button(action: {
                        Task {
                            do {
                                try await authManager.authenticateWithBiometrics()
                            } catch {
                                authManager.errorMessage = error.localizedDescription
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("Sign In with Face ID")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showSignUp = true }) {
                        Text("Sign Up")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authManager)
            }
        }
    }
    
    private var brandSymbolName: String {
        return "house.circle.fill"
    }
}
