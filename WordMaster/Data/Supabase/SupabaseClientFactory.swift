import Foundation

struct SupabaseConfig {
    let urlString: String
    let anonKey: String

    var isValid: Bool {
        URL(string: urlString) != nil && !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum SupabaseClientFactory {
    static func loadConfig() -> SupabaseConfig? {
        let env = ProcessInfo.processInfo.environment
        let url = env["SUPABASE_URL"] ?? ""
        let key = env["SUPABASE_ANON_KEY"] ?? ""
        let config = SupabaseConfig(urlString: url, anonKey: key)
        return config.isValid ? config : nil
    }
}

