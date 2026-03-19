import SwiftUI

@main
struct WordMasterApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var context = AppContext.shared

    var body: some Scene {
        WindowGroup {
            Group {
                switch router.currentRoute {
                case .login:
                    LoginView { email, password in
                        let success = await context.signIn(email: email, password: password)
                        if success {
                            router.setAuthenticated(true)
                        }
                        return success
                    }
                case .mainTabs:
                    MainTabView()
                }
            }
            .environmentObject(context)
            .task {
                await context.restoreSession()
                router.setAuthenticated(context.isAuthenticated)
            }
            .onChangeCompat(of: context.isAuthenticated) { isAuthenticated in
                router.setAuthenticated(isAuthenticated)
            }
        }
    }
}
