import SwiftUI
import GoogleSignIn

class AuthenticationManager: ObservableObject {
    @Published var user: GIDGoogleUser?
    @Published var isAuthenticated = false
    
    // Client ID from the GoogleService-Info.plist
    private let clientID = "601560301211-k7uqv0rph1c0t9kiu6e2eslrg1ba4ufj.apps.googleusercontent.com"
    
    // Key for storing authentication state
    private let rememberMeKey = "lotcation_remember_me"
    private let userIdKey = "lotcation_user_id"
    
    init() {
        // Check for remembered login on initialization
        checkSavedCredentials()
    }
    
    func checkSavedCredentials() {
        // Check if user opted to be remembered
        if UserDefaults.standard.bool(forKey: rememberMeKey) {
            // Try to restore the session
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                guard let self = self else { return }
                
                if let user = user, error == nil {
                    self.user = user
                    self.isAuthenticated = true
                    print("User session restored: \(user.profile?.name ?? "Unknown user")")
                } else if let error = error {
                    print("Failed to restore session: \(error.localizedDescription)")
                    // Clear saved credentials if restore fails
                    self.clearSavedCredentials()
                }
            }
        }
    }
    
    func signIn(rememberMe: Bool = false) {
        // Create Google Sign In configuration object
        let config = GIDConfiguration(clientID: clientID)
        // Assign the configuration to the shared instance
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("No root view controller found")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: []) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Sign in error: \(error.localizedDescription)")
                return
            }
            
            guard let result = result else { return }
            
            self.user = result.user
            self.isAuthenticated = true
            
            // Store remember me preference
            UserDefaults.standard.set(rememberMe, forKey: self.rememberMeKey)
            
            // Store user ID if remember me is selected
            if rememberMe {
                UserDefaults.standard.set(result.user.userID, forKey: self.userIdKey)
            }
            
            // Store user name in UserDefaults for personalization
            if let profile = result.user.profile {
                let userName = profile.name
                UserDefaults.standard.set(userName, forKey: "userName")
                print("User signed in: \(userName)")
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        user = nil
        isAuthenticated = false
        
        // Clear user data from UserDefaults
        clearSavedCredentials()
        
        print("User signed out")
    }
    
    private func clearSavedCredentials() {
        UserDefaults.standard.removeObject(forKey: rememberMeKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: "userName")
    }
}
