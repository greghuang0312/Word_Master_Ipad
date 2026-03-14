import XCTest
@testable import WordMaster

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func testTestAndSaveApiKeySuccessPersistsAndClearsVisibleInput() async {
        let keychainStore = KeychainStore(service: "profile-view-model-tests-success")
        let client = MockDeepSeekClient(result: .success(["apple"]))
        let viewModel = makeViewModel(client: client, keychainStore: keychainStore)
        viewModel.apiKey = "sk-success"

        await viewModel.testAndSaveApiKey()

        XCTAssertEqual(keychainStore.loadString(for: DeepSeekSettings.apiKeyName), "sk-success")
        XCTAssertTrue(viewModel.hasSavedApiKey)
        XCTAssertEqual(viewModel.apiKey, "")
        XCTAssertEqual(viewModel.notice, "测试成功，已保存 API")
    }

    func testTestAndSaveApiKeyFailureShowsUnderlyingErrorAndDoesNotPersist() async {
        let keychainStore = KeychainStore(service: "profile-view-model-tests-failure")
        let client = MockDeepSeekClient(result: .failure(MockError(message: "连接 DeepSeek 失败：网络超时")))
        let viewModel = makeViewModel(client: client, keychainStore: keychainStore)
        viewModel.apiKey = "sk-valid-but-timeout"

        await viewModel.testAndSaveApiKey()

        XCTAssertNil(keychainStore.loadString(for: DeepSeekSettings.apiKeyName))
        XCTAssertFalse(viewModel.hasSavedApiKey)
        XCTAssertEqual(viewModel.apiKey, "sk-valid-but-timeout")
        XCTAssertEqual(viewModel.notice, "连接 DeepSeek 失败：网络超时")
        XCTAssertEqual(viewModel.resultBanner?.tone, .error)
    }

    private func makeViewModel(client: DeepSeekClientProtocol, keychainStore: KeychainStore) -> ProfileViewModel {
        let context = AppContext(
            authRepository: InMemoryAuthRepository(),
            wordRepository: InMemoryWordRepository(),
            deepSeekClient: client,
            keychainStore: keychainStore,
            reviewScheduler: ReviewScheduler()
        )
        return ProfileViewModel(context: context)
    }
}

private struct MockError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

private final class MockDeepSeekClient: DeepSeekClientProtocol {
    private let result: Result<[String], Error>

    init(result: Result<[String], Error>) {
        self.result = result
    }

    func generateCandidates(for zhText: String, apiKey: String) async throws -> [String] {
        switch result {
        case let .success(candidates):
            return candidates
        case let .failure(error):
            throw error
        }
    }
}
