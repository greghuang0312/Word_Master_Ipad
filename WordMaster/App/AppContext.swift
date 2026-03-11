import Foundation
import Combine

@MainActor
final class AppContext: ObservableObject {
    static let shared = AppContext()

    @Published private(set) var session: UserSession?

    let authRepository: AuthRepository
    let wordRepository: WordRepository
    let deepSeekClient: DeepSeekClientProtocol
    let keychainStore: KeychainStore
    let reviewScheduler: ReviewScheduler

    init(
        authRepository: AuthRepository = AuthRepositoryFactory.makeDefault(),
        wordRepository: WordRepository = WordRepositoryFactory.makeDefault(),
        deepSeekClient: DeepSeekClientProtocol = DeepSeekClient(),
        keychainStore: KeychainStore = KeychainStore(service: "word.master"),
        reviewScheduler: ReviewScheduler = ReviewScheduler()
    ) {
        self.authRepository = authRepository
        self.wordRepository = wordRepository
        self.deepSeekClient = deepSeekClient
        self.keychainStore = keychainStore
        self.reviewScheduler = reviewScheduler
    }

    var currentUserId: UUID? { session?.id }
    var isAuthenticated: Bool { session != nil }

    func restoreSession() async {
        session = await authRepository.currentSession()
    }

    @discardableResult
    func signIn(email: String, password: String) async -> Bool {
        do {
            let signedIn = try await authRepository.signIn(email: email, password: password)
            session = signedIn
            return true
        } catch {
            return false
        }
    }

    func signOut() async {
        do {
            try await authRepository.signOut()
        } catch {
            // Best-effort sign out in UI flow
        }
        session = nil
    }
}
