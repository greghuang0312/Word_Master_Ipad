import Foundation

enum ReviewResult: Equatable {
    case known
    case unknown
}

struct ReviewStateTransition: Equatable {
    let stage: Int
    let nextReviewDate: Date
}

struct ReviewScheduler {
    // Stage 1...6 intervals: 1/2/4/7/15/30 days
    private let stageIntervals = [1, 2, 4, 7, 15, 30]
    private var calendar: Calendar

    init(calendar: Calendar? = nil) {
        if let calendar {
            self.calendar = calendar
        } else {
            var gmtCalendar = Calendar(identifier: .gregorian)
            gmtCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
            self.calendar = gmtCalendar
        }
    }

    func nextState(currentStage: Int, result: ReviewResult, today: Date) -> ReviewStateTransition {
        let normalizedStage = min(max(currentStage, 1), 6)

        switch result {
        case .unknown:
            let nextDate = addDays(1, to: today)
            return ReviewStateTransition(stage: 1, nextReviewDate: nextDate)
        case .known:
            let nextStage = min(normalizedStage + 1, 6)
            let intervalDays = stageIntervals[nextStage - 1]
            let nextDate = addDays(intervalDays, to: today)
            return ReviewStateTransition(stage: nextStage, nextReviewDate: nextDate)
        }
    }

    private func addDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
}
