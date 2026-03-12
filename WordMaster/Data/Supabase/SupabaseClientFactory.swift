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
        let info = Bundle.main.infoDictionary ?? [:]

        let url = firstNonEmpty([
            env["SUPABASE_URL"],
            info["SUPABASE_URL"] as? String,
            SupabaseLocalConfig.url
        ]) ?? ""

        let key = firstNonEmpty([
            env["SUPABASE_ANON_KEY"],
            env["SUPABASE_PUBLISHABLE_KEY"],
            info["SUPABASE_ANON_KEY"] as? String,
            info["SUPABASE_PUBLISHABLE_KEY"] as? String,
            SupabaseLocalConfig.anonKey
        ]) ?? ""

        let config = SupabaseConfig(urlString: url, anonKey: key)
        return config.isValid ? config : nil
    }

    private static func firstNonEmpty(_ candidates: [String?]) -> String? {
        for value in candidates {
            if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }
}

