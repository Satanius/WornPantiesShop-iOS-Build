import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct WornPantiesShopIOSApp: App {
    @UIApplicationDelegateAdaptor(IOSAppDelegate.self)
    private var appDelegate

    @State private var authenticated: Bool

    init() {
        FirebaseApp.configure()
        _authenticated = State(initialValue: Auth.auth().currentUser != nil)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authenticated {
                    MainIOSView {
                        Task { @MainActor in
                            await IOSPushNotifications
                                .clearCurrentTokenForCurrentUser()

                            do {
                                try Auth.auth().signOut()
                                authenticated = false
                            } catch {
                            }
                        }
                    }
                } else {
                    AuthView {
                        authenticated = true
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
