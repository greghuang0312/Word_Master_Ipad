import Foundation
import Combine

@MainActor
final class AddWordViewModel: ObservableObject {
    @Published var zhText: String = ""
    @Published var candidates: [String] = []
    @Published var selectedCandidate: String?
    @Published var manualEnglish: String = ""
    @Published var loading = false
    @Published var notice: String = ""
    @Published var completionMessage: String?

    private let context: AppContext
    private var completionDismissTask: Task<Void, Never>?
    private var autoQueryTask: Task<Void, Never>?

    init(context: AppContext) {
        self.context = context
    }

    deinit {
        completionDismissTask?.cancel()
        autoQueryTask?.cancel()
    }

    func scheduleAutoQuery() {
        autoQueryTask?.cancel()

        let prompt = zhText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            loading = false
            candidates = []
            selectedCandidate = nil
            return
        }

        autoQueryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            await self?.queryCandidates(autoTriggered: true)
        }
    }

    func queryCandidates() async {
        await queryCandidates(autoTriggered: false)
    }

    private func queryCandidates(autoTriggered: Bool) async {
        let prompt = zhText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            if !autoTriggered {
                notice = "请先输入中文词义"
            }
            return
        }

        let apiKey = context.keychainStore.loadString(for: DeepSeekSettings.apiKeyName) ?? ""
        guard !apiKey.isEmpty else {
            notice = "未配置 API Key，仍可手写英文后保存"
            candidates = []
            selectedCandidate = nil
            return
        }

        loading = true
        defer { loading = false }

        do {
            let result = try await context.deepSeekClient.generateCandidates(for: prompt, apiKey: apiKey)
            guard !Task.isCancelled else { return }
            guard prompt == zhText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

            candidates = result
            selectedCandidate = candidates.first
            notice = result.isEmpty ? "未返回候选词，可手写英文保存" : "请选择候选词，或手写更合适的英文"
        } catch {
            if error is CancellationError || Task.isCancelled { return }
            guard prompt == zhText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            candidates = []
            selectedCandidate = nil
            notice = "候选词查询失败，可手写英文保存：\(error.localizedDescription)"
        }
    }

    func save(today: Date = Date()) async {
        guard let userId = context.currentUserId else {
            notice = "请先登录"
            return
        }

        let zh = zhText.trimmingCharacters(in: .whitespacesAndNewlines)
        let picked = selectedCandidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let manual = manualEnglish.trimmingCharacters(in: .whitespacesAndNewlines)
        let english = !manual.isEmpty ? manual : picked

        guard !zh.isEmpty else {
            notice = "中文词义不能为空"
            return
        }
        guard !english.isEmpty else {
            notice = "请选择候选英文或手写英文"
            return
        }

        do {
            let result = try await context.wordRepository.upsertWord(
                userId: userId,
                zhText: zh,
                enWord: english,
                today: today
            )
            notice = result.merged ? "英文重复，已合并并重置到阶段 1" : ""
            resetInput(keepNotice: true)
            showCompletionPopup("已经添加完成")
        } catch {
            notice = "保存失败：\(error.localizedDescription)"
        }
    }

    func resetInput(keepNotice: Bool = false) {
        autoQueryTask?.cancel()
        zhText = ""
        candidates = []
        selectedCandidate = nil
        manualEnglish = ""
        loading = false
        if !keepNotice { notice = "" }
    }

    private func showCompletionPopup(_ message: String) {
        completionDismissTask?.cancel()
        completionMessage = message

        completionDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.completionMessage = nil
        }
    }
}
