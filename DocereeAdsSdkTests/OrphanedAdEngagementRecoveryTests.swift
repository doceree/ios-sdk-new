import XCTest
@testable import DocereeAdsSdk

final class OrphanedAdEngagementRecoveryTests: XCTestCase {
    private let baseURL =
        "https://example.com/nEvent?eType=2&viewedPercentage={{VIEWED_PERCENTAGE}}&viewedTime={{VIEWED_TIME}}&eventClientTime={{EVENT_CLIENT_TIME}}"

    override func setUp() {
        super.setUp()
        ActiveAdRecoveryStore.clear()
        DocereeBeaconQueue.clearQueue()
    }

    func testMakeRecoveryEngagementURLUsesEType5() {
        let snapshot = ActiveAdRecoveryStore.Snapshot(
            adViewedURL: baseURL,
            totalViewTime: 4,
            savedViewPercentage: 80,
            oneSecMrcSent: true,
            updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        let url = OrphanedAdEngagementRecovery.makeRecoveryEngagementURL(from: snapshot)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.contains("eType=5"))
        XCTAssertTrue(url!.contains("viewedTime=4"))
    }

    func testRecoveryClearsSnapshot() {
        ActiveAdRecoveryStore.mark(
            adViewedURL: baseURL,
            totalViewTime: 4,
            savedViewPercentage: 80,
            oneSecMrcSent: true
        )

        OrphanedAdEngagementRecovery.recover()

        XCTAssertNil(ActiveAdRecoveryStore.load())
    }

    func testDropsExpiredSnapshotWithoutEnqueue() {
        let stale = Int64(Date().timeIntervalSince1970 * 1000) - ActiveAdRecoveryStore.maxAgeMs - 1000
        ActiveAdRecoveryStore.mark(
            adViewedURL: baseURL,
            totalViewTime: 2,
            savedViewPercentage: 60,
            oneSecMrcSent: true,
            updatedAt: stale
        )

        OrphanedAdEngagementRecovery.recover()

        XCTAssertNil(ActiveAdRecoveryStore.load())
        XCTAssertTrue(DocereeBeaconQueue.loadQueue().isEmpty)
    }

    func testNoOpWhenNoSnapshot() {
        OrphanedAdEngagementRecovery.recover()
        XCTAssertTrue(DocereeBeaconQueue.loadQueue().isEmpty)
    }
}
