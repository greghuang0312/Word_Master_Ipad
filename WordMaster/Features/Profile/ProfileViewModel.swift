import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var notice: String = ""
    @Published var testing = false
    @Published private(set) var hasSavedApiKey = false
    @Published var resultBannerMessage: String?

    private let context: AppContext
    private var resultDismissTask: Task<Void, Never>?

    init(context: AppContext) {
        self.context = context
        self.apiKey = context.keychainStore.loadString(for: DeepSeekSettings.apiKeyName) ?? ""
        self.hasSavedApiKey = !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    deinit {
        resultDismissTask?.cancel()
    }

    var currentEmail: String {
        context.session?.email ?? "未登录"
    }

    func saveApiKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showResult("API Key 不能为空")
            return
        }

        do {
            try persistApiKey(trimmed)
            showResult("API Key 保存成功")
        } catch {
            showResult("保存失败：\(error.localizedDescription)")
        }
    }

    func clearApiKey() {
        context.keychainStore.deleteValue(for: DeepSeekSettings.apiKeyName)
        apiKey = ""
        hasSavedApiKey = false
        showResult("API Key 已清除")
    }

    func testApiKey() async {
        let typed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let saved = context.keychainStore.loadString(for: DeepSeekSettings.apiKeyName)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let keyToTest: String
        if !typed.isEmpty {
            keyToTest = typed
        } else if !saved.isEmpty {
            keyToTest = saved
            apiKey = saved
        } else {
            showResult("请先输入 API Key")
            return
        }

        testing = true
        defer { testing = false }

        do {
            _ = try await context.deepSeekClient.generateCandidates(
                for: DeepSeekSettings.connectivityProbeText,
                apiKey: keyToTest
            )
            try persistApiKey(keyToTest)
            showResult("测试成功，已保存API")
        } catch {
            showResult("测试错误")
        }
    }

    func testAndSaveApiKey() async {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showResult("请先输入 API Key")
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
            showResult("测试成功，已保存API")
        } catch {
            showResult("测试错误")
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
        apiKey = key
        hasSavedApiKey = true
    }

    private func showResult(_ message: String) {
        notice = message
        resultDismissTask?.cancel()
        resultBannerMessage = message

        resultDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.resultBannerMessage = nil
        }
    }
}
