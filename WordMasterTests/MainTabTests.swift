import XCTest
@testable import WordMaster

final class MainTabTests: XCTestCase {
    func testAllTabsExposeExpectedTitlesAndIcons() {
        XCTAssertEqual(MainTab.allCases.map(\.title), ["复习", "添加", "库", "统计", "我的"])
        XCTAssertEqual(
            MainTab.allCases.map(\.systemImage),
            ["book", "plus.circle", "books.vertical", "chart.bar", "person.crop.circle"]
        )
    }

    func testReloadsOnActivatePolicyMatchesContentTabs() {
        XCTAssertTrue(MainTab.review.reloadsOnActivate)
        XCTAssertTrue(MainTab.library.reloadsOnActivate)
        XCTAssertTrue(MainTab.stats.reloadsOnActivate)
        XCTAssertFalse(MainTab.add.reloadsOnActivate)
        XCTAssertFalse(MainTab.profile.reloadsOnActivate)
    }
}
