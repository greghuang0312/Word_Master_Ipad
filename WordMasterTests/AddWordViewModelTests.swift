import XCTest
@testable import WordMaster

@MainActor
final class AddWordViewModelTests: XCTestCase {
    func testSettingChineseMeaningAutomaticallyQueriesCandidates() async {
        let client = RecordingDeepSeekClient(result: .success(["apple", "fruit"]))
        let viewModel = makeViewModel(client: client, autoQueryDelayNanoseconds: 20_000_000)

        viewModel.zhText = "苹果"
        try? await Task.sleep(nanoseconds: 120_000_000)

        XCTAssertEqual(await client.requestedPrompts, ["苹果"])
        XCTAssertEqual(viewModel.candidates, ["apple", "fruit"])
        XCTAssertEqual(viewModel.selectedCandidate, "apple")
    }

    func testClearingChineseMeaningCancelsAutoQueryAndClearsCandidates() async {
        let client = RecordingDeepSeekClient(result: .success(["apple"]))
        let viewModel = makeViewModel(client: client, autoQueryDelayNanoseconds: 80_000_000)
        viewModel.candidates = ["apple"]
        viewModel.selectedCandidate = "apple"
        viewModel.loading = true

        viewModel.zhText = "苹果"
        viewModel.zhText = ""
        try? await Task.sleep(nanoseconds: 160_000_000)

        XCTAssertEqual(await client.requestedPrompts, [])
        XCTAssertEqual(viewModel.candidates, [])
        XCTAssertNil(viewModel.selectedCandidate)
        XCTAssertFalse(viewModel.loading)
    }

    func testSaveShowsProgressBeforeSuccess() async {
        let repository = DelayedWordRepository(result: .success(makeUpsertResult()), delayNanoseconds: 80_000_000)
        let viewModel = await makeAuthenticatedViewModel(wordRepository: repository)
        viewModel.zhText = "苹果"
        viewModel.selectedCandidate = "apple"

        let saveTask = Task { await viewModel.save(today: Date(timeIntervalSince1970: 0)) }
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(viewModel.resultBanner, AddWordResultBanner(message: "正在保存", tone: .progress))

        await saveTask.value

        XCTAssertEqual(viewModel.resultBanner, AddWordResultBanner(message: "已经添加完成", tone: .success))
        XCTAssertEqual(viewModel.zhText, "")
        XCTAssertFalse(viewModel.saving)
    }

    func testSaveFailureShowsErrorBanner() async {
        let repository = DelayedWordRepository(
            result: .failure(MockError(message: "数据库写入失败")),
            delayNanoseconds: 0
        )
        let viewModel = await makeAuthenticatedViewModel(wordRepository: repository)
        viewModel.zhText = "苹果"
        viewModel.selectedCandidate = "apple"

        await viewModel.save(today: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(
            viewModel.resultBanner,
            AddWordResultBanner(message: "保存失败：数据库写入失败", tone: .error)
        )
        XCTAssertEqual(viewModel.notice, "保存失败：数据库写入失败")
        XCTAssertFalse(viewModel.saving)
    }

    func testSaveWithoutSessionSignsOutImmediately() async {
        let authRepository = TrackingAuthRepository()
        let context = AppContext(
            authRepository: authRepository,
            wordRepository: InMemoryWordRepository(),
            deepSeekClient: RecordingDeepSeekClient(result: .success([])),
            keychainStore: KeychainStore(service: UUID().uuidString),
            reviewScheduler: ReviewScheduler()
        )
        let viewModel = AddWordViewModel(context: context, autoQueryDelayNanoseconds: 20_000_000)
        viewModel.zhText = "苹果"
        viewModel.selectedCandidate = "apple"

        await viewModel.save(today: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(await authRepository.signOutCount, 1)
        XCTAssertNil(viewModel.resultBanner)
    }

    private func makeViewModel(
        client: DeepSeekClientProtocol,
        autoQueryDelayNanoseconds: UInt64
    ) -> AddWordViewModel {
        let keychainStore = KeychainStore(service: UUID().uuidString)
        try? keychainStore.saveString("sk-test", for: DeepSeekSettings.apiKeyName)

        let context = AppContext(
            authRepository: InMemoryAuthRepository(),
            wordRepository: InMemoryWordRepository(),
            deepSeekClient: client,
            keychainStore: keychainStore,
            reviewScheduler: ReviewScheduler()
        )
        return AddWordViewModel(
            context: context,
            autoQueryDelayNanoseconds: autoQueryDelayNanoseconds
        )
    }

    private func makeAuthenticatedViewModel(wordRepository: WordRepository) async -> AddWordViewModel {
        let keychainStore = KeychainStore(service: UUID().uuidString)
        try? keychainStore.saveString("sk-test", for: DeepSeekSettings.apiKeyName)

        let context = AppContext(
            authRepository: InMemoryAuthRepository(),
            wordRepository: wordRepository,
            deepSeekClient: RecordingDeepSeekClient(result: .success([])),
            keychainStore: keychainStore,
            reviewScheduler: ReviewScheduler()
        )
        _ = await context.signIn(email: "tester@example.com", password: "secret")

        return AddWordViewModel(
            context: context,
            autoQueryDelayNanoseconds: 20_000_000
        )
    }

    private func makeUpsertResult() -> UpsertWordResult {
        let userId = UUID()
        return UpsertWordResult(
            word: WordItem(
                userId: userId,
                zhText: "苹果",
                enWord: "apple",
                nextReviewDate: Date(timeIntervalSince1970: 86_400)
            ),
            merged: false
        )
    }
}

private struct MockError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

private actor RecordingDeepSeekClient: DeepSeekClientProtocol {
    private(set) var requestedPrompts: [String] = []
    private let result: Result<[String], Error>

    init(result: Result<[String], Error>) {
        self.result = result
    }

    func generateCandidates(for zhText: String, apiKey: String) async throws -> [String] {
        requestedPrompts.append(zhText)
        switch result {
        case let .success(candidates):
            return candidates
        case let .failure(error):
            throw error
        }
    }
}

private actor DelayedWordRepository: WordRepository {
    private let result: Result<UpsertWordResult, Error>
    private let delayNanoseconds: UInt64

    init(result: Result<UpsertWordResult, Error>, delayNanoseconds: UInt64) {
        self.result = result
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchDueWords(userId: UUID, today: Date) async throws -> [WordItem] { [] }
    func fetchAllWords(userId: UUID) async throws -> [WordItem] { [] }
    func deleteWord(userId: UUID, wordId: UUID) async throws {}
    func applyReview(
        userId: UUID,
        wordId: UUID,
        result: ReviewResult,
        today: Date,
        scheduler: ReviewScheduler
    ) async throws -> WordItem {
        throw MockError(message: "unused")
    }

    func upsertWord(userId: UUID, zhText: String, enWord: String, today: Date) async throws -> UpsertWordResult {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        switch result {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}

private actor TrackingAuthRepository: AuthRepository {
    private(set) var signOutCount = 0

    func signIn(email: String, password: String) async throws -> UserSession {
        UserSession(id: UUID(), email: email)
    }

    func signOut() async throws {
        signOutCount += 1
    }

    func currentSession() async -> UserSession? {
        nil
    }
}
