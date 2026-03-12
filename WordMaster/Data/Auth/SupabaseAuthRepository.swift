import Foundation

final class SupabaseAuthRepository: AuthRepository {
    private let config: SupabaseConfig
    private let sessionStore: SupabaseSessionStore
    private let urlSession: URLSession

    init(
        config: SupabaseConfig,
        sessionStore: SupabaseSessionStore = .shared,
        urlSession: URLSession = .shared
    ) {
        self.config = config
        self.sessionStore = sessionStore
        self.urlSession = urlSession
    }

    func signIn(email: String, password: String) async throws -> UserSession {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            throw AuthRepositoryError.invalidCredentials
        }

        var request = try makeRequest(path: "/auth/v1/token?grant_type=password", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(SignInRequest(email: normalizedEmail, password: password))

        let response: SignInResponse = try await send(request: request, decode: SignInResponse.self)
        guard let userId = UUID(uuidString: response.user.id) else {
            throw AuthRepositoryError.unsupportedInCurrentBuild
        }

        let session = UserSession(id: userId, email: response.user.email ?? normalizedEmail)
        await sessionStore.update(accessToken: response.accessToken, session: session)
        return session
    }

    func signOut() async throws {
        if let token = await sessionStore.currentAccessToken() {
            var request = try makeRequest(path: "/auth/v1/logout", method: "POST")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try await send(request: request, decode: EmptyResponse.self)
        }
        await sessionStore.clear()
    }

    func currentSession() async -> UserSession? {
        await sessionStore.currentSession()
    }

    private func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let baseURL = URL(string: config.urlString) else {
            throw AuthRepositoryError.missingSupabaseConfig
        }

        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw AuthRepositoryError.missingSupabaseConfig
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")

        return request
    }

    private func send<T: Decodable>(request: URLRequest, decode: T.Type) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthRepositoryError.unsupportedInCurrentBuild
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 400 || http.statusCode == 401 {
                throw AuthRepositoryError.invalidCredentials
            }
            throw AuthRepositoryError.unsupportedInCurrentBuild
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct SignInRequest: Encodable {
    let email: String
    let password: String
}

private struct SignInResponse: Decodable {
    let accessToken: String
    let user: SignInUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

private struct SignInUser: Decodable {
    let id: String
    let email: String?
}

private struct EmptyResponse: Decodable {
    init() {}
}
