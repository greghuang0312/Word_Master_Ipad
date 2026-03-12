import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var notice: String = ""
    @Published var testing = false

    private let context: AppContext

    init(context: AppContext) {
        self.context = context
        self.apiKey = context.keychainStore.loadString(for: DeepSeekSettings.apiKeyName) ?? ""
    }

    var currentEmail: String {
        context.session?.email ?? "未登录"
    }

    func saveApiKey() {
        do {
            try context.keychainStore.saveString(
                apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                for: DeepSeekSettings.apiKeyName
            )
            notice = "API Key 保存成功"
        } catch {
            notice = "保存失败：\(error.localizedDescription)"
        }
    }

    func clearApiKey() {
        context.keychainStore.deleteValue(for: DeepSeekSettings.apiKeyName)
        apiKey = ""
        notice = "API Key 已清除"
    }

    func testApiKey() async {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            notice = "请先输入 API Key"
            return
        }

        testing = true
        defer { testing = false }

        do {
            let candidates = try await context.deepSeekClient.generateCandidates(
                for: DeepSeekSettings.connectivityProbeText,
                apiKey: trimmed
            )
            notice = candidates.isEmpty ? "API Key 可用，但未返回候选词" : "DeepSeek 连接正常，请先保存 API Key"
        } catch {
            notice = "DeepSeek 验证失败：\(error.localizedDescription)"
        }
    }

    func logout() async {
        await context.signOut()
    }
}
