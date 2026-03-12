import Foundation

actor SupabaseSessionStore {
    static let shared = SupabaseSessionStore()

    private enum Keys {
        static let accessToken = "supabase_access_token"
        static let userId = "supabase_user_id"
        static let email = "supabase_user_email"
    }

    private var loaded = false
    private var accessToken: String?
    private var userSession: UserSession?

    func currentSession() -> UserSession? {
        loadIfNeeded()
        return userSession
    }

    func currentAccessToken() -> String? {
        loadIfNeeded()
        return accessToken
    }

    func update(accessToken: String, session: UserSession) {
        self.accessToken = accessToken
        self.userSession = session
        loaded = true

        let defaults = UserDefaults.standard
        defaults.set(accessToken, forKey: Keys.accessToken)
        defaults.set(session.id.uuidString, forKey: Keys.userId)
        defaults.set(session.email, forKey: Keys.email)
    }

    func clear() {
        accessToken = nil
        userSession = nil
        loaded = true

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.accessToken)
        defaults.removeObject(forKey: Keys.userId)
        defaults.removeObject(forKey: Keys.email)
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true

        let defaults = UserDefaults.standard
        guard
            let token = defaults.string(forKey: Keys.accessToken),
            let userIdRaw = defaults.string(forKey: Keys.userId),
            let userId = UUID(uuidString: userIdRaw),
            let email = defaults.string(forKey: Keys.email)
        else {
            return
        }

        accessToken = token
        userSession = UserSession(id: userId, email: email)
    }
}
