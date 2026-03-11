import Foundation
import Combine

enum AppRoute: Equatable {
    case login
    case mainTabs
}

@MainActor
final class AppRouter: ObservableObject {
    @Published private(set) var isAuthenticated: Bool

    var currentRoute: AppRoute {
        isAuthenticated ? .mainTabs : .login
    }

    init(isAuthenticated: Bool = false) {
        self.isAuthenticated = isAuthenticated
    }

    func setAuthenticated(_ authenticated: Bool) {
        isAuthenticated = authenticated
    }
}
