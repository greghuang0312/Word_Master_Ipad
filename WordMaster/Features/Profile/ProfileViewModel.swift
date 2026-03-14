import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var notice: String = ""
    @Published var testing = false
    @Published private(set) var hasSavedApiKey = false
    @Published var resultBanner: ProfileResultBanner?

    private let context: AppContext
    private var resultDismissTask: Task<Void, Never>?

    init(context: AppContext) {
        self.context = context
        let savedKey = context.keychainStore.loadString(for: DeepSeekSettings.apiKeyName) ?? ""
        self.hasSavedApiKey = !savedKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    deinit {
        resultDismissTask?.cancel()
    }

    var currentEmail: String {
        context.session?.email ?? "未登录"
    }

    func clearApiKey() {
        context.keychainStore.deleteValue(for: DeepSeekSettings.apiKeyName)
        apiKey = ""
        hasSavedApiKey = false
        showResult("API Key 已清除")
    }

    func testAndSaveApiKey() async {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showResult("请输入 API Key", tone: .error)
            return
        }

        testing = true
        defer { testing = false }

        do {
            _ = try await context.deepSeekClient.generateCandidates(
                for: DeepSeekSettings.connectivityProbeText,
                apiKey: trimmed
            )
            try persistApiKey(trimmed)
            apiKey = ""
            showResult("测试成功，已保存 API")
        } catch {
            showResult(error.localizedDescription, tone: .error)
        }
    }

    func logout() async {
        await context.signOut()
    }

    private func persistApiKey(_ key: String) throws {
        try context.keychainStore.saveString(key, for: DeepSeekSettings.apiKeyName)
        let persisted = context.keychainStore.loadString(for: DeepSeekSettings.apiKeyName) ?? ""
        guard persisted == key else {
            throw NSError(
                domain: "ProfileViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "写入后校验失败，请重试"]
            )
        }
        hasSavedApiKey = true
    }

    private func showResult(_ message: String, tone: ProfileResultBanner.Tone = .success) {
        notice = message
        resultDismissTask?.cancel()
        resultBanner = ProfileResultBanner(message: message, tone: tone)

        resultDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.resultBanner = nil
        }
    }
}
