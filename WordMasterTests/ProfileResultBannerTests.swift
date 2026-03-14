import XCTest
@testable import WordMaster

final class ProfileResultBannerTests: XCTestCase {
    func testSuccessToneUsesCheckmarkIcon() {
        let banner = ProfileResultBanner(message: "Saved", tone: .success)

        XCTAssertEqual(banner.tone.iconSystemName, "checkmark.circle.fill")
    }

    func testErrorToneUsesXmarkIcon() {
        let banner = ProfileResultBanner(message: "Test failed", tone: .error)

        XCTAssertEqual(banner.tone.iconSystemName, "xmark.circle.fill")
    }
}
