import Foundation
import Combine

@MainActor
final class ReviewViewModel: ObservableObject {
    @Published private(set) var queue: [WordItem] = []
    @Published private(set) var currentIndex: Int = 0
    @Published var showEnglish: Bool = false
    @Published var notice: String = ""
    @Published private(set) var loading = false

    private let context: AppContext

    init(context: AppContext) {
        self.context = context
    }

    var currentWord: WordItem? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var progressText: String {
        guard !queue.isEmpty else { return "今日无待复习" }
        return "\(currentIndex + 1)/\(queue.count)"
    }

    func loadQueue(today: Date = Date()) async {
        guard let userId = context.currentUserId else {
            notice = "请先登录"
            return
        }
        loading = true
        defer { loading = false }

        do {
            queue = try await context.wordRepository.fetchDueWords(userId: userId, today: today)
            currentIndex = 0
            showEnglish = false
            notice = queue.isEmpty ? "今天没有需要复习的单词" : ""
        } catch {
            notice = "加载复习队列失败：\(error.localizedDescription)"
        }
    }

    func revealEnglish() {
        showEnglish = true
    }

    func tapCard(today: Date = Date()) async {
        guard let current = currentWord, let userId = context.currentUserId else { return }
        let result: ReviewResult = showEnglish ? .unknown : .known

        do {
            let updated = try await context.wordRepository.applyReview(
                userId: userId,
                wordId: current.id,
                result: result,
                today: today,
                scheduler: context.reviewScheduler
            )
            queue[currentIndex] = updated
            moveToNextCard()
        } catch {
            notice = "保存复习结果失败：\(error.localizedDescription)"
        }
    }

    private func moveToNextCard() {
        showEnglish = false
        let next = currentIndex + 1
        if next < queue.count {
            currentIndex = next
        } else {
            queue = []
            currentIndex = 0
            notice = "已完成今日复习队列"
        }
    }
}
