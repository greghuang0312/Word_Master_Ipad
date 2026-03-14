import Foundation

struct LibraryDeletionPrompt: Equatable {
    let title: String
    let message: String
    let confirmTitle: String

    init(word: WordItem) {
        self.title = "删除词条"
        self.message = "删除后不可恢复，确认删除“\(word.zhText) / \(word.enWord)”吗？"
        self.confirmTitle = "删除"
    }
}
