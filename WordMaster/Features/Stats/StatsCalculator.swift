import Foundation

struct StatsSummary {
    let total: Int
    let inProgress: Int
    let overdue: Int
    let mastered: Int
}

struct StageDistributionItem: Identifiable {
    let stage: Int
    let count: Int
    var id: Int { stage }
}

struct TimelineItem: Identifiable {
    let stage: Int
    let daysAfterReview: Int
    var id: Int { stage }
}

struct StatsResult {
    let summary: StatsSummary
    let distribution: [StageDistributionItem]
    let timeline: [TimelineItem]
}

struct StatsCalculator {
    private let stageIntervals = [1, 2, 4, 7, 15, 30]

    func calculate(words: [WordItem], today: Date = Date()) -> StatsResult {
        let normalizedToday = Calendar.current.startOfDay(for: today)
        let mastered = words.filter(\.isMastered).count
        let overdue = words.filter { !($0.isMastered) && Calendar.current.startOfDay(for: $0.nextReviewDate) < normalizedToday }.count
        let total = words.count
        let inProgress = max(total - mastered, 0)

        let distribution = (1...6).map { stage in
            StageDistributionItem(stage: stage, count: words.filter { $0.stage == stage }.count)
        }

        let timeline = stageIntervals.enumerated().map { index, day in
            TimelineItem(stage: index + 1, daysAfterReview: day)
        }

        return StatsResult(
            summary: StatsSummary(total: total, inProgress: inProgress, overdue: overdue, mastered: mastered),
            distribution: distribution,
            timeline: timeline
        )
    }
}

