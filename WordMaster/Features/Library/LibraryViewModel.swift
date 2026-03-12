import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var words: [WordItem] = []
    @Published private(set) var deletingWordIds: Set<UUID> = []
    @Published var notice: String = ""
    @Published var loading = false
    @Published var feedbackMessage: String?

    private let context: AppContext
    private var feedbackDismissTask: Task<Void, Never>?

    init(context: AppContext) {
        self.context = context
    }

    deinit {
        feedbackDismissTask?.cancel()
    }

    func loadWords() async {
        guard let userId = context.currentUserId else {
            notice = "请先登录"
            return
        }
        loading = true
        defer { loading = false }

        do {
            let fetchedWords = try await context.wordRepository.fetchAllWords(userId: userId)
            words = sortLibraryWords(fetchedWords)
            notice = words.isEmpty ? "词库为空，请先添加词条" : ""
        } catch {
            notice = "加载词库失败：\(error.localizedDescription)"
            showFeedback(notice)
        }
    }

    func deleteWord(at offsets: IndexSet) async {
        let ids = offsets.compactMap { index in
            words.indices.contains(index) ? words[index].id : nil
        }

        for id in ids {
            await deleteWord(id: id)
        }
    }

    func deleteWord(id: UUID) async {
        guard let userId = context.currentUserId else {
            notice = "请先登录"
            showFeedback(notice)
            return
        }
        guard !deletingWordIds.contains(id) else { return }

        deletingWordIds.insert(id)
        defer { deletingWordIds.remove(id) }

        do {
            try await context.wordRepository.deleteWord(userId: userId, wordId: id)
            words.removeAll { $0.id == id }
            notice = words.isEmpty ? "词库为空，请先添加词条" : ""
            showFeedback("删除成功")
        } catch {
            notice = "删除失败：\(error.localizedDescription)"
            showFeedback(notice)
        }
    }

    private func showFeedback(_ message: String) {
        feedbackDismissTask?.cancel()
        feedbackMessage = message

        feedbackDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.feedbackMessage = nil
        }
    }

    private func sortLibraryWords(_ words: [WordItem]) -> [WordItem] {
        words.sorted { lhs, rhs in
            if lhs.stage != rhs.stage {
                return lhs.stage < rhs.stage
            }

            let lhsInitial = chineseInitialSortKey(lhs.zhText)
            let rhsInitial = chineseInitialSortKey(rhs.zhText)
            if lhsInitial != rhsInitial {
                return lhsInitial < rhsInitial
            }

            if lhs.zhText != rhs.zhText {
                return lhs.zhText.localizedCompare(rhs.zhText) == .orderedAscending
            }

            return lhs.enWord.localizedCaseInsensitiveCompare(rhs.enWord) == .orderedAscending
        }
    }

    private func chineseInitialSortKey(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstChar = trimmed.first else { return "{" }

        let mutable = NSMutableString(string: String(firstChar))
        CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutable, nil, kCFStringTransformStripCombiningMarks, false)

        let transformed = (mutable as String)
            .uppercased()
            .filter(\.isLetter)

        guard let initial = transformed.first else { return "{" }
        return String(initial)
    }
}
