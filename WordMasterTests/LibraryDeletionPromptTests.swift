import XCTest
@testable import WordMaster

final class LibraryDeletionPromptTests: XCTestCase {
    func testPromptUsesWordContentInConfirmActionAndMessage() {
        let word = WordItem(
            userId: UUID(),
            zhText: "苹果",
            enWord: "apple",
            nextReviewDate: Date()
        )

        let prompt = LibraryDeletionPrompt(word: word)

        XCTAssertEqual(prompt.title, "删除词条")
        XCTAssertEqual(prompt.confirmTitle, "删除")
        XCTAssertTrue(prompt.message.contains("苹果"))
        XCTAssertTrue(prompt.message.contains("apple"))
    }
}
