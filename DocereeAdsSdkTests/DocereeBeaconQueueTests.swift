import XCTest
@testable import DocereeAdsSdk

final class DocereeBeaconQueueTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DocereeBeaconQueue.clearQueue()
    }

    func testCoalescesViewabilityURLsWithDynamicQueryParams() {
        DocereeBeaconQueue.enqueueBeacon(
            kind: .viewability,
            url: "https://example.com/view?VIEWED_TIME=1&EVENT_CLIENT_TIME=1000"
        )
        DocereeBeaconQueue.enqueueBeacon(
            kind: .viewability,
            url: "https://example.com/view?VIEWED_TIME=5&EVENT_CLIENT_TIME=2000"
        )

        let queued = DocereeBeaconQueue.loadQueue()
        XCTAssertEqual(queued.count, 1)
        XCTAssertTrue(queued[0].url.contains("VIEWED_TIME=5"))
    }

    func testNormalizeMeasurementURLStripsDynamicValues() {
        let normalized = DocereeBeaconQueue.normalizeMeasurementURL(
            "https://example.com/imp?VIEWED_TIME=9&EVENT_CLIENT_TIME=1234567890"
        )
        XCTAssertTrue(normalized.contains("VIEWED_TIME=*"))
        XCTAssertTrue(normalized.contains("EVENT_CLIENT_TIME=*"))
    }

    func testClearQueueRemovesPersistedItems() {
        DocereeBeaconQueue.enqueueBeacon(kind: .impression, url: "https://example.com/imp")
        DocereeBeaconQueue.clearQueue()
        XCTAssertTrue(DocereeBeaconQueue.loadQueue().isEmpty)
    }

    func testBackoffDelayIncreasesWithAttempts() {
        XCTAssertEqual(DocereeBeaconQueue.backoffDelayMs(attempts: 1), 2000)
        XCTAssertEqual(DocereeBeaconQueue.backoffDelayMs(attempts: 2), 4000)
    }
}
