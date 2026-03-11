import Foundation

#if canImport(Security)
import Security
#endif

final class KeychainStore {
    private let service: String

#if !canImport(Security)
    private var fallbackStore: [String: String] = [:]
#endif

    init(service: String) {
        self.service = service
    }

    func saveString(_ value: String, for key: String) throws {
#if canImport(Security)
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        let attrs: [String: Any] = query.merging([
            kSecValueData as String: data
        ]) { _, new in new }
        let status = SecItemAdd(attrs as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainStore", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "保存 Keychain 失败"])
        }
#else
        fallbackStore[key] = value
#endif
    }

    func loadString(for key: String) -> String? {
#if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        guard let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
#else
        return fallbackStore[key]
#endif
    }

    func deleteValue(for key: String) {
#if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
#else
        fallbackStore.removeValue(forKey: key)
#endif
    }
}

