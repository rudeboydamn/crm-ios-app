import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var userId = ""
    @State private var agreedToTerms = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("Join ValeCRM to manage your business")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Sign Up Form
                    VStack(spacing: 15) {
                        TextField("Full Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.name)
                        
                        TextField("Username", text: $userId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.username)
                            .autocapitalization(.none)
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.newPassword)
                        
                        // Password strength indicator
                        if !password.isEmpty {
                            PasswordStrengthView(password: password)
                        }
                        
                        // Terms and conditions
                        Toggle(isOn: $agreedToTerms) {
                            HStack(spacing: 4) {
                                Text("I agree to the")
                                    .font(.caption)
                                Button(action: {}) {
                                    Text("Terms & Conditions")
                                        .font(.caption)
                                        .underline()
                                }
                            }
                        }
                        
                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button(action: signUp) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 50)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(!isFormValid || authManager.isLoading)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !name.isEmpty &&
        !userId.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        agreedToTerms &&
        email.contains("@")
    }
    
    private func signUp() {
        Task {
            await authManager.signUp(
                email: email,
                password: password,
                name: name,
                userId: userId
            )
            
            // Dismiss on successful signup
            if authManager.isAuthenticated {
                dismiss()
            }
        }
    }
}

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.count < 6 {
            return .weak
        } else if password.count < 8 {
            return .medium
        } else if password.count >= 8 && containsNumbersAndSpecialChars {
            return .strong
        } else {
            return .medium
        }
    }
    
    private var containsNumbersAndSpecialChars: Bool {
        let numberRegex = ".*[0-9]+.*"
        let specialCharRegex = ".*[!@#$%^&*(),.?\":{}|<>]+.*"
        
        let hasNumber = password.range(of: numberRegex, options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: specialCharRegex, options: .regularExpression) != nil
        
        return hasNumber && hasSpecialChar
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Rectangle()
                    .fill(index < strength.level ? strength.color : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .overlay(
            Text(strength.text)
                .font(.caption2)
                .foregroundColor(strength.color)
                .padding(.top, 8),
            alignment: .bottom
        )
    }
}

enum PasswordStrength {
    case weak
    case medium
    case strong
    
    var level: Int {
        switch self {
        case .weak: return 1
        case .medium: return 2
        case .strong: return 3
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    var text: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
}
