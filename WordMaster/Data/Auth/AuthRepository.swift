import Foundation

enum AuthRepositoryError: LocalizedError {
    case invalidCredentials
    case missingSupabaseConfig
    case unsupportedInCurrentBuild

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "账号或密码无效"
        case .missingSupabaseConfig:
            return "缺少 Supabase 配置"
        case .unsupportedInCurrentBuild:
            return "当前构建不支持 Supabase 接入"
        }
    }
}

protocol AuthRepository: AnyObject {
    func signIn(email: String, password: String) async throws -> UserSession
    func signOut() async throws
    func currentSession() async -> UserSession?
}

enum AuthRepositoryFactory {
    static func makeDefault() -> AuthRepository {
        if let config = SupabaseClientFactory.loadConfig() {
            return SupabaseAuthRepository(config: config)
        }
        return InMemoryAuthRepository()
    }
}

actor InMemoryAuthRepository: AuthRepository {
    private var cachedSession: UserSession?

    func signIn(email: String, password: String) async throws -> UserSession {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            throw AuthRepositoryError.invalidCredentials
        }

        let userId = UUID()
        let session = UserSession(id: userId, email: normalizedEmail)
        cachedSession = session
        return session
    }

    func signOut() async throws {
        cachedSession = nil
    }

    func currentSession() async -> UserSession? {
        cachedSession
    }
}
