import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var words: [WordItem] = []
    @Published var notice: String = ""
    @Published var loading = false

    private let context: AppContext

    init(context: AppContext) {
        self.context = context
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
        }
    }

    func deleteWord(at offsets: IndexSet) async {
        guard let userId = context.currentUserId else { return }
        do {
            for offset in offsets {
                let id = words[offset].id
                try await context.wordRepository.deleteWord(userId: userId, wordId: id)
            }
            words.remove(atOffsets: offsets)
            notice = "删除成功"
        } catch {
            notice = "删除失败：\(error.localizedDescription)"
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
