import XCTest
@testable import WordMaster

final class ProfileApiKeyGuidanceTests: XCTestCase {
    func testHelperTextExplainsSkPrefixAndBearerRule() {
        let text = ProfileApiKeyGuidance.helperText

        XCTAssertTrue(text.contains("sk-"))
        XCTAssertTrue(text.contains("Bearer"))
        XCTAssertTrue(text.contains("完整 API Key"))
    }

    func testStatusTextMatchesSavedState() {
        XCTAssertEqual(ProfileApiKeyGuidance.statusText(hasSavedApiKey: true), "当前已保存可用 API Key")
        XCTAssertEqual(ProfileApiKeyGuidance.statusText(hasSavedApiKey: false), "当前尚未保存 API Key")
    }
}
