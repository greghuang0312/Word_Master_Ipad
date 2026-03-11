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

    private let context: AppContext
    private let apiKeyName = "deepseek_api_key"

    init(context: AppContext) {
        self.context = context
    }

    func queryCandidates() async {
        let prompt = zhText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            notice = "请先输入中文词义"
            return
        }

        let apiKey = context.keychainStore.loadString(for: apiKeyName) ?? ""
        guard !apiKey.isEmpty else {
            notice = "未配置 API Key，仍可手写英文后保存"
            candidates = []
            return
        }

        loading = true
        defer { loading = false }

        do {
            let result = try await context.deepSeekClient.generateCandidates(for: prompt, apiKey: apiKey)
            candidates = result
            selectedCandidate = candidates.first
            notice = result.isEmpty ? "未返回候选词，可手写英文保存" : "请选择候选词，或手写更合适英文"
        } catch {
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
            notice = result.merged ? "英文重复，已合并更新并重置到阶段1" : "保存成功，首次复习日期为明天"
            resetInput(keepNotice: true)
        } catch {
            notice = "保存失败：\(error.localizedDescription)"
        }
    }

    func resetInput(keepNotice: Bool = false) {
        zhText = ""
        candidates = []
        selectedCandidate = nil
        manualEnglish = ""
        if !keepNotice { notice = "" }
    }
}
