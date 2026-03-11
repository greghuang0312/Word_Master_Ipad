import XCTest
@testable import WordMaster

final class AppRouterTests: XCTestCase {
    func testUnauthenticatedUserShowsLogin() {
        let router = AppRouter(isAuthenticated: false)
        XCTAssertEqual(router.currentRoute, .login)
    }

    func testAuthenticatedUserShowsMainTabs() {
        let router = AppRouter(isAuthenticated: true)
        XCTAssertEqual(router.currentRoute, .mainTabs)
    }
}

