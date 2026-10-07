import XCTest
@testable import DocereeAdsSdk

final class DocereeAdQuestRetryTests: XCTestCase {
    func testQuestRetryDelayMatchesRNBackoff() {
        XCTAssertEqual(DocereeAdQuestRetry.delayMs(forAttempt: 1), 5_000)
        XCTAssertEqual(DocereeAdQuestRetry.delayMs(forAttempt: 2), 10_000)
        XCTAssertEqual(DocereeAdQuestRetry.delayMs(forAttempt: 3), 20_000)
        XCTAssertEqual(DocereeAdQuestRetry.delayMs(forAttempt: 4), 40_000)
        XCTAssertEqual(DocereeAdQuestRetry.delayMs(forAttempt: 5), 60_000)
        XCTAssertEqual(DocereeAdQuestRetry.delayMs(forAttempt: 6), 60_000)
    }

    func testMaxOnlineAttempts() {
        XCTAssertEqual(DocereeAdQuestRetry.maxOnlineAttempts, 5)
    }
}
