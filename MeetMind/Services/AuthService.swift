import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isSignedIn = false
    @Published var isLoading = true
    @Published var userProfile = UserProfile.load()
    @Published var signInError: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isSignedIn = user != nil
                self?.isLoading = false
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        signInError = nil

        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            signInError = "Unable to find root view controller."
            return
        }
        #elseif os(macOS)
        guard let window = NSApplication.shared.keyWindow else {
            signInError = "Unable to find key window."
            return
        }
        #endif

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            signInError = "Firebase not configured. Missing GoogleService-Info.plist."
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            #if os(iOS)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            #elseif os(macOS)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            #endif
            guard let idToken = result.user.idToken?.tokenString else {
                signInError = "Missing ID token from Google."
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            self.currentUser = authResult.user
            self.isSignedIn = true
        } catch {
            signInError = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
            isSignedIn = false
        } catch {
            signInError = error.localizedDescription
        }
    }

    // MARK: - Continue Without Account

    func continueWithoutAccount() {
        Task {
            do {
                let result = try await Auth.auth().signInAnonymously()
                self.currentUser = result.user
                self.isSignedIn = true
            } catch {
                self.isSignedIn = true
                self.isLoading = false
            }
        }
    }

    // MARK: - Profile Management

    func updateProfile(_ profile: UserProfile) {
        self.userProfile = profile
        profile.save()
    }

    var displayName: String {
        currentUser?.displayName ?? "User"
    }

    var email: String {
        currentUser?.email ?? ""
    }

    var photoURL: URL? {
        currentUser?.photoURL
    }

    var isAnonymous: Bool {
        currentUser?.isAnonymous ?? true
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        try await currentUser?.delete()
        UserProfile().save()
        UserDefaults.standard.removeObject(forKey: "meetmind_user_profile")
        currentUser = nil
        isSignedIn = false
    }
}
