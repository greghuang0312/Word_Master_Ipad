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
            words = try await context.wordRepository.fetchAllWords(userId: userId)
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
}
