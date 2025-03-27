import SwiftUI
import GoogleSignIn

struct GoogleSignInButton: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var rememberMe: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                authManager.signIn(rememberMe: rememberMe)
            }) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.white)
                    Text("Sign in with Google")
                        .foregroundColor(.white)
                        .font(.custom("Noto Sans", size: 18).bold())
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }
            
            // Remember Me checkbox
            Toggle(isOn: $rememberMe) {
                Text("Remember me")
                    .foregroundColor(.black)
                    .font(.custom("Noto Sans", size: 14))
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.blue))
            .padding(.horizontal, 16)
        }
    }
}
