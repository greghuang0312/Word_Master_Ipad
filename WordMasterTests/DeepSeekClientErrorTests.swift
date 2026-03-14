import XCTest
@testable import WordMaster

final class DeepSeekClientErrorTests: XCTestCase {
    func testRequestFailed401UsesFriendlyChineseMessage() {
        let error = DeepSeekClientError.requestFailed(
            statusCode: 401,
            message: "Authentication Fails, your api key is invalid"
        )

        XCTAssertEqual(
            error.errorDescription,
            "DeepSeek API Key 无效或已失效（Authentication Fails, your api key is invalid）"
        )
    }

    func testRequestFailed402UsesFriendlyChineseMessage() {
        let error = DeepSeekClientError.requestFailed(
            statusCode: 402,
            message: "Insufficient Balance"
        )

        XCTAssertEqual(
            error.errorDescription,
            "DeepSeek 账户余额不足（Insufficient Balance）"
        )
    }

    func testRequestFailed429UsesFriendlyChineseMessage() {
        let error = DeepSeekClientError.requestFailed(
            statusCode: 429,
            message: "Rate limit reached"
        )

        XCTAssertEqual(
            error.errorDescription,
            "DeepSeek 请求过于频繁，请稍后再试（Rate limit reached）"
        )
    }
}
