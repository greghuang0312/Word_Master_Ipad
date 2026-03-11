import Foundation

struct WordItem: Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var zhText: String
    var enWord: String
    var stage: Int
    var nextReviewDate: Date
    var isMastered: Bool

    init(
        id: UUID = UUID(),
        userId: UUID,
        zhText: String,
        enWord: String,
        stage: Int = 1,
        nextReviewDate: Date,
        isMastered: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.zhText = zhText
        self.enWord = enWord
        self.stage = stage
        self.nextReviewDate = nextReviewDate
        self.isMastered = isMastered
    }
}
