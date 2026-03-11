import XCTest
@testable import WordMaster

final class ReviewSchedulerTests: XCTestCase {
    func testUnknownResetsToStage1AndTomorrow() {
        let scheduler = ReviewScheduler()
        let today = TestDate.makeDate("2026-03-11")

        let result = scheduler.nextState(currentStage: 4, result: .unknown, today: today)

        XCTAssertEqual(result.stage, 1)
        XCTAssertEqual(TestDate.formatDate(result.nextReviewDate), "2026-03-12")
    }

    func testKnownMovesToNextStageWithConfiguredInterval() {
        let scheduler = ReviewScheduler()
        let today = TestDate.makeDate("2026-03-11")

        let result = scheduler.nextState(currentStage: 2, result: .known, today: today)

        XCTAssertEqual(result.stage, 3)
        XCTAssertEqual(TestDate.formatDate(result.nextReviewDate), "2026-03-15")
    }

    func testKnownAtMaxStageKeepsStageSix() {
        let scheduler = ReviewScheduler()
        let today = TestDate.makeDate("2026-03-11")

        let result = scheduler.nextState(currentStage: 6, result: .known, today: today)

        XCTAssertEqual(result.stage, 6)
        XCTAssertEqual(TestDate.formatDate(result.nextReviewDate), "2026-04-10")
    }
}

private enum TestDate {
    static func makeDate(_ yyyyMMdd: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: yyyyMMdd)!
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

