import XCTest
@testable import WordMaster

@MainActor
final class ReviewViewModelTests: XCTestCase {
    func testTapCardWhenEnglishHiddenStartsKnownTransitionAndResetsRevealOnAdvance() async {
        let userId = UUID()
        let first = WordItem(
            id: UUID(),
            userId: userId,
            zhText: "苹果",
            enWord: "apple",
            stage: 1,
            nextReviewDate: Date(timeIntervalSince1970: 0)
        )
        let second = WordItem(
            id: UUID(),
            userId: userId,
            zhText: "香蕉",
            enWord: "banana",
            stage: 2,
            nextReviewDate: Date(timeIntervalSince1970: 0)
        )
        let repository = ReviewQueueWordRepository(
            dueWords: [first, second],
            appliedWords: [
                WordItem(
                    id: first.id,
                    userId: userId,
                    zhText: "苹果",
                    enWord: "apple",
                    stage: 2,
                    nextReviewDate: Date(timeIntervalSince1970: 86_400 * 2)
                )
            ]
        )
        let viewModel = await makeViewModel(userId: userId, wordRepository: repository)

        await viewModel.loadQueue(today: Date(timeIntervalSince1970: 0))
        await viewModel.tapCard(today: Date(timeIntervalSince1970: 0))

        XCTAssertTrue(viewModel.isTransitioningToNextCard)
        XCTAssertEqual(await repository.appliedResults, [.known])
        XCTAssertEqual(viewModel.currentWord?.id, first.id)

        viewModel.completeCardTransition()

        XCTAssertFalse(viewModel.showEnglish)
        XCTAssertFalse(viewModel.isTransitioningToNextCard)
        XCTAssertEqual(viewModel.currentWord?.id, second.id)
        XCTAssertEqual(viewModel.progressText, "2/2")
    }

    func testTapCardAfterRevealStartsUnknownTransitionAndAdvancesToNextWord() async {
        let userId = UUID()
        let first = WordItem(
            id: UUID(),
            userId: userId,
            zhText: "苹果",
            enWord: "apple",
            stage: 3,
            nextReviewDate: Date(timeIntervalSince1970: 0)
        )
        let second = WordItem(
            id: UUID(),
            userId: userId,
            zhText: "香蕉",
            enWord: "banana",
            stage: 2,
            nextReviewDate: Date(timeIntervalSince1970: 0)
        )
        let repository = ReviewQueueWordRepository(
            dueWords: [first, second],
            appliedWords: [
                WordItem(
                    id: first.id,
                    userId: userId,
                    zhText: "苹果",
                    enWord: "apple",
                    stage: 1,
                    nextReviewDate: Date(timeIntervalSince1970: 86_400)
                )
            ]
        )
        let viewModel = await makeViewModel(userId: userId, wordRepository: repository)

        await viewModel.loadQueue(today: Date(timeIntervalSince1970: 0))
        viewModel.revealEnglish()

        await viewModel.tapCard(today: Date(timeIntervalSince1970: 0))

        XCTAssertTrue(viewModel.isTransitioningToNextCard)
        XCTAssertEqual(await repository.appliedResults, [.unknown])

        viewModel.completeCardTransition()

        XCTAssertFalse(viewModel.showEnglish)
        XCTAssertEqual(viewModel.currentWord?.id, second.id)
    }

    func testTapCardOnFinalWordCompletesQueueWithoutTransitionState() async {
        let userId = UUID()
        let onlyWord = WordItem(
            id: UUID(),
            userId: userId,
            zhText: "苹果",
            enWord: "apple",
            stage: 1,
            nextReviewDate: Date(timeIntervalSince1970: 0)
        )
        let repository = ReviewQueueWordRepository(
            dueWords: [onlyWord],
            appliedWords: [
                WordItem(
                    id: onlyWord.id,
                    userId: userId,
                    zhText: "苹果",
                    enWord: "apple",
                    stage: 2,
                    nextReviewDate: Date(timeIntervalSince1970: 86_400 * 2)
                )
            ]
        )
        let viewModel = await makeViewModel(userId: userId, wordRepository: repository)

        await viewModel.loadQueue(today: Date(timeIntervalSince1970: 0))
        await viewModel.tapCard(today: Date(timeIntervalSince1970: 0))

        XCTAssertFalse(viewModel.isTransitioningToNextCard)
        XCTAssertNil(viewModel.currentWord)
        XCTAssertEqual(viewModel.progressText, "今日无待复习")
        XCTAssertEqual(viewModel.notice, "已完成今日复习队列")
    }

    private func makeViewModel(userId: UUID, wordRepository: WordRepository) async -> ReviewViewModel {
        let context = AppContext(
            authRepository: InMemoryAuthRepository(),
            wordRepository: wordRepository,
            deepSeekClient: NoopDeepSeekClient(),
            keychainStore: KeychainStore(service: UUID().uuidString),
            reviewScheduler: ReviewScheduler()
        )
        _ = await context.signIn(email: "tester@example.com", password: "secret")
        return ReviewViewModel(context: context)
    }
}

private actor NoopDeepSeekClient: DeepSeekClientProtocol {
    func generateCandidates(for zhText: String, apiKey: String) async throws -> [String] {
        []
    }
}

private struct MockError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

private actor ReviewQueueWordRepository: WordRepository {
    private let dueWords: [WordItem]
    private var remainingAppliedWords: [WordItem]
    private(set) var appliedResults: [ReviewResult] = []

    init(dueWords: [WordItem], appliedWords: [WordItem]) {
        self.dueWords = dueWords
        self.remainingAppliedWords = appliedWords
    }

    func fetchDueWords(userId: UUID, today: Date) async throws -> [WordItem] {
        dueWords
    }

    func fetchAllWords(userId: UUID) async throws -> [WordItem] {
        dueWords
    }

    func upsertWord(userId: UUID, zhText: String, enWord: String, today: Date) async throws -> UpsertWordResult {
        throw MockError(message: "unused")
    }

    func deleteWord(userId: UUID, wordId: UUID) async throws {}

    func applyReview(
        userId: UUID,
        wordId: UUID,
        result: ReviewResult,
        today: Date,
        scheduler: ReviewScheduler
    ) async throws -> WordItem {
        appliedResults.append(result)
        guard !remainingAppliedWords.isEmpty else {
            throw MockError(message: "missing applied word")
        }
        return remainingAppliedWords.removeFirst()
    }
}
