import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var notice: String = ""

    private let context: AppContext
    private let apiKeyName = "deepseek_api_key"

    init(context: AppContext) {
        self.context = context
        self.apiKey = context.keychainStore.loadString(for: apiKeyName) ?? ""
    }

    var currentEmail: String {
        context.session?.email ?? "未登录"
    }

    func saveApiKey() {
        do {
            try context.keychainStore.saveString(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), for: apiKeyName)
            notice = "API Key 保存成功"
        } catch {
            notice = "保存失败：\(error.localizedDescription)"
        }
    }

    func clearApiKey() {
        context.keychainStore.deleteValue(for: apiKeyName)
        apiKey = ""
        notice = "API Key 已清除"
    }

    func logout() async {
        await context.signOut()
    }
}
